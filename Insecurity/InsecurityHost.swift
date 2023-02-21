import UIKit

enum CoordinatorDeathReason {
    case result
    case deinitOrKvo
}

struct InsecurityHostState {
    enum Stage {
        struct Batching {
            struct ScheduledStart {
                let routine: () -> Void
                
                func routineAfterDelay() {
                    DispatchQueue.main.asyncAfter(Insecurity.navigationPopBatchedStartDelay, routine)
                }
            }
            
            let deepestDeadIndex: CoordinatorIndex
            let modalIndexThatNeedsDismissing: Int?
            let scheduledStart: ScheduledStart?
            
            func settingScheduledStart(_ scheduledStart: ScheduledStart) -> Batching {
                return Batching(deepestDeadIndex: deepestDeadIndex,
                                modalIndexThatNeedsDismissing: modalIndexThatNeedsDismissing,
                                scheduledStart: scheduledStart)
            }
        }
        
        case ready
        case batching(Batching)
        case purging
        case dead
    }
    
    var stage: Stage
}

// MARK: - InsecurityHost

public final class InsecurityHost {
    var frames: [Frame] = []

    var state = InsecurityHostState(stage: .ready)
    
    func kill() {
        state.stage = .dead
        self.frames.dismountFromHost()
        self.frames = []
    }
    
    public init() {
        
    }
    
    // MARK: - Modal
    
    func startModal<Coordinator: CommonModalCoordinator>(
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        switch state.stage {
        case .dead:
            insecAssertFail(.hostDiedBeforeStart)
        case .purging:
            insecFatalError(.noStartingWhilePurging)
        case .batching(let batching):
            let scheduledStart = InsecurityHostState.Stage.Batching.ScheduledStart { [unowned self] in
                guard let topAliveIndex = self.frames.topIndex() else {
                    insecAssertFail(.wantedToBatchedStartButHostIsNotMountedAnymore)
                    return
                }
                
                insecAssert(topAliveIndex == parentIndex,
                            .presumedParentForBatchedStartWasEitherDeadOrNotAtTheTopOfTheStack)
                
                self.startModalImmediately(child,
                                           after: topAliveIndex,
                                           animated: animated,
                                           completion)
            }
            self.state.stage = .batching(batching.settingScheduledStart(scheduledStart))
        case .ready:
            startModalImmediately(child,
                                  after: parentIndex,
                                  animated: animated,
                                  completion)
        }
    }
    
