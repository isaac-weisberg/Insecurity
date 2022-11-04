import UIKit

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
    private var frames: [Frame] = []
    private var state = InsecurityHostState(notDead: true,
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
            self?.handleCoordinatorFinished(with: result, at: coordinates, completion)
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
        case .precull:
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
        case .culling:
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
        
        guard let lastFrame = frames.last else {
            assertionFailure("Why would there be no frames")
            return
        }
        
        guard let lastFrameNavigationData = lastFrame.navigationData else {
            assertionFailure("Starting a navigationChild in non-navigation context")
            return
        }
        
        guard let host = lastFrameNavigationData.navigationController else {
            assertionFailure("No navigation controller to start a child, it died")
            return
        }
        
        let coordinates = CoordinatorLocation(frameIndex: frames.count - 1,
                                              navigationFrameIndex: lastFrameNavigationData.children.count)
        
        let controller = child.bindToHost(self) { [weak self] result, finalizationKind in
            self?.handleCoordinatorFinished(with: result, at: coordinates, completion)
        }
        
        let navigationFrame = FrameNavigationChild(coordinator: child,
                                                   viewController: controller)
        let newNavigationDataChildren = lastFrameNavigationData.children + [navigationFrame]
        let newNavigationData = FrameNavigationData(children: newNavigationDataChildren,
                                                    navigationController: lastFrameNavigationData.navigationController,
                                                    rootController: lastFrameNavigationData.rootController)
        let newFrame = Frame(coordinator: lastFrame.coordinator,
                             viewController: lastFrame.viewController,
                             navigationData: newNavigationData)
        
        let newFrames = self.frames.replacingLast(with: newFrame)
        
        self.frames = newFrames
        
        host.pushViewController(controller, animated: animated)
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
        case .precull:
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
        case .culling:
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
        
        guard let host = frames.last?.viewController else {
            return
        }
        
        let newNavigationCoordinator = NewNavigationCoordinator(child)
        
        let coordinates = CoordinatorLocation(frameIndex: frames.count,
                                              navigationFrameIndex: nil)
        
        let controller = newNavigationCoordinator.bindToHost(self, navigationController) { [weak self] result, finalizationKind in
            self?.handleCoordinatorFinished(with: result, at: coordinates) { result in
                completion(result)
            }
        }
        
        let frame = Frame(
            coordinator: child,
            viewController: navigationController,
            navigationData: FrameNavigationData(
                children: [],
                navigationController: navigationController,
                rootController: controller
            )
        )
        
        self.frames.append(frame)
        
        host.present(navigationController, animated: animated, completion: nil)
    }
    
    // MARK: - Purge
    
    private func handleCoordinatorFinished<Result>(with result: Result?,
                                                   at coordinates: CoordinatorLocation,
                                                   _ completion: @escaping (Result?) -> Void) {
        guard self.state.notDead else { return }
        
        switch self.state.stage {
        case .ready:
            self.state.stage = .precull(coordinates)
            completion(result)
            
            switch self.state.stage {
            case .precull(let minimumCoordinates):
                self.state.stage = .culling
                self.purge(locationOfFirstDeadCoordinator: minimumCoordinates)
                self.state.stage = .ready
            case .culling, .ready:
                assertionFailure()
            }
        case .precull(let currentLowestCoordinates):
            let newLowestCoordinates = min(currentLowestCoordinates, coordinates)
            self.state.stage = .precull(newLowestCoordinates)
        case .culling:
            assertionFailure()
        }
    }
    
    private func purge(locationOfFirstDeadCoordinator location: CoordinatorLocation) {
        guard let previousLocation = self.previousLocation(for: location) else {
            assertionFailure("How comes every frame died?")
            return
        }
        
        resetAtLocation(previousLocation)
    }
    
    // MARK: - Mount
    
    public func mount(navigation navigationController: UINavigationController) {
        guard frames.isEmpty else {
            assertionFailure("Already mounted")
            return
        }
        guard let rootController = navigationController.viewControllers.first else {
            fatalError("Root controller on UINavigationController must be already set")
        }
        self.frames = [
            Frame(coordinator: InsecurityHostRootCoordinator(),
                  viewController: navigationController,
                  navigationData: FrameNavigationData(children: [],
                                                      navigationController: navigationController,
                                                      rootController: rootController))
        ]
    }
    
    public func mount(modal modalController: UIViewController) {
        guard frames.isEmpty else {
            assertionFailure("Already mounted")
            return
        }
        self.frames = [
            Frame(coordinator: InsecurityHostRootCoordinator(),
                  viewController: modalController,
                  navigationData: nil)
        ]
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
            let navigationData = frame.navigationData
        {
            if let navigationFrameIndex = location.navigationFrameIndex {
                let navigationFrame = navigationData.children[navigationFrameIndex]
                
                let nextNavigationFrameIndex = navigationFrameIndex + 1
                
                if navigationData.children.at(nextNavigationFrameIndex) != nil {
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
                if navigationData.children.isEmpty {
                    popAction = nil
                } else {
                    if let navigationController = navigationData.navigationController {
                        if let popToController = navigationData.rootController {
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
                }
            }
        } else {
            // No navigation frames in this frame, which means, that dismissing will be completely enough
            
            popAction = nil
        }
        
        let dismissAction: CullingAction.Dismiss?
        
        // Is there a next frame that will require modal dismissal?
        let nextFrameIndex = frameIndex + 1
        
        if frames.at(nextFrameIndex) != nil {
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
