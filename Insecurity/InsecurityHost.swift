import UIKit

struct Weak<Value> where Value: AnyObject {
    weak var value: Value?
    
    init(_ value: Value) {
        self.value = value
    }
}

struct InsecurityHostState {
    enum Stage {
        case ready
        case batching
        case purging
    }
    
    var stage: Stage
    var notDead: Bool
}

private enum FinalizationKind {
    case callback
    case kvo
    case deinitialization
    
    func toFrameState() -> InsecurityHost.Frame.State {
        switch self {
        case .callback:
            return .finishedByCompletion
        case .kvo:
            return .finishedByKVO
        case .deinitialization:
            return .finishedByDeinit
        }
    }
}

public class InsecurityHost {
    enum Frame {
        enum State {
            case live
            case finishedByCompletion
            case finishedByKVO
            case finishedByDeinit
        }
        
        struct Regular {
            let state: State
            let coordinator: CommonModalCoordinatorAny
            weak var viewController: UIViewController?
        }
        
        case regular(Regular)
        
        struct Navigation {
            struct Child {
                let state: State
                let coordinator: CommonNavigationCoordinatorAny
                weak var viewController: UIViewController?
            }
            
            let children: [Child]
            weak var navigationController: UINavigationController?
        }
        
        case navigation(Navigation)
    }
    
    var frames: [Frame] = []
    
    enum Root {
        case modal(Weak<UIViewController>)
        case navigation(Weak<UINavigationController>)
    }
    
    let root: Root
    
    var state = InsecurityHostState(stage: .ready, notDead: true)
    
    public init(modal viewController: UIViewController) {
        self.root = .modal(Weak<UIViewController>(viewController))
    }
    
    public init(navigation viewController: UINavigationController) {
        self.root = .navigation(Weak<UINavigationController>(viewController))
    }
    
    var scheduledStartRoutine: (() -> Void)?
    
    // MARK: - Modal
    
