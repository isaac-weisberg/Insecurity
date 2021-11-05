import UIKit

private struct Weak<Value> where Value: AnyObject {
    weak var value: Value?
    
    init(_ value: Value) {
        self.value = value
    }
}

private struct InsecurityHostState {
    enum Stage {
        case ready
        case batching
        case purging
        
        var allowsPresentation: Bool {
            switch self {
            case .batching:
                return false
            case .ready, .purging:
                return true
            }
        }
    }
    
    var stage: Stage
    var notDead: Bool
}

private enum FinalizationKind {
    case callback
    case kvo
    case deinitialization
    
    func toFrameState() -> FrameState {
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

private struct FrameNavigationChild {
    var state: FrameState
    let coordinator: CommonNavigationCoordinatorAny
    weak var viewController: UIViewController?
    weak var previousViewController: UIViewController?
    
    init(
        state: FrameState,
        coordinator: CommonNavigationCoordinatorAny,
        viewController: UIViewController?,
        previousViewController: UIViewController?
    ) {
        self.state = state
        self.coordinator = coordinator
        self.viewController = viewController
        self.previousViewController = previousViewController
    }
}

private struct FrameNavigationData {
    var children: [FrameNavigationChild]
    weak var navigationController: UINavigationController?
    
    init(
        children: [FrameNavigationChild],
        navigationController: UINavigationController?
    ) {
        self.children = children
        self.navigationController = navigationController
    }
}

private enum FrameState {
    case live
    case finishedByCompletion
    case finishedByKVO
    case finishedByDeinit
}

private class RootNavigationCrutchCoordinator: CommonCoordinatorAny {
    
}

private struct Frame {
    var state: FrameState
    let coordinator: CommonCoordinatorAny
    weak var viewController: UIViewController?
    weak var previousViewController: UIViewController?
    var navigationData: FrameNavigationData?
    
    init(
        state: FrameState,
        coordinator: CommonCoordinatorAny,
        viewController: UIViewController?,
        previousViewController: UIViewController?,
        navigationData: FrameNavigationData?
    ) {
        self.state = state
        self.coordinator = coordinator
        self.viewController = viewController
        self.previousViewController = previousViewController
        self.navigationData = navigationData
    }
}

public class InsecurityHost {
    fileprivate var frames: [Frame] = []
    
    fileprivate enum Root {
        case modal(Weak<UIViewController>)
        case navigation(Weak<UINavigationController>)
    }
    
    fileprivate let root: Root
    
    fileprivate var state = InsecurityHostState(stage: .ready, notDead: true)
    
    func kill() {
        state.notDead = false
    }
    
    public init(modal viewController: UIViewController) {
        self.root = .modal(Weak<UIViewController>(viewController))
    }
    
    public init(navigation viewController: UINavigationController) {
        self.root = .navigation(Weak<UINavigationController>(viewController))
    }
    
    fileprivate var _scheduledStartRoutine: (() -> Void)?
    
    fileprivate func executeScheduledStartRoutine() {
        _scheduledStartRoutine?()
        _scheduledStartRoutine = nil
    }
    
    fileprivate func executeScheduledStartRoutineWithDelay() {
        insecDelay(Insecurity.navigationPopBatchedStartDelay) { [weak self] in
            self?.executeScheduledStartRoutine()
        }
    }
    
    // MARK: - Modal
    
    func startModal<Coordinator: CommonModalCoordinator>(
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
            if _scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            _scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self._scheduledStartRoutine = nil
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
        
        assert(state.stage.allowsPresentation)
        
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
            if oldController != nil, newController == nil {
                if let kvoContext = kvoContext {
                    weakController?.insecurityKvo.removeObserver(kvoContext)
                }
                weakController?.deinitObservable.onDeinit = nil
                weakChild?._finishImplementation = nil
                
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
            return frame.coordinator === child
        })
        
        if let indexOfChild = indexOfChildOpt {
            frames[indexOfChild].state = kind.toFrameState()
        }
        
        switch state.stage {
        case .batching:
            if self.state.notDead {
                callback()
            }
        case .purging:
            fatalError()
        case .ready:
            self.state.stage = .batching
            if self.state.notDead {
                callback()
            }
            self.state.stage = .purging
            self.purge()
            self.state.stage = .ready
        }
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
        
        let frame = Frame(
            state: .live,
            coordinator: child,
            viewController: controller,
            previousViewController: electedHostController,
            navigationData: nil
        )
        self.frames.append(frame)
        
        electedHostController.present(controller, animated: animated, completion: nil)
    }
    
    // MARK: - Navigation Current
    
    func startNavigation<Coordinator: CommonNavigationCoordinator>(
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
            if _scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            _scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self._scheduledStartRoutine = nil
                self.immediateDispatchNavigation(child, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    private func immediateDispatchNavigation<Coordinator: CommonNavigationCoordinator>(
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        assert(state.stage.allowsPresentation)
        
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
            if oldController != nil, oldController is UINavigationController, newController == nil {
                if let kvoContext = kvoContext {
                    weakController?.insecurityKvo.removeObserver(kvoContext)
                }
                weakController?.deinitObservable.onDeinit = nil
                weakChild?._finishImplementation = nil
                
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
        var indexInsideNavigationOpt: Int?
        let indexOfFrameOpt = frames.firstIndex(where: { frame -> Bool in
            if frame.coordinator === child {
                return true
            } else if let navigationData = frame.navigationData {
                let firstIndexInsideNavigationOpt = navigationData.children.firstIndex(where: { navigationChild in
                    return navigationChild.coordinator === child
                })
                
                if let firstIndexInsideNavigation = firstIndexInsideNavigationOpt {
                    indexInsideNavigationOpt = firstIndexInsideNavigation
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        })
        
        if let indexOfFrame = indexOfFrameOpt {
            assert(frames.at(indexOfFrame) != nil)
            
            if let indexInsideNavigation = indexInsideNavigationOpt {
                assert(frames[indexOfFrame].navigationData != nil)
                frames[indexOfFrame].navigationData?.children[indexInsideNavigation].state = kind.toFrameState()
            } else {
                frames[indexOfFrame].state = kind.toFrameState()
            }
        }
        
        switch state.stage {
        case .batching:
            if self.state.notDead {
                callback()
            }
        case .purging:
            fatalError()
        case .ready:
            self.state.stage = .batching
            if self.state.notDead {
                callback()
            }
            self.state.stage = .purging
            self.purge()
            self.state.stage = .ready
        }
    }
    
    func sendOffNavigation(
        _ controller: UIViewController,
        _ animated: Bool,
        _ child: CommonNavigationCoordinatorAny
    ) {
        if let lastFrame = frames.last {
            if let navigationData = lastFrame.navigationData {
                let previousViewController: UIViewController?
                if let lastNavigationChild = navigationData.children.last {
                    previousViewController = lastNavigationChild.viewController.assertingNotNil()
                } else {
                    previousViewController = lastFrame.viewController.assertingNotNil()
                }
                let navigationFrame = FrameNavigationChild(
                    state: .live,
                    coordinator: child,
                    viewController: controller,
                    previousViewController: previousViewController.assertingNotNil()
                )
                
                var updatedFrame = lastFrame
                assert(lastFrame.navigationData != nil)
                updatedFrame.navigationData?.children.append(navigationFrame)
                
                frames = frames.replacingLast(with: updatedFrame)
                
                navigationData.navigationController.assertNotNil()
                navigationData.navigationController?.pushViewController(controller, animated: true)
            } else {
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
                
                
                let frameChild = FrameNavigationChild(
                    state: .live,
                    coordinator: child,
                    viewController: controller,
                    previousViewController: navigationController.viewControllers[0]
                )
                
                let navigationData = FrameNavigationData(
                    children: [ frameChild ],
                    navigationController: navigationController
                )
                
                // This is ass, this is really-really bad
                let frame = Frame(
                    state: .live,
                    coordinator: RootNavigationCrutchCoordinator(),
                    viewController: navigationController,
                    previousViewController: nil,
                    navigationData: navigationData
                )
                
                self.frames = [
                    frame
                ]
                
                navigationController.pushViewController(controller, animated: true)
            }
        }
    }
    
    // MARK: - Navigation New
    
    func startNavigationNew<Coordinator: CommonNavigationCoordinator>(
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
            if _scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            _scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self._scheduledStartRoutine = nil
                self.immediateDispatchNewNavigation(navigationController, child, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    private func immediateDispatchNewNavigation<Coordinator: CommonNavigationCoordinator>(
        _ navigationController: UINavigationController,
        _ child: Coordinator,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else { return }
        
        assert(state.stage.allowsPresentation)
        
        child._updateHostReference(self)
        
        weak var weakChild = child
        weak var kvoContext: InsecurityKVOContext?
        weak var weakController: UIViewController? = navigationController
        
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
        
        kvoContext = navigationController.insecurityKvo.addHandler(
            UIViewController.self,
            modalParentObservationKeypath
        ) { [weak self, weak child] oldController, newController in
            if oldController != nil, newController == nil {
                if let kvoContext = kvoContext {
                    weakController?.insecurityKvo.removeObserver(kvoContext)
                }
                weakController?.deinitObservable.onDeinit = nil
                weakChild?._finishImplementation = nil
                
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
        
        navigationController.deinitObservable.onDeinit = { [weak self, weak child] in
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
        let frame = Frame(
            state: .live,
            coordinator: child,
            viewController: navigationController,
            previousViewController: electedHostController,
            navigationData: FrameNavigationData(
                children: [],
                navigationController: navigationController
            )
        )
        
        self.frames.append(frame)
        
        navigationController.setViewControllers([ controller ], animated: false)
        electedHostController.present(navigationController, animated: animated, completion: nil)
    }
    
    // MARK: - Purge
    
    private func purge() {
        let prepurgeFrames = self.frames
        
        var firstDeadNavigationChildIndexOpt: Int?
        let firstDeadChildIndexOpt = prepurgeFrames.firstIndex(where: { frame in
            switch frame.state {
            case .finishedByCompletion, .finishedByKVO, .finishedByDeinit:
                return true
            case .live:
                if let navigationData = frame.navigationData {
                    let firstDeadNavigationIndexOpt = navigationData.children.firstIndex(where: { child in
                        switch child.state {
                        case .finishedByDeinit, .finishedByKVO, .finishedByCompletion:
                            return true
                        case .live:
                            return false
                        }
                    })
                    
                    if let firstDeadNavigationIndex = firstDeadNavigationIndexOpt {
                        firstDeadNavigationChildIndexOpt = firstDeadNavigationIndex
                        return true
                    }
                    return false
                } else {
                    return false
                }
            }
        })
        
        let postPurgeFrames: [Frame]
        
        if let firstDeadChildIndex = firstDeadChildIndexOpt {
            let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
            
            if
                let navigationChildIndex = firstDeadNavigationChildIndexOpt,
                let navigationData = firstDeadChild.navigationData
            {
                var newFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex + 1))
                
                let newNavigationChildren = Array(navigationData.children.prefix(navigationChildIndex))
                
                if var lastFrame = newFrames.last {
                    assert(lastFrame.navigationData != nil)
                    lastFrame.navigationData?.children = newNavigationChildren
                    
                    newFrames = newFrames.replacingLast(with: lastFrame)
                } else {
                    assertionFailure()
                }
                
                postPurgeFrames = newFrames
            } else {
                postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex))
            }
        } else {
            assertionFailure("Noone died?")
            postPurgeFrames = prepurgeFrames
        }
        
        self.frames = postPurgeFrames
        
        if state.notDead, let firstDeadChildIndex = firstDeadChildIndexOpt {
            let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
            let frameAboveOpt = prepurgeFrames.at(firstDeadChildIndex + 1)
            
            if
                let firstDeadNavigationChildIndex = firstDeadNavigationChildIndexOpt,
                let navigationData = firstDeadChild.navigationData
            {
                let navigationDeadChild = navigationData.children[firstDeadNavigationChildIndex]
                
                switch navigationDeadChild.state {
                case .live:
                    assertionFailure()
                case .finishedByCompletion:
                    navigationDeadChild.previousViewController.assertNotNil()
                    navigationData.navigationController.assertNotNil()
                    if
                        let navigationController = navigationData.navigationController,
                        let popToController = navigationDeadChild.previousViewController
                    {
                        if let frameAbove = frameAboveOpt, frameAbove.state.needsDismissalInADeadChain {
                            frameAbove.previousViewController.assertNotNil()
                            
                            navigationController.popToViewController(popToController, animated: false)
                            if let presentingViewController = frameAbove.previousViewController {
                                presentingViewController.dismiss(animated: true) { [weak self] in
                                    self?.executeScheduledStartRoutine()
                                }
                            }
                        } else {
                            navigationController.popToViewController(popToController, animated: true)
                            executeScheduledStartRoutineWithDelay()
                        }
                    }
                    
                case .finishedByKVO, .finishedByDeinit:
                    assert(frameAboveOpt == nil, "Not supposed to have a controller modally on top while controller in the navigation controller has been killed by popping")
                    executeScheduledStartRoutine()
                }
            } else {
                switch firstDeadChild.state {
                case .live:
                    assertionFailure()
                case .finishedByDeinit, .finishedByKVO:
                    executeScheduledStartRoutine()
                case .finishedByCompletion:
                    assert(firstDeadChild.previousViewController != nil)
                    firstDeadChild.previousViewController?.dismiss(animated: true) { [weak self] in
                        self?.executeScheduledStartRoutine()
                    }
                }
            }
        } else {
            executeScheduledStartRoutine()
        }
    }
    
#if DEBUG
    deinit {
        insecPrint("\(type(of: self)) deinit")
    }
#endif
}

extension InsecurityHost: ModalNavigation {
    public func start<NewResult>(
        _ child: ModalCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        startModal(child, animated: animated) { result in
            completion(result)
        }
    }
    
    public func start<NewResult>(
        _ navigationController: UINavigationController,
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        startNavigationNew(navigationController, child, animated: animated) { result in
            completion(result)
        }
    }
}

extension InsecurityHost: NavigationControllerNavigation {
    public func start<NewResult>(
        _ child: NavigationCoordinator<NewResult>,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        startNavigation(child, animated: animated) { result in
            completion(result)
        }
    }
}

extension InsecurityHost: AdaptiveNavigation {
    public func start<NewResult>(
        _ child: AdaptiveCoordinator<NewResult>,
        in context: AdaptiveContext,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        guard state.notDead else { return }
        
        switch state.stage {
        case .ready:
            self.immediateDispatchAdaptive(child, in: context, animated: animated) { result in
                completion(result)
            }
        case .batching:
            if _scheduledStartRoutine != nil {
                assertionFailure("Another child is waiting to be started; can't start multiple children at the same time")
                return
            }
            
            _scheduledStartRoutine = { [weak self] in
                guard let self = self else { return }
                
                self._scheduledStartRoutine = nil
                self.immediateDispatchAdaptive(child, in: context, animated: animated) { result in
                    completion(result)
                }
            }
        case .purging:
            assertionFailure("Please don't start during purges")
        }
    }
    
    func immediateDispatchAdaptive<NewResult>(
        _ child: AdaptiveCoordinator<NewResult>,
        in context: AdaptiveContext,
        animated: Bool,
        _ completion: @escaping (NewResult?) -> Void
    ) {
        switch context._internalContext {
        case .current:
            if let lastFrame = self.frames.last {
                if lastFrame.navigationData != nil {
                    self.immediateDispatchNavigation(child, animated: animated) { result in
                        completion(result)
                    }
                } else {
                    self.immediateDispatchModal(child, animated: animated) { result in
                        completion(result)
                    }
                }
            } else {
                switch self.root {
                case .navigation:
                    self.immediateDispatchNavigation(child, animated: animated) { result in
                        completion(result)
                    }
                case .modal:
                    self.immediateDispatchModal(child, animated: animated) { result in
                        completion(result)
                    }
                }
            }
        case .modal:
            self.immediateDispatchModal(child, animated: animated) { result in
                completion(result)
            }
        case .currentNavigation(let deferredNavigationController):
            if let lastFrame = self.frames.last {
                if lastFrame.navigationData != nil {
                    self.immediateDispatchNavigation(child, animated: animated) { result in
                        completion(result)
                    }
                } else {
                    let navigationController = deferredNavigationController.make()
                    
                    self.immediateDispatchNewNavigation(navigationController, child, animated: animated) { result in
                        completion(result)
                    }
                }
            } else {
                switch self.root {
                case .navigation:
                    self.immediateDispatchNavigation(child, animated: animated) { result in
                        completion(result)
                    }
                case .modal:
                    let navigationController = deferredNavigationController.make()
                    
                    self.immediateDispatchNewNavigation(navigationController, child, animated: animated) { result in
                        completion(result)
                    }
                }
            }
        case .newNavigation(let navigationController):
            self.immediateDispatchNewNavigation(navigationController, child, animated: animated) { result in
                completion(result)
            }
        }
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

private extension FrameState {
    var needsDismissalInADeadChain: Bool {
        switch self {
        case .finishedByDeinit, .finishedByKVO:
            return false
        case .finishedByCompletion, .live:
            return true
        }
    }
}

private extension Array {
    func replacing(_ index: Index, with element: Element) -> Array {
        var array = self
        array[index] = element
        return array
    }
    
    func replacingLast(with element: Element) -> Array {
        return self.replacing(self.count - 1, with: element)
    }
}

private extension Array {
    func appending(_ element: Element) -> Array {
        var array = self
        array.append(element)
        return array
    }
}

private extension Array {
    func at(_ index: Index) -> Element? {
        if index >= 0, index < count {
            return self[index]
        }
        return nil
    }
}

private extension Optional {
    #if DEBUG
    func assertingNotNil(_ file: StaticString = #file, _ line: UInt = #line) -> Optional {
        assert(self != nil, "\(type(of: Wrapped.self)) died too early")
        return self
    }
    #else
    @inline(__always) func assertingNotNil() -> Optional {
        return self
    }
    #endif
    
    #if DEBUG
    func assertNotNil(_ file: StaticString = #file, _ line: UInt = #line) {
        assert(self != nil, "\(type(of: Wrapped.self)) died too early")
    }
    #else
    @inline(__always) func assertNotNil() {
        
    }
    #endif
}