    private func startModalImmediately<Coordinator: CommonModalCoordinator>(
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        let index = CoordinatorIndex(modalIndex: parentIndex.modalIndex + 1,
                                     navigationData: nil)
        if let parentFrame = frames.at(parentIndex.modalIndex) {
            if let existingFrame = frames.at(index.modalIndex) {
                let aliveFramesCount = parentIndex.modalIndex + 1
                let aliveFrames = self.frames.prefix(aliveFramesCount)
                
                if let parentController = existingFrame.controller.value.insecAssertNotNil() {
                    let deadFrames = self.frames.suffix(self.frames.count - aliveFramesCount)
                    deadFrames.dismountFromHost()
                    
                    let controller = child.mountOnHostModal(self, index, completion: completion)
                    
                    let frame = Frame(coordinator: child,
                                      controller: controller,
                                      previousController: parentController,
                                      navigationData: nil)
                    
                    let newFrames = aliveFrames + [frame]
                    self.frames = Array(newFrames)
                    
                    if parentController.presentedViewController != nil {
                        parentController.dismiss(animated: animated) {
                            parentController.present(controller, animated: animated)
                        }
                    } else {
                        parentController.present(controller, animated: animated)
                    }
                }
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
    
    // MARK: - Navigation Current
    func startNavigation<Coordinator: CommonNavigationCoordinator>(
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        switch state.stage {
        case .dead:
            insecAssertFail(.hostDiedBeforeStart)
        case .purging:
            insecAssertFail(.noStartingWhilePurging)
        case .batching(let batching):
            let scheduledStart = InsecurityHostState.Stage.Batching.ScheduledStart { [unowned self] in
                guard let topAliveIndex = self.frames.topIndex() else {
                    insecAssertFail(.wantedToBatchedStartButHostIsNotMountedAnymore)
                    return
                }
                
                insecAssert(topAliveIndex == parentIndex,
                            .presumedParentForBatchedStartWasEitherDeadOrNotAtTheTopOfTheStack)
                
                insecAssert(topAliveIndex.navigationData != nil, .cantStartNavigationOverModalContext)
                
                self.startNavigationImmediately(child,
                                                after: topAliveIndex,
                                                animated: animated,
                                                completion)
            }
            self.state.stage = .batching(batching.settingScheduledStart(scheduledStart))
        case .ready:
            startNavigationImmediately(child,
                                       after: parentIndex,
                                       animated: animated,
                                       completion)
        }
    }
    
    func startNavigationImmediately<Coordinator: CommonNavigationCoordinator>(
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        let existingModalFrame = self.frames[parentIndex.modalIndex]
        guard let existingNavigationData = existingModalFrame.navigationData else {
            insecFatalError(.indexAssuredNavigationButFrameWasModal)
        }
        if
            let parentIndexNavData = parentIndex.navigationData,
            let navigationController = existingNavigationData.navigationController.value
        {
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
            
            let previousController: Weak<UIViewController>
            if let parentNavichildIndex = parentIndexNavData.navigationIndex {
                previousController = existingNavigationData.children[parentNavichildIndex].controller
            } else {
                previousController = existingNavigationData.rootController
            }
            let newNavichildFrame = FrameNavigationChild(coordinator: child,
                                                         controller: Weak(controller),
                                                         previousController: previousController)
            
            let navigationDataChildren = existingNavigationData.children
            let thereIsANaviChildAboveParentAlready = navigationDataChildren.at(newNavigationIndex) != nil
            if thereIsANaviChildAboveParentAlready {
                let aliveNavFramesCount = newNavigationIndex + 1
                let aliveNavFrames = navigationDataChildren.prefix(aliveNavFramesCount)
                let deadNavFrames = navigationDataChildren.suffix(navigationDataChildren.count - aliveNavFramesCount)
                
                deadNavFrames.dismountFromHost()
                
                let newNavFrames = aliveNavFrames + [newNavichildFrame]
                let newNavigationData = existingNavigationData.replacingChildren(Array(newNavFrames))
                let updatedFrame = existingModalFrame.replacingNavigationData(newNavigationData)
                let aliveModalFramesCount = parentIndex.modalIndex + 1
                let oldFrames = self.frames.prefix(aliveModalFramesCount)
                let newFrames = oldFrames.replacingLast(with: updatedFrame)
                 
                let existingViewControllers = navigationController.viewControllers
                let aliveControllers = existingViewControllers.prefix(aliveNavFramesCount)
                let newControllers = Array(aliveControllers + [controller])
                
                let thereIsAModalFrameAboveCurrent = self.frames.at(parentIndex.modalIndex + 1) != nil
                if thereIsAModalFrameAboveCurrent {
                    let aliveModalFramesCount = parentIndex.modalIndex + 1
                    let aliveModalFrames = self.frames.prefix(aliveModalFramesCount)
                    let deadModalFrames = self.frames.suffix(self.frames.count - aliveModalFramesCount)
                    deadModalFrames.dismountFromHost()
                    
                    self.frames = Array(newFrames)
                    
                    if navigationController.presentedViewController != nil {
                        navigationController.setViewControllers(newControllers, animated: false)
                        navigationController.dismiss(animated: animated)
                    } else {
                        navigationController.setViewControllers(newControllers, animated: animated)
                    }
                } else {
                    self.frames = Array(newFrames)
                    navigationController.setViewControllers(newControllers, animated: animated)
                }
            } else {
                let newNavichildren = navigationDataChildren + [newNavichildFrame]
                
                let newNavigationData = existingNavigationData.replacingChildren(newNavichildren)
                
                let frame = existingModalFrame.replacingNavigationData(newNavigationData)
                
                self.frames = self.frames.replacing(index.modalIndex, with: frame)
                
                navigationController.pushViewController(
                    controller,
                    animated: animated
                )
            }
        } else {
            insecAssertFail(.cantStartNavigationOverModalContext)
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
        switch state.stage {
        case .dead:
            insecAssertFail(.hostDiedBeforeStart)
        case .purging:
            insecAssertFail(.noStartingWhilePurging)
        case .batching(let batching):
            let scheduledStart = InsecurityHostState.Stage.Batching.ScheduledStart { [unowned self] in
                guard let topAliveIndex = self.frames.topIndex() else {
                    insecAssertFail(.wantedToBatchedStartButHostIsNotMountedAnymore)
                    return
                }
                
                insecAssert(topAliveIndex == parentIndex,
                            .presumedParentForBatchedStartWasEitherDeadOrNotAtTheTopOfTheStack)
                
                self.startNavigationNewImmediately(navigationController,
                                                   child,
                                                   after: topAliveIndex,
                                                   animated: animated,
                                                   completion)
            }
            self.state.stage = .batching(batching.settingScheduledStart(scheduledStart))
        case .ready:
            startNavigationNewImmediately(navigationController,
                                          child,
                                          after: parentIndex,
                                          animated: animated,
                                          completion)
        }
    }
    
    func startNavigationNewImmediately<Coordinator: CommonNavigationCoordinator>(
        _ navigationController: UINavigationController,
        _ child: Coordinator,
        after parentIndex: CoordinatorIndex,
        animated: Bool,
        _ completion: @escaping (Coordinator.Result?) -> Void
    ) {
        let index = CoordinatorIndex(
            modalIndex: parentIndex.modalIndex + 1,
            navigationData: CoordinatorIndex.NavigationData(
                navigationIndex: nil
            )
        )
        if let parentFrame = frames.at(parentIndex.modalIndex) {
            if let existingFrame = frames.at(index.modalIndex) {
                let aliveFramesCount = parentIndex.modalIndex + 1
                let aliveFrames = self.frames.prefix(aliveFramesCount)
                
                if let parentController = existingFrame.controller.value.insecAssertNotNil() {
                    let deadFrames = self.frames.suffix(self.frames.count - aliveFramesCount)
                    deadFrames.dismountFromHost()
                    
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
                    
                    let newFrames = aliveFrames + [frame]
                    self.frames = Array(newFrames)
                    
                    navigationController.setViewControllers([ controller ], animated: false)
                    if parentController.presentedViewController != nil {
                        parentController.dismiss(animated: animated) {
                            parentController.present(navigationController, animated: animated)
                        }
                    } else {
                        parentController.present(navigationController, animated: animated)
                    }
                }
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
    
    // MARK: - Purge
    
    private func purge(deepestDeadIndex: CoordinatorIndex,
                       modalIndexThatNeedsDismissing: Int?,
                       scheduledStart: InsecurityHostState.Stage.Batching.ScheduledStart?) {
        #if DEBUG
        insecPrint("Purging \(deepestDeadIndex.string) modalDismiss: \(modalIndexThatNeedsDismissing.flatMap({ "\($0)" }) ?? "nil")")
        #endif
        
        let prepurgeFrames = self.frames
        
        let postPurgeFrames: [Frame]
        
        let firstDeadChildIndex = deepestDeadIndex.modalIndex
        let firstDeadChild = prepurgeFrames[firstDeadChildIndex]
        
        if
            let navigationData = firstDeadChild.navigationData,
            let indexNavData = deepestDeadIndex.navigationData.presenceAssuredByIndex(),
            let navigationChildIndex = indexNavData.navigationIndex
        {
            let aliveNavChildrenCount = navigationChildIndex
            let deadNavChildrenCount = navigationData.children.count - aliveNavChildrenCount
            navigationData.children.suffix(deadNavChildrenCount).forEach { child in
                child.coordinator.dismountFromHost()
            }
            
            let aliveNavChildren = Array(navigationData.children.prefix(aliveNavChildrenCount))
            
            let aliveFramesCount = firstDeadChildIndex + 1
            let deadFramesCount = prepurgeFrames.count - aliveFramesCount
            
            let deadFrames = prepurgeFrames.suffix(deadFramesCount)
            deadFrames.dismountFromHost()
            
            let newFrames = Array(prepurgeFrames.prefix(aliveFramesCount))
            
            let newNavigationData = navigationData.replacingChildren(aliveNavChildren)
            let newFrame = firstDeadChild.replacingNavigationData(newNavigationData)
            
            let trulyNewFrames = newFrames.replacingLast(with: newFrame)
            
            postPurgeFrames = trulyNewFrames
        } else {
            let aliveFramesCount = firstDeadChildIndex
            let deadFramesCount = prepurgeFrames.count - aliveFramesCount
            
            let deadFrames = prepurgeFrames.suffix(deadFramesCount)
            for deadFrame in deadFrames {
                deadFrame.coordinator.dismountFromHost()
                deadFrame.navigationData?.children.forEach { child in
                    child.coordinator.dismountFromHost()
                }
            }
            
            postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex))
        }
        
        self.frames = postPurgeFrames
        
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
                    frameThatNeedsModalDismissal.previousController.value.insecAssertNotNil()
                    
                    navigationController.popToViewController(popToController, animated: false)
                    if let presentingViewController = frameThatNeedsModalDismissal.previousController.value {
                        presentingViewController.dismiss(animated: true) {
                            scheduledStart?.routine()
                        }
                    }
                } else {
                    navigationController.popToViewController(popToController, animated: true)
                    scheduledStart?.routineAfterDelay()
                }
            }
        } else {
            if modalIndexThatNeedsDismissing == deepestDeadIndex.modalIndex {
                firstDeadChild.previousController.value.insecAssertNotNil()?
                    .dismiss(animated: true) {
                        scheduledStart?.routine()
                    }
            } else {
                scheduledStart?.routine()
            }
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
#if DEBUG
        insecPrint("Index \(index.string) died")
#endif
        
        // Recursive function
        switch state.stage {
        case .dead:
            insecAssertFail(.hostDiedBeforeCoordinator)
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
                    modalIndexThatNeedsDismissing: modalIndexThatNeedsDismissing,
                    scheduledStart: nil
                )
            )
            callback(result)
            
            switch self.state.stage {
            case .batching(let batch):
                self.state.stage = .purging
                self.purge(
                    deepestDeadIndex: batch.deepestDeadIndex,
                    modalIndexThatNeedsDismissing: batch.modalIndexThatNeedsDismissing,
                    scheduledStart: batch.scheduledStart
                )
                self.state.stage = .ready
            case .ready, .purging:
                insecAssertFail(.unexpectedState)
            case .dead:
                break
            }
        case .batching(let batching):
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
                    modalIndexThatNeedsDismissing: modalIndexThatNeedsDismissing,
                    scheduledStart: batching.scheduledStart
                )
            )
            
            callback(result)
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
