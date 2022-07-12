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
        case precull(CoordinatorLocation)
        case culling
        
        var allowsPresentation: Bool {
            switch self {
            case .precull:
                return false
            case .ready, .culling:
                return true
            }
        }
    }
    
    var notDead: Bool
    var stage: Stage
}

private struct FrameNavigationChild {
    let coordinator: CommonNavigationCoordinatorAny
    weak var viewController: UIViewController?
    
    init(
        coordinator: CommonNavigationCoordinatorAny,
        viewController: UIViewController?
    ) {
        self.coordinator = coordinator
        self.viewController = viewController
    }
}

private struct FrameNavigationData {
    var children: [FrameNavigationChild]
    weak var navigationController: UINavigationController?
    weak var rootController: UIViewController?
    
    init(
        children: [FrameNavigationChild],
        navigationController: UINavigationController?,
        rootController: UIViewController?
    ) {
        self.children = children
        self.navigationController = navigationController
        self.rootController = rootController
    }
}

private class RootNavigationCrutchCoordinator: CommonCoordinatorAny {
    
}

private struct Frame {
    let coordinator: CommonCoordinatorAny
    weak var viewController: UIViewController?
    var navigationData: FrameNavigationData?
    
    init(
        coordinator: CommonCoordinatorAny,
        viewController: UIViewController?,
        navigationData: FrameNavigationData?
    ) {
        self.coordinator = coordinator
        self.viewController = viewController
        self.navigationData = navigationData
    }
}

public class InsecurityHost {
    fileprivate var frames: [Frame] = []
    
    fileprivate var state = InsecurityHostState(notDead: true,
                                                stage: .ready)
    
    func kill() {
        state.notDead = false
    }
    
    public init() {
        
    }
    
    // MARK: - Scheduled start routine
    
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
        case .precull:
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
        case .culling:
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
        
        guard let host = frames.last?.viewController else {
            assertionFailure("Frames chain integrity violated, one modal host is dead")
            return
        }
                
        let coordinates = CoordinatorLocation(frameIndex: frames.count,
                                              navigationFrameIndex: nil)
        
        
        let controller = child.bindToHost(self) { [weak self] result, finalizationKind in
            guard let self = self else { return }
            guard self.state.notDead else { return }
            
            switch self.state.stage {
            case .ready:
                self.state.stage = .precull(coordinates)
                completion(result)
                
            case .precull(let currentLowestCoordinates):
                let newLowestCoordinates = min(currentLowestCoordinates, coordinates)
                self.state.stage = .precull(newLowestCoordinates)
            case .culling:
                assertionFailure()
            }
        }
        
        let newFrame = Frame(coordinator: child,
                             viewController: controller,
                             navigationData: nil)
        
        frames.append(newFrame)
        
        host.present(controller, animated: animated, completion: nil)
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
        
        if indexOfFrameOpt != nil {
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
    }
    
