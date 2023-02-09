import UIKit

enum CoordinatorDeathReason {
    case result
    case deinitOrKvo
}

struct InsecurityHostState {
    enum Stage {
        struct Batching {
            let deepestDeadIndex: CoordinatorIndex
            let modalIndexThatNeedsDismissing: Int?
        }
        
        case ready
        case batching(Batching)
        case purging
    }
    
    var stage: Stage
    var notDead: Bool
}

class FrameNavigationChild {
    let coordinator: CommonNavigationCoordinatorAny
    let controller: Weak<UIViewController>
    let previousController: Weak<UIViewController>
    
    init(
        coordinator: CommonNavigationCoordinatorAny,
        controller: Weak<UIViewController>,
        previousController: Weak<UIViewController>
    ) {
        self.coordinator = coordinator
        self.controller = controller
        self.previousController = previousController
    }
}

class FrameNavigationData {
    var children: [FrameNavigationChild]
    let navigationController: Weak<UINavigationController>
    let rootController: Weak<UIViewController>
    
    init(
        children: [FrameNavigationChild],
        navigationController: UINavigationController,
        rootController: UIViewController
    ) {
        self.children = children
        self.navigationController = Weak(navigationController)
        self.rootController = Weak(rootController)
    }
}

class Frame {
    let coordinator: CommonCoordinatorAny
    let controller: Weak<UIViewController>
    let previousController: Weak<UIViewController>
    let navigationData: FrameNavigationData?
    
    init(
        coordinator: CommonCoordinatorAny,
        controller: UIViewController,
        previousController: UIViewController,
        navigationData: FrameNavigationData?
    ) {
        self.coordinator = coordinator
        self.controller = Weak(controller)
        self.previousController = Weak(previousController)
        self.navigationData = navigationData
    }
}

// MARK: - InsecurityHost

public class InsecurityHost {
    fileprivate var frames: [Frame] = []

    fileprivate var state = InsecurityHostState(stage: .ready, notDead: true)
    
    func kill() {
        state.notDead = false
    }
    
    public init() {
        
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
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else {
            insecAssertFail(.hostDiedBeforeStart)
            return
        }
        
        switch state.stage {
        case .purging:
            insecFatalError(.noStartingWhilePurging)
        case .batching:
            fatalError("Not impl")
        case .ready:
            let index = CoordinatorIndex(modalIndex: parentIndex.modalIndex + 1,
                                         navigationData: nil)
            
            if let parentFrame = frames.at(parentIndex.modalIndex) {
                if let existingFrame = frames.at(index.modalIndex) {
                    fatalError("Not impl")
                } else {
                    if let parentController = parentFrame.controller.value {
                        let controller = child.mountOnHostModal(self, index, completion: completion)
                        
                        let frame = Frame(coordinator: child,
                                          controller: controller,
                                          previousController: parentController,
                                          navigationData: nil)
                        
                        self.frames = self.frames + [frame]
                        
                        parentController.present(controller, animated: animated)
                    } else {
                        insecAssertFail(.parentControllerHasBeenLost)
                    }
                }
            } else {
                insecAssertFail(.noFrameAtIndexPath)
            }
        }
    }
    
