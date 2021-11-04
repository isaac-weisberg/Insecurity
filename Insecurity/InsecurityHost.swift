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

private enum FrameKind {
    case modal
    case navigation(FrameNavigationData)
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

private extension Frame {
    var frameKind: FrameKind {
        if let navigationData = navigationData {
            return .navigation(navigationData)
        }
        return .modal
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
            if let navigationData = frame.navigationData {
                if frame.coordinator === child {
                    return true
                } else {
                    let firstIndexInsideNavigationOpt = navigationData.children.firstIndex(where: { navigationChild in
                        return navigationChild.coordinator === child
                    })
                    
                    if let firstIndexInsideNavigation = firstIndexInsideNavigationOpt {
                        indexInsideNavigationOpt = firstIndexInsideNavigation
                        return true
                    } else {
                        return false
                    }
                }
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
            switch lastFrame {
            case .navigation(let navigationLastFrame):
                guard let navigationController = navigationLastFrame.navigationController else {
                    assertionFailure("NavigationHost wanted to start NavigationChild, but the UINavigationController was found dead")
                    return
                }
                
                let frameChild = Frame.NavigationChildFrame(
                    state: .live,
                    coordinator: child,
                    viewController: controller,
                    popToViewController: navigationLastFrame.children.last?.viewController
                )
                
                self.frames = self.frames.replacing(
                    self.frames.count - 1,
                    with: .navigation(
                        .init(
                            children: navigationLastFrame.children.appending(frameChild),
                            navigationController: navigationController,
                            presentingViewController: navigationLastFrame.presentingViewController
                        )
                    )
                )
                
                navigationController.pushViewController(controller, animated: animated)
            case .rootNavigation(let navigationLastFrame):
                guard let navigationController = navigationLastFrame.navigationController else {
                    assertionFailure("NavigationHost wanted to start NavigationChild, but the UINavigationController was found dead")
                    return
                }
                
                let frameChild = Frame.NavigationChildFrame(
                    state: .live,
                    coordinator: child,
                    viewController: controller,
                    popToViewController: navigationLastFrame.children.last?.viewController
                )
                
                self.frames = self.frames.replacing(
                    self.frames.count - 1,
                    with: .rootNavigation(
                        .init(
                            children: navigationLastFrame.children.appending(frameChild),
                            navigationController: navigationController
                        )
                    )
                )
                
                navigationController.pushViewController(controller, animated: animated)
            case .modal:
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
                
                let frameChild = Frame.NavigationChildFrame(
                    state: .live,
                    coordinator: child,
                    viewController: controller,
                    popToViewController: navigationController.viewControllers[0]
                )
                
                self.frames = [
                    .rootNavigation(
                        Frame.RootNavigation(
                            children: [ frameChild ],
                            navigationController: navigationController
                        )
                    )
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
        
        let navigationFrameChild = Frame.NavigationChildFrame(state: .live,
                                                         coordinator: child,
                                                         viewController: controller,
                                                         popToViewController: nil)
        let frame = Frame.navigation(Frame.Navigation(children: [navigationFrameChild],
                                                      navigationController: navigationController,
                                                      presentingViewController: electedHostController))
        self.frames.append(frame)
        
        navigationController.setViewControllers([ controller ], animated: false)
        electedHostController.present(navigationController, animated: animated, completion: nil)
    }
    
    // MARK: - Purge
    
    private func purge() {
        let prepurgeFrames = self.frames
        
        var firstDeadNavigationChildIndex: Int!
        let firstDeadChildIndexOpt = prepurgeFrames.firstIndex(where: { frame in
            switch frame {
            case .modal(let modal):
                switch modal.state {
                case .finishedByDeinit, .finishedByKVO, .finishedByCompletion:
                    return true
                case .live:
                    return false
                }
            case .navigation(let navigation):
                let firstDeadNavigationIndexOpt = navigation.children.firstIndex(where: { child in
                    switch child.state {
                    case .finishedByDeinit, .finishedByKVO, .finishedByCompletion:
                        return true
                    case .live:
                        return false
                    }
                })
                
                if let firstDeadNavigationIndex = firstDeadNavigationIndexOpt {
                    firstDeadNavigationChildIndex = firstDeadNavigationIndex
                    return true
                }
                return false
            case .rootNavigation(let navigation):
                let firstDeadNavigationIndexOpt = navigation.children.firstIndex(where: { child in
                    switch child.state {
                    case .finishedByDeinit, .finishedByKVO, .finishedByCompletion:
                        return true
                    case .live:
                        return false
                    }
                })
                
                if let firstDeadNavigationIndex = firstDeadNavigationIndexOpt {
                    firstDeadNavigationChildIndex = firstDeadNavigationIndex
                    return true
                }
                return false
            }
        })
        
        let postPurgeFrames: [Frame]
        
        if let firstDeadChildIndex = firstDeadChildIndexOpt {
            let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
            
            switch firstDeadChild {
            case .modal:
                postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex))
            case .rootNavigation(let rootNavigation):
                let newRootNavigation = Frame.rootNavigation(
                    Frame.RootNavigation(
                        children: Array(rootNavigation.children.prefix(firstDeadNavigationChildIndex)),
                        navigationController: rootNavigation.navigationController
                    )
                )
                
                postPurgeFrames = [ newRootNavigation ]
            case .navigation(let navigation):
                if firstDeadNavigationChildIndex == 0 {
                    postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex))
                } else {
                    postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex + 1))
                        .replacing(
                            firstDeadChildIndex,
                            with: .navigation(
                                Frame.Navigation(
                                    children: Array(navigation.children.prefix(firstDeadNavigationChildIndex)),
                                    navigationController: navigation.navigationController,
                                    presentingViewController: navigation.presentingViewController
                                )
                            )
                        )
                }
            }
        } else {
            assertionFailure("Noone died?")
            postPurgeFrames = prepurgeFrames
        }
        
        self.frames = postPurgeFrames
        
        if state.notDead, let firstDeadChildIndex = firstDeadChildIndexOpt {
            let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
            
            switch firstDeadChild {
            case .rootNavigation(let navigation):
                if let navigationController = navigation.navigationController {
                    let deadNavigationChild = navigation.children[firstDeadNavigationChildIndex]
                    
                    let frameAboveOpt = prepurgeFrames.at(firstDeadChildIndex + 1)
                    
                    switch deadNavigationChild.state {
                    case .live:
                        fatalError()
                    case .finishedByCompletion:
                        if let popToController = deadNavigationChild.popToViewController {
                            if let frameAbove = frameAboveOpt {
                                if let frameAbovePresentingController = frameAbove.presentingViewController {
                                    let frameAboveNeedsDismissal = frameAbove.needsDismissalInADeadChain
                                    
                                    if frameAboveNeedsDismissal {
                                        navigationController.popToViewController(popToController, animated: false)
                                        frameAbovePresentingController.dismiss(animated: true) { [weak self] in
                                            self?.executeScheduledStartRoutine()
                                        }
                                    } else {
                                        navigationController.popToViewController(popToController, animated: true)
                                        executeScheduledStartRoutineWithDelay()
                                    }
                                } else {
                                    navigationController.popToViewController(popToController, animated: true)
                                    executeScheduledStartRoutineWithDelay()
                                }
                            } else {
                                navigationController.popToViewController(popToController, animated: true)
                                executeScheduledStartRoutineWithDelay()
                            }
                        } else {
                            assertionFailure("Huh?")
                            if let frameAbovePresentingController = frameAboveOpt?.presentingViewController {
                                frameAbovePresentingController.dismiss(animated: true) { [weak self] in
                                    self?.executeScheduledStartRoutine()
                                }
                            } else {
                                executeScheduledStartRoutine()
                            }
                        }
                    case .finishedByKVO, .finishedByDeinit:
                        if let frameAbovePresentingController = frameAboveOpt?.presentingViewController {
                            frameAbovePresentingController.dismiss(animated: true) { [weak self] in
                                self?.executeScheduledStartRoutine()
                            }
                        } else {
                            executeScheduledStartRoutine()
                        }
                    }
                } else {
                    executeScheduledStartRoutine()
                }
            case .navigation(let navigation):
                let deadNavigationFrameChild = navigation.children[firstDeadNavigationChildIndex]
                let frameAboveOpt = prepurgeFrames.at(firstDeadChildIndex + 1)
                
                switch deadNavigationFrameChild.state {
                case .live:
                    fatalError()
                case .finishedByDeinit, .finishedByKVO:
                    if let frameAbove = frameAboveOpt, let presetingController = frameAbove.presentingViewController {
                        presetingController.dismiss(animated: true) { [weak self] in
                            self?.executeScheduledStartRoutine()
                        }
                    } else {
                        // Well, we're cleaned up
                        executeScheduledStartRoutine()
                    }
                case .finishedByCompletion:
                    
                }
                
                if let popToController = deadNavigationFrameChild.popToViewController {
                    if let navigationController = navigation.navigationController {
                        let frameAboveOpt = prepurgeFrames.at(firstDeadChildIndex + 1)
                        
                        if let frameAbove = frameAboveOpt {
                            if let frameAbovePresentingController = frameAboveOpt?.presentingViewController {
                                let frameAboveNeedsDismissal = frameAbove.needsDismissalInADeadChain
                                
                                if frameAboveNeedsDismissal {
                                    navigationController.popToViewController(popToController, animated: false)
                                    frameAbovePresentingController.dismiss(animated: true) { [weak self] in
                                        self?.executeScheduledStartRoutine()
                                    }
                                } else {
                                    navigationController.popToViewController(popToController, animated: true)
                                    executeScheduledStartRoutineWithDelay()
                                }
                            } else {
                                navigationController.popToViewController(popToController, animated: true)
                                executeScheduledStartRoutineWithDelay()
                            }
                        } else {
                            navigationController.popToViewController(popToController, animated: true)
                            executeScheduledStartRoutineWithDelay()
                        }
                        
                    } else {
                        executeScheduledStartRoutine()
                    }
                } else {
                    assertionFailure("thats wrong")
                    if let presentingController = navigation.presentingViewController {
                        presentingController.dismiss(animated: true) { [weak self] in
                            self?.executeScheduledStartRoutine()
                        }
                    } else {
                        executeScheduledStartRoutine()
                    }
                }
            case .modal(let modal):
                switch modal.state {
                case .live:
                    fatalError()
                case .finishedByDeinit, .finishedByKVO:
                    self.executeScheduledStartRoutine()
                case .finishedByCompletion:
                    if let presentingController = modal.presentingViewController {
                        presentingController.dismiss(animated: true) { [weak self] in
                            self?.executeScheduledStartRoutine()
                        }
                    } else {
                        self.executeScheduledStartRoutine()
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
                switch lastFrame {
                case .navigation, .rootNavigation:
                    self.immediateDispatchNavigation(child, animated: animated) { result in
                        completion(result)
                    }
                case .modal:
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
                switch lastFrame {
                case .navigation, .rootNavigation:
                    self.immediateDispatchNavigation(child, animated: animated) { result in
                        completion(result)
                    }
                case .modal:
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

private extension InsecurityHost.Frame {
    var viewController: UIViewController? {
        switch self {
        case .modal(let modal):
            return modal.viewController
        case .navigation(let navigation):
            return navigation.navigationController
        case .rootNavigation(let rootNavigation):
            return rootNavigation.navigationController
        }
    }
    
    var presentingViewController: UIViewController? {
        switch self {
        case .rootNavigation:
            return nil
        case .navigation(let navigation):
            return navigation.presentingViewController
        case .modal(let modal):
            return modal.presentingViewController
        }
    }
    
    var needsDismissalInADeadChain: Bool {
        switch self {
        case .rootNavigation:
            return false
        case .modal(let modal):
            switch modal.state {
            case .live:
                assertionFailure("Not supposed to be live, it's dead chain")
                return false
            case .finishedByDeinit, .finishedByKVO:
                return false
            case .finishedByCompletion:
                return true
            }
        case .navigation(let navigation):
            if let firstChild = navigation.children.first {
                switch firstChild.state {
                case .live:
                    assertionFailure("Not supposed to be live, it's dead chain")
                    return false
                case .finishedByCompletion:
                    return true
                case .finishedByKVO, .finishedByDeinit:
                    return false
                }
            } else {
                return false
            }
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

private extension Array {
    func at(_ index: Index) -> Element? {
        if index >= 0, index < count {
            return self[index]
        }
        return nil
    }
}