    func start<Coordinator: CommonModalCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        switch state.stage {
        case .ready:
            immediateDispatchModal(child, animated: animated) { result in
                completion(result)
            }
        case .batching:
            if scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self.scheduledStartRoutine = nil
                self.immediateDispatchModal(child, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    private func immediateDispatchModal<Coordinator: CommonModalCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        assert(state.stage == .ready)
        
        child._updateHostReference(self)
        
        weak var weakChild = child
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController?
        
        child._finishImplementation = { [weak self] result in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil
            
            guard let self = self else {
                assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = weakChild else { return }
            
            self.finalizeModal(child, .callback) {
                completion(result)
            }
        }
        
        let controller = child.viewController
        weakController = controller
        
        kvoContext = controller.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { [weak self, weak child] oldController, newController in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil
            
            if oldController != nil, newController == nil {
                guard let self = self else {
                    assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                    return
                }
                guard let child = child else { return }
            
                self.finalizeModal(child, .kvo) {
                    completion(nil)
                }
            }
        }
        
        controller.deinitObservable.onDeinit = { [weak self, weak child] in
            weakChild?._finishImplementation = nil
            
            guard let self = self, let child = child else { return }
            
            self.finalizeModal(child, .deinitialization) {
                completion(nil)
            }
        }
        
        sendOffModal(controller, animated, child)
    }
    
    private func finalizeModal(
        _ child: CommonModalCoordinatorAny,
        _ kind: FinalizationKind,
        _ callback: () -> Void
    ) {
        let indexOfChildOpt = frames.firstIndex(where: { frame in
            switch frame {
            case .regular(let regular):
                return regular.coordinator === child
            case .navigation:
                return false
            }
        })
        
        if let indexOfChild = indexOfChildOpt {
            switch frames[indexOfChild] {
            case .regular(let regular):
                frames[indexOfChild] = .regular(
                    Frame.Regular(
                        state: kind.toFrameState(),
                        coordinator: regular.coordinator,
                        viewController: regular.viewController
                    )
                )
            case .navigation:
                fatalError()
            }
        }
        
        self.state.stage = .batching
        if self.state.notDead {
            callback()
        }
        self.state.stage = .purging
        self.purge()
        self.state.stage = .ready
    }
    
    private func sendOffModal(_ controller: UIViewController, _ animated: Bool, _ child: CommonModalCoordinatorAny) {
        let electedHostControllerOpt: UIViewController?
        if let topFrame = frames.last {
            if let hostController = topFrame.viewController {
                let hostDoesntPresentAnything = hostController.presentedViewController == nil
                if hostDoesntPresentAnything {
                    electedHostControllerOpt = hostController
                } else {
                    assertionFailure("Top controller in the modal stack is already busy presenting something else")
                    electedHostControllerOpt = nil
                }
            } else {
                assertionFailure("Top controller of modal stack is somehow dead")
                electedHostControllerOpt = nil
            }
        } else {
            electedHostControllerOpt = root.viewController
        }
        
        guard let electedHostController = electedHostControllerOpt else {
            assertionFailure("No parent was found to start a child")
            return
        }
        
        let frame = Frame.regular(Frame.Regular(state: .live, coordinator: child, viewController: controller))
        self.frames.append(frame)
        
        electedHostController.present(controller, animated: animated, completion: nil)
    }
    
    // MARK: - Navigation Current
    
    func start<Coordinator: CommonNavigationCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        switch state.stage {
        case .ready:
            immediateDispatchNavigation(child, animated: animated) { result in
                completion(result)
            }
        case .batching:
            if scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self.scheduledStartRoutine = nil
                self.immediateDispatchNavigation(child, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    func immediateDispatchNavigation<Coordinator: CommonNavigationCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        assert(state.stage == .ready)
        
        child._updateHostReference(self)
        
        weak var weakChild = child
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController?
        
        child._finishImplementation = { [weak self] result in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil
            
            guard let self = self else {
                assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = weakChild else { return }
            
            self.finalizeNavigation(child, .callback) {
                completion(result)
            }
        }
        
        let controller = child.viewController
        weakController = controller
        
        kvoContext = controller.insecurityKvo.addHandler(
            UIViewController.self,
            parentObservationKeypath
        ) { [weak self, weak child] oldController, newController in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil
            
            if oldController != nil, oldController is UINavigationController, newController == nil {
                guard let self = self else {
                    assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                    return
                }
                guard let child = child else { return }
            
                self.finalizeNavigation(child, .kvo) {
                    completion(nil)
                }
            }
        }
        
        controller.deinitObservable.onDeinit = { [weak self, weak child] in
            weakChild?._finishImplementation = nil
            
            guard let self = self, let child = child else { return }
            
            self.finalizeNavigation(child, .deinitialization) {
                completion(nil)
            }
        }
        
        sendOffNavigation(controller, animated, child)
    }
    
    private func finalizeNavigation(
        _ child: CommonNavigationCoordinatorAny,
        _ kind: FinalizationKind,
        _ callback: () -> Void
    ) {
        // Very questionable code ahead
        var indexInsideNavigation: Int!
        let indexOfFrameOpt = frames.firstIndex(where: { frame -> Bool in
            switch frame {
            case .regular:
                return false
            case .navigation(let navigation):
                let indexInsideNavigationOpt = navigation.children.firstIndex(where: { navigationChild in
                    if navigationChild.coordinator === child {
                        return true
                    }
                    return false
                })
                
                if let indexInsideNavigationUnwrapped = indexInsideNavigationOpt {
                    indexInsideNavigation = indexInsideNavigationUnwrapped
                    return true
                } else {
                    return false
                }
            }
        })
        
        if let indexOfFrame = indexOfFrameOpt {
            switch frames[indexOfFrame] {
            case .navigation(let navigationFrame):
                let childInNavigation = navigationFrame.children[indexInsideNavigation]
                
                frames[indexOfFrame] = .navigation(
                    Frame.Navigation(
                        children: navigationFrame.children
                            .replacing(
                                indexInsideNavigation,
                                with: Frame.Navigation.Child(
                                    state: kind.toFrameState(),
                                    coordinator: childInNavigation.coordinator,
                                    viewController: childInNavigation.viewController
                                )
                            ),
                        navigationController: navigationFrame.navigationController
                    )
                )
            case .regular:
                fatalError()
            }
        }
        
        self.state.stage = .batching
        if self.state.notDead {
            callback()
        }
        self.state.stage = .purging
        self.purge()
        self.state.stage = .ready
    }
    
    func sendOffNavigation(
        _ controller: UIViewController,
        _ animated: Bool,
        _ child: CommonNavigationCoordinatorAny
    ) {
        let frameChild = Frame.Navigation.Child(
            state: .live,
            coordinator: child,
            viewController: controller
        )
        
        if let lastFrame = frames.last {
            switch lastFrame {
            case .navigation(let navigationLastFrame):
                guard let navigationController = navigationLastFrame.navigationController else {
                    assertionFailure("NavigationHost wanted to start NavigationChild, but the UINavigationController was found dead")
                    return
                }
                
                self.frames = self.frames.replacing(
                    self.frames.count - 1,
                    with: .navigation(
                        .init(
                            children: navigationLastFrame.children.appending(frameChild),
                            navigationController: navigationController
                        )
                    )
                )
                
                navigationController.pushViewController(controller, animated: animated)
            case .regular:
                assertionFailure("Can not start navigation child when the top context is not UINavigationController")
                return
            }
        } else {
            switch root {
            case .modal:
                assertionFailure("Can not start navigation child when the top context is not UINavigationController")
                return
            case .navigation(let weak):
                guard let navigationController = weak.value else {
                    assertionFailure("NavigationHost wanted to start NavigationChild, but the UINavigationController was found dead")
                    return
                }
                
                self.frames = [
                    .navigation(
                        Frame.Navigation(
                            children: [ frameChild ],
                            navigationController: navigationController
                        )
                    )
                ]
            }
        }
    }
    
    // MARK: - Navigation New
    
    func start<Coordinator: CommonNavigationCoordinator>(
        _ navigationController: UINavigationController,
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        switch state.stage {
        case .ready:
            immediateDispatchNewNavigation(navigationController, child, animated: animated) { result in
                completion(result)
            }
        case .batching:
            if scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self.scheduledStartRoutine = nil
                self.immediateDispatchNewNavigation(navigationController, child, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    func immediateDispatchNewNavigation<Coordinator: CommonNavigationCoordinator>(
        _ navigationController: UINavigationController,
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        assert(state.stage == .ready)
        
        child._updateHostReference(self)
        
        weak var weakChild = child
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController?

        child._finishImplementation = { [weak self] result in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil

            guard let self = self else {
                assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                return
            }
            guard let child = weakChild else { return }

            self.finalizeNavigation(child, .callback) {
                completion(result)
            }
        }

        let controller = child.viewController
        weakController = controller

        kvoContext = navigationController.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { [weak self, weak child] oldController, newController in
            if let kvoContext = kvoContext {
                weakController?.insecurityKvo.removeObserver(kvoContext)
            }
            weakController?.deinitObservable.onDeinit = nil
            weakChild?._finishImplementation = nil

            if oldController != nil, newController == nil {
                guard let self = self else {
                    assertionFailure("InsecurityHost wasn't properly retained. Make sure you save it somewhere before starting any children.")
                    return
                }
                guard let child = child else { return }

                self.finalizeNavigation(child, .kvo) {
                    completion(nil)
                }
            }
        }

        controller.deinitObservable.onDeinit = { [weak self, weak child] in
            weakChild?._finishImplementation = nil

            guard let self = self, let child = child else { return }

            self.finalizeNavigation(child, .deinitialization) {
                completion(nil)
            }
        }

        sendOffNewNavigation(navigationController, controller, animated, child)
    }
    
    private func sendOffNewNavigation(
        _ navigationController: UINavigationController,
        _ controller: UIViewController,
        _ animated: Bool,
        _ child: CommonNavigationCoordinatorAny
    ) {
        let electedHostControllerOpt: UIViewController?
        if let topFrame = frames.last {
            if let hostController = topFrame.viewController {
                let hostDoesntPresentAnything = hostController.presentedViewController == nil
                if hostDoesntPresentAnything {
                    electedHostControllerOpt = hostController
                } else {
                    assertionFailure("Top controller in the modal stack is already busy presenting something else")
                    electedHostControllerOpt = nil
                }
            } else {
                assertionFailure("Top controller of modal stack is somehow dead")
                electedHostControllerOpt = nil
            }
        } else {
            electedHostControllerOpt = root.viewController
        }
        
        guard let electedHostController = electedHostControllerOpt else {
            assertionFailure("No parent was found to start a child")
            return
        }
        
        let navigatioFrameChild = Frame.Navigation.Child(state: .live,
                                                         coordinator: child,
                                                         viewController: controller)
        let frame = Frame.navigation(Frame.Navigation(children: [navigatioFrameChild],
                                                      navigationController: navigationController))
        self.frames.append(frame)
        
        navigationController.setViewControllers([ controller ], animated: false)
        electedHostController.present(navigationController, animated: animated, completion: nil)
    }
    
    // MARK: - Purge
    
    private func purge() {
        
    }
}

extension InsecurityHost: ModalNavigation {
    public func start<NewResult>(
        _ child: ModalCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
    
    public func start<NewResult>(
        _ navigationController: UINavigationController,
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
}

extension InsecurityHost: NavigationControllerNavigation {
    public func start<NewResult>(
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
}

extension InsecurityHost: AdaptiveNavigation {
    public func start<NewResult>(
        _ child: AdaptiveCoordinator<NewResult>,
        in context: AdaptiveContext,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        
    }
}

private extension InsecurityHost.Root {
    var viewController: UIViewController? {
        switch self {
        case .navigation(let weak):
            return weak.value
        case .modal(let weak):
            return weak.value
        }
    }
}

private extension InsecurityHost.Frame {
    var viewController: UIViewController? {
        switch self {
        case .regular(let regular):
            return regular.viewController
        case .navigation(let navigation):
            return navigation.navigationController
        }
    }
}

private extension Array {
    func replacing(_ index: Index, with element: Element) -> Array {
        var array = self
        array[index] = element
        return array
    }
}

private extension Array {
    func appending(_ element: Element) -> Array {
        var array = self
        array.append(element)
        return array
    }
}