    // MARK: - Navigation Current
    func startNavigation<Coordinator: CommonNavigationCoordinator>(
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else {
            insecAssertFail(.hostDiedBeforeStart)
            return
        }
        
        switch state.stage {
        case .purging:
            insecAssertFail(.noStartingWhilePurging)
        case .batching:
            fatalError("Not implemented")
        case .ready:
            let existingModalFrame = self.frames[parentIndex.modalIndex]
            guard let existingNavigationData = existingModalFrame.navigationData else {
                insecFatalError(.indexAssuredNavigationButFrameWasModal)
            }
            if let parentIndexNavData = parentIndex.navigationData {
                let newNavigationIndex: Int
                if let naviChildIndex = parentIndexNavData.navigationIndex {
                    newNavigationIndex = naviChildIndex + 1
                } else {
                    newNavigationIndex = 0
                }
                let index = CoordinatorIndex(
                    modalIndex: parentIndex.modalIndex,
                    navigationData: CoordinatorIndex.NavigationData(
                        navigationIndex: newNavigationIndex
                    )
                )
                
                let controller = child.mountOnHostNavigation(self, index, completion: completion)
                
                if let existingNavigationChild = existingNavigationData.children.at(newNavigationIndex) {
                    fatalError("Unimplemented")
                } else {
                    let previousController: Weak<UIViewController>
                    if let parentNavichildIndex = parentIndexNavData.navigationIndex {
                        previousController = existingNavigationData.children[parentNavichildIndex].controller
                    } else {
                        previousController = existingNavigationData.rootController
                    }
                    let newNavichildFrame = FrameNavigationChild(coordinator: child,
                                                                 controller: Weak(controller),
                                                                 previousController: previousController)
                    let newNavichildren = existingNavigationData.children + [newNavichildFrame]
                    
                    existingNavigationData.children = newNavichildren // MODIFICATION BY REFERENCE
                    
                    existingNavigationData.navigationController.value.insecAssertNotNil()?.pushViewController(
                        controller,
                        animated: animated
                    )
                }
            } else {
                insecAssertFail(.cantStartNavigationOverModalContext)
            }
        }
        
    }
    
    // MARK: - Navigation New
    
    func startNavigationNew<Coordinator: CommonNavigationCoordinator>(
        _ navigationController: UINavigationController,
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        guard state.notDead else {
            insecAssertFail(.hostDiedBeforeStart)
            return
        }
        
        switch state.stage {
        case .purging:
            insecAssertFail(.noStartingWhilePurging)
        case .batching:
            fatalError("Not implemented")
        case .ready:
            let index = CoordinatorIndex(
                modalIndex: parentIndex.modalIndex + 1,
                navigationData: CoordinatorIndex.NavigationData(
                    navigationIndex: nil
                )
            )
            if let parentFrame = frames.at(parentIndex.modalIndex) {
                if let existingFrame = frames.at(index.modalIndex) {
                    fatalError("Not impl")
                } else {
                    if let parentController = parentFrame.controller.value {
                        let controller = child.mountOnHostNavigation(self, index, completion: completion)
                        
                        let frame = Frame(
                            coordinator: child,
                            controller: navigationController,
                            previousController: parentController,
                            navigationData: FrameNavigationData(
                                children: [],
                                navigationController: navigationController,
                                rootController: controller
                            )
                        )
                        
                        self.frames.append(frame)
                        
                        navigationController.setViewControllers([ controller ], animated: false)
                        parentController.present(navigationController, animated: animated, completion: nil)
                    } else {
                        insecAssertFail(.parentControllerHasBeenLost)
                    }
                }
            } else {
                insecAssertFail(.noFrameAtIndexPath)
            }
        }
    }
    
    // MARK: - Purge
    