    func sendOffNavigation(
        _ controller: UIViewController,
        _ animated: Bool,
        _ child: CommonNavigationCoordinatorAny
    ) {
        if let lastFrame = frames.last {
            if let navigationData = lastFrame.navigationData {
                let navigationFrame = FrameNavigationChild(
                    state: .live,
                    coordinator: child,
                    viewController: controller
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
                    assertionFailure("InsecurityHost wanted to start NavigationChild, but the UINavigationController was found dead")
                    return
                }
                
                let frameChild = FrameNavigationChild(
                    state: .live,
                    coordinator: child,
                    viewController: controller
                )
                
                let navigationData = FrameNavigationData(
                    children: [ frameChild ],
                    navigationController: navigationController,
                    rootController: navigationController.viewControllers[0]
                )
                
                // This is ass, this is really-really bad
                let frame = Frame(
                    state: .live,
                    coordinator: RootNavigationCrutchCoordinator(),
                    viewController: navigationController,
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
            navigationData: FrameNavigationData(
                children: [],
                navigationController: navigationController,
                rootController: controller
            )
        )
        
        self.frames.append(frame)
        
        navigationController.setViewControllers([ controller ], animated: false)
        electedHostController.present(navigationController, animated: animated, completion: nil)
    }
    
    // MARK: - Purge
    
    private func purge(locationOfFirstDeadCoordinator location: CoordinatorLocation) {
        guard let previousLocation = self.previousLocation(for: location) else {
            assertionFailure("How comes every frame died?")
        }
        
        resetAtLocation(previousLocation)
    }
    
    // MARK: - Reset
    
    enum CullingAction {
        struct Dismiss {
            let controller: UIViewController
        }
        
        struct Pop {
            let navigationController: UINavigationController
            let popToController: UIViewController
        }
        
        case dismiss(Dismiss)
        case pop(Pop)
        case popAndThenDismiss(Pop, Dismiss)
    }
    
    private func findAppropriateActionForReset(at location: CoordinatorLocation) -> CullingAction? {
        let frameIndex = location.frameIndex
        let frame = frames[frameIndex]
        
        // Let's see if popping will be necessary
        let popAction: CullingAction.Pop?
        
        if
            let navigationFrameIndex = location.navigationFrameIndex,
            let navigationData = frame.navigationData
        {
            let navigationFrame = navigationData.children[navigationFrameIndex]
            
            let nextNavigationFrameIndex = navigationFrameIndex + 1
            if
                let nextNavigationFrame = navigationData.children.at(nextNavigationFrameIndex),
                nextNavigationFrame.state.needsDismissalInADeadChain
            {
                // Yep, will need to pop
                
                if let navigationController = navigationData.navigationController {
                    if let popToController = navigationFrame.viewController {
                        popAction = CullingAction.Pop(navigationController: navigationController,
                                                      popToController: popToController)
                    } else {
                        insecPrint("Can't find a popToController during pop")
                        popAction = nil
                    }
                } else {
                    insecPrint("Can't find a navigationController during pop")
                    popAction = nil
                }
            } else {
                popAction = nil
            }
        } else {
            // No navigation frames in this frame, which means, that dismissing will be completely enough
            
            popAction = nil
        }
        
        let dismissAction: CullingAction.Dismiss?
        
        // Is there a next frame that will require modal dismissal?
        let nextFrameIndex = frameIndex + 1
        
        if
            let nextFrame = frames.at(nextFrameIndex),
            nextFrame.state.needsDismissalInADeadChain
        {
            // Alright, there is a next frame which will need to be dismissed
            if let dismissController = frame.viewController {
                dismissAction = CullingAction.Dismiss(controller: dismissController)
            } else {
                dismissAction = nil
                insecPrint("Can't find a controller to dismiss during culling")
            }
        } else {
            // No nextFrame, good, nothing to dismiss
            
            dismissAction = nil
        }
        
        switch (dismissAction, popAction) {
        case (nil, nil):
            return nil
        case (.some(let dismissAction), nil):
            return .dismiss(dismissAction)
        case (nil, .some(let popAction)):
            return .pop(popAction)
        case (.some(let dismissAction), .some(let popAction)):
            return .popAndThenDismiss(popAction, dismissAction)
        }
    }
    
    private func cullFramesAfterLocation(_ location: CoordinatorLocation) -> [Frame] {
        let frames = self.frames
        
        let culledFrames: [Frame]
        
        let frame = frames[location.frameIndex]
        
        let newlyCulledFrames = frames.removingAfter(index: location.frameIndex)
        
        if let navigationFrameIndex = location.navigationFrameIndex {
            let oldNavigationData = frame.navigationData!
            let oldChildren = oldNavigationData.children
            
            let culledChildren = oldChildren.removingAfter(index: navigationFrameIndex)
            
            let newNavigationData = FrameNavigationData(
                children: culledChildren,
                navigationController: oldNavigationData.navigationController,
                rootController: oldNavigationData.rootController
            )
            let newFrame = Frame(
                state: .live,
                coordinator: frame.coordinator,
                viewController: frame.viewController,
                navigationData: newNavigationData
            )
            
            let framesUpdatedWithNavigationData = newlyCulledFrames.replacingLast(with: newFrame)
            
            culledFrames = framesUpdatedWithNavigationData
        } else {
            culledFrames = newlyCulledFrames
        }
        
        return culledFrames
    }
    
    func reset(coordinator: CommonCoordinatorAny) {
        guard state.notDead else { return }
        
        let coordinatorLocation = findCoordinatorLocation(coordinator)
        
        guard let coordinatorLocation = coordinatorLocation else {
            assertionFailure("Calling reset on an untracked coordinator")
            return
        }
        
        resetAtLocation(coordinatorLocation)
    }
    
    func resetAtLocation(_ location: CoordinatorLocation) {
        let action = findAppropriateActionForReset(at: location)
        
        let culledFrames = cullFramesAfterLocation(location)
        
        self.frames = culledFrames
        
        if state.notDead {
            switch action {
            case .dismiss(let dismiss):
                dismiss.controller.dismiss(animated: true) { [weak self] in
                    self?.executeScheduledStartRoutine()
                }
            case .pop(let pop):
                pop.navigationController.popToViewController(pop.popToController, animated: true)
                self.executeScheduledStartRoutineWithDelay()
            case .popAndThenDismiss(let pop, let dismiss):
                pop.navigationController.popToViewController(pop.popToController, animated: false)
                dismiss.controller.dismiss(animated: true) { [weak self] in
                    self?.executeScheduledStartRoutine()
                }
            case nil:
                executeScheduledStartRoutine()
            }
        }
    }
        
    // MARK: - Calculus
    
    func previousLocation(for location: CoordinatorLocation) -> CoordinatorLocation? {
        if let navigationIndex = location.navigationFrameIndex {
            if navigationIndex > 0 {
                let previousNavigationIndex = navigationIndex - 1
                
                return CoordinatorLocation(frameIndex: location.frameIndex,
                                           navigationFrameIndex: previousNavigationIndex)
            } else {
                return CoordinatorLocation(frameIndex: location.frameIndex,
                                           navigationFrameIndex: nil)
            }
        } else {
            let previousFrameIndex = location.frameIndex - 1
            
            if let previousFrame = frames.at(previousFrameIndex) {
                if
                    let previousFrameNavigationData = previousFrame.navigationData
                {
                    if previousFrameNavigationData.children.isEmpty {
                        return CoordinatorLocation(frameIndex: previousFrameIndex,
                                                   navigationFrameIndex: nil)
                    } else {
                        let lastNavigationIndex = previousFrameNavigationData.children.count - 1
                        return CoordinatorLocation(frameIndex: previousFrameIndex,
                                                   navigationFrameIndex: lastNavigationIndex)
                    }
                } else {
                    return CoordinatorLocation(frameIndex: previousFrameIndex,
                                               navigationFrameIndex: nil)
                }
            } else {
                 return nil
            }
        }
    }
    
    private func findCoordinatorLocation(_ coordinator: CommonCoordinatorAny) -> CoordinatorLocation? {
        var frameIndex: Int?
        var navigationFrameIndex: Int?
        
        loop: for (index, frame) in frames.enumerated() {
            if frame.coordinator === coordinator {
                frameIndex = index
                break loop
            } else if let navigationData = frame.navigationData {
                for (navigationIndex, navigationChild) in navigationData.children.enumerated() {
                    if navigationChild.coordinator === coordinator {
                        frameIndex = index
                        navigationFrameIndex = navigationIndex
                        break loop
                    }
                }
            }
        }
        
        guard let frameIndex = frameIndex else {
            return nil
        }

        return CoordinatorLocation(frameIndex: frameIndex,
                                   navigationFrameIndex: navigationFrameIndex)
    }
    
#if DEBUG
    deinit {
        insecPrint("\(type(of: self)) deinit")
    }
#endif
}

// MARK: - Extensions

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
    
    func removingAfter(index: Int) -> Array {
        if index >= count {
            assertionFailure("Nothing to remove")
        }
        return Array(self.prefix(index + 1))
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