    private func purge(deepestDeadIndex: CoordinatorIndex,
                       modalIndexThatNeedsDismissing: Int?) {
        let prepurgeFrames = self.frames
        
        let postPurgeFrames: [Frame]
        
        let firstDeadChildIndex = deepestDeadIndex.modalIndex
        let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
        
        if let navigationData = firstDeadChild.navigationData {
            if let indexNavData = deepestDeadIndex.navigationData {
                if let navigationChildIndex = indexNavData.navigationIndex {
                    var newFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex + 1))
                    
                    let newNavigationChildren = Array(navigationData.children.prefix(navigationChildIndex))
                    
                    if let lastFrame = newFrames.last {
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
                insecFatalError(.indexAssuredNavigationButFrameWasModal)
            }
        } else {
            postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex))
        }
        
        self.frames = postPurgeFrames
        
        if state.notDead {
            let firstDeadChildIndex = deepestDeadIndex.modalIndex
            let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
            
            if
                let deadNavIndex = deepestDeadIndex.navigationData?.navigationIndex,
                let deadNavData = firstDeadChild.navigationData
            {
                let deadNavChild = deadNavData.children[deadNavIndex]
                
                let frameThatNeedsModalDismissalOpt: Frame?
                if let modalIndexThatNeedsDismissing = modalIndexThatNeedsDismissing {
                    frameThatNeedsModalDismissalOpt = prepurgeFrames[modalIndexThatNeedsDismissing]
                } else {
                    frameThatNeedsModalDismissalOpt = nil
                }
                if
                    let navigationController = deadNavData.navigationController.value.insecAssertNotNil(),
                    let popToController = deadNavChild.previousController.value.insecAssertNotNil()
                {
                    if let frameThatNeedsModalDismissal = frameThatNeedsModalDismissalOpt {
                        frameThatNeedsModalDismissal.previousController.value.assertNotNil()
                        
                        navigationController.popToViewController(popToController, animated: false)
                        if let presentingViewController = frameThatNeedsModalDismissal.previousController.value {
                            presentingViewController.dismiss(animated: true) { [weak self] in
                                self?.executeScheduledStartRoutine()
                            }
                        }
                    } else {
                        navigationController.popToViewController(popToController, animated: true)
                        executeScheduledStartRoutineWithDelay()
                    }
                }
            } else {
                if modalIndexThatNeedsDismissing == deepestDeadIndex.modalIndex {
                    firstDeadChild.previousController.value.insecAssertNotNil()?
                        .dismiss(animated: true) { [weak self] in
                            self?.executeScheduledStartRoutine()
                        }
                } else {
                    executeScheduledStartRoutine()
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
    
    // MARK: - New API
    
    func handleCoordinatorDied<Result>(_ coordinator: CommonCoordinatorAny,
                                       _ index: CoordinatorIndex,
                                       _ deathReason: CoordinatorDeathReason,
                                       _ result: Result?,
                                       _ callback: (Result?) -> Void) {
        guard state.notDead else {
            insecAssertFail(.hostDiedBeforeCoordinator)
            return
        }
        // Recursive function
        switch state.stage {
        case .ready:
            let modalIndexThatNeedsDismissing: Int?
            switch deathReason {
            case .deinitOrKvo:
                modalIndexThatNeedsDismissing = nil
            case .result:
                modalIndexThatNeedsDismissing = index.modalIndex
            }
            
            self.state.stage = .batching(
                InsecurityHostState.Stage.Batching(
                    deepestDeadIndex: index,
                    modalIndexThatNeedsDismissing: modalIndexThatNeedsDismissing
                )
            )
            callback(result)
            
            switch self.state.stage {
            case .batching(let batch):
                self.state.stage = .purging
                self.purge(
                    deepestDeadIndex: batch.deepestDeadIndex,
                    modalIndexThatNeedsDismissing: batch.modalIndexThatNeedsDismissing
                )
                self.state.stage = .ready
            case .ready, .purging:
                insecAssertFail(.unexpectedState)
            }
        case .batching(let batching):
            if self.state.notDead {
                let newDeepestDeadIndex: CoordinatorIndex
                let modalIndexThatNeedsDismissing: Int?
                let needsNavigationDismissal: Bool
                
                let modalComparison = compare(index.modalIndex, batching.deepestDeadIndex.modalIndex)
                
                switch modalComparison {
                case .equal:
                    // Same modal frame
                    switch (index.navigationData, batching.deepestDeadIndex.navigationData) {
                    case let (.some(newlyNavigationData), .some(deepestNavigationData)):
                        // It's 2 navigation frames inside one modal frame
                        
                        switch (newlyNavigationData.navigationIndex, deepestNavigationData.navigationIndex) {
                        case let (.some(newDeadNavIndex), .some(deepestDeadNavIndex)):
                            // Both navigation frames are child frames
                            switch compare(newDeadNavIndex, deepestDeadNavIndex) {
                            case .equal:
                                // Same navigation coordinator that is a navigation child has died twice
                                insecFatalError(.coordinatorDiedTwice)
                            case .less:
                                // Navigation child that just died is deeper
                                newDeepestDeadIndex = index
                                
                                switch deathReason {
                                case .deinitOrKvo:
                                    needsNavigationDismissal = false
                                case .result:
                                    needsNavigationDismissal = true
                                }
                                // And regarding modal dismissal - I guess we just preserve
                                modalIndexThatNeedsDismissing = batching.modalIndexThatNeedsDismissing
                            case .greater:
                                // Newly died nav child is above the deepest
                                // Do nothing
                                newDeepestDeadIndex = batching.deepestDeadIndex
                                modalIndexThatNeedsDismissing = batching.modalIndexThatNeedsDismissing
                            }
                        case (.some, nil):
                            // Newly dead one is a navigation child
                            // while deepest one is root
                            // child > root, root is deeper, do nothing
                            newDeepestDeadIndex = batching.deepestDeadIndex
                            modalIndexThatNeedsDismissing = batching.modalIndexThatNeedsDismissing
                        case (nil, .some):
                            // Newly dead coordinator is the root controller
                            // While current deepest is merely a child
                            newDeepestDeadIndex = index
                            // Navigation dismissal not needed because when root dies,
                            // it's a transition of modal dismissal
                            needsNavigationDismissal = false
                            switch deathReason {
                            case .result:
                                modalIndexThatNeedsDismissing = index.modalIndex
                            case .deinitOrKvo:
                                modalIndexThatNeedsDismissing = nil
                            }
                        case (nil, nil):
                            // Same navigation coordinator that is a root has died twice
                            insecFatalError(.coordinatorDiedTwice)
                        }
                    case (nil, nil):
                        // This is the same modal frame with no navigation
                        insecFatalError(.coordinatorDiedTwice)
                    case (.some, nil), (nil, .some):
                        // Two comparable frames with same modal index should have similar presence/absense of navdata
                        insecFatalError(.twoIndicesHaveSameModalIndexButNavDataDiffers)
                    }
                case .less:
                    // Modal index is less than current deepest - definitely deeper!
                    newDeepestDeadIndex = index
                    
                    if let navigationData = index.navigationData {
                        // This is a modal frame with nav data
                        if navigationData.navigationIndex != nil {
                            // This is a navigation child
                            // This means, the UINavigationController doesn't die
                            // The need for modal dismissal still affects only controllers above
                            
                            modalIndexThatNeedsDismissing = batching.modalIndexThatNeedsDismissing
                            switch deathReason {
                            case .deinitOrKvo:
                                needsNavigationDismissal = false
                            case .result:
                                needsNavigationDismissal = true
                            }
                        } else {
                            // this is a navigation root
                            
                            // If a nav root dies, there is no need to do UINavigationController popping
                            // since the transition is modal dismissal
                            
                            needsNavigationDismissal = false
                            
                            // ... as I said, modal dismissal
                            switch deathReason {
                            case .result:
                                modalIndexThatNeedsDismissing = index.modalIndex
                            case .deinitOrKvo:
                                modalIndexThatNeedsDismissing = nil
                            }
                        }
                    } else {
                        // This is a pure modal frame
                        
                        // Every single navigation context above just dies, so no need to manipulate it
                        needsNavigationDismissal = false
                        
                        // Modal dismissal is determined by deathReason
                        switch deathReason {
                        case .result:
                            modalIndexThatNeedsDismissing = index.modalIndex
                        case .deinitOrKvo:
                            modalIndexThatNeedsDismissing = nil
                        }
                    }
                case .greater:
                    // Modal index is greater than current deepest
                    // Do nothing
                    newDeepestDeadIndex = batching.deepestDeadIndex
                    modalIndexThatNeedsDismissing = batching.modalIndexThatNeedsDismissing
                }
                
                self.state.stage = .batching(
                    InsecurityHostState.Stage.Batching(
                        deepestDeadIndex: newDeepestDeadIndex,
                        modalIndexThatNeedsDismissing: modalIndexThatNeedsDismissing
                    )
                )
                
                callback(result)
            } else {
                insecAssertFail(.hostDiedMidBatch)
            }
        case .purging:
            insecAssertFail(.noDyingWhilePurging)
        }
    }
    
    // MARK: - NEW Mount API
    
    public func mount<Result>(_ coordinator: ModalCoordinator<Result>,
                              on parentController: UIViewController,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void) {
        guard frames.isEmpty else {
            insecFatalError(.hostIsAlreadyMounted)
        }
            
        let index = CoordinatorIndex(modalIndex: 0, navigationData: nil)
        let controller = coordinator.mountOnHostModal(self, index, completion: completion)
        let frame = Frame(coordinator: coordinator,
                          controller: controller,
                          previousController: parentController, navigationData: nil)
        self.frames = [frame]
        
        parentController.present(controller, animated: animated)
    }
}
