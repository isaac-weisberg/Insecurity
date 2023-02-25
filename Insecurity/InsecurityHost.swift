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
        let preTransformFrames = self.frames
        // Sanity checks
        
        let parentFrame = preTransformFrames[parentIndex.modalIndex]
        guard let parentNavigationData = parentFrame.navigationData else {
            insecAssertFail(.indexAssuredNavigationButFrameWasModal)
            return
        }
        guard let parentNavIndex = parentIndex.assertNavigationIndex() else {
            return
        }
        
        // Mount Coordinator
        let index = parentNavIndex.nextNavichildIndex
        
        let controller = child.mountOnHostNavigation(self, index.asUntypedIndex, completion: completion)
        
        let previousController: Weak<UIViewController>
        if let parentNavichildIndex = parentNavIndex.navichildIndex {
            previousController = parentNavigationData.children[parentNavichildIndex].controller
        } else {
            previousController = parentNavigationData.rootController
        }
        let newNavichildFrame = FrameNavigationChild(coordinator: child,
                                                     controller: Weak(controller),
                                                     previousController: previousController)
        
        // Transform frames
        
        // Calculate dead modal frames
        let aliveFramesCount = parentIndex.modalIndex + 1
        let deadFramesCount = preTransformFrames.count - aliveFramesCount
        let oldFrames = preTransformFrames.suffix(deadFramesCount)
        let aliveFrames = preTransformFrames.prefix(aliveFramesCount)
        
        // Calculate dead navigation frames
        let aliveNavChildCount = parentNavIndex.navichildIndex
            .flatMap { $0 + 1 } ?? 0
        let deadNavChildCount = parentNavigationData.children.count - aliveNavChildCount
        let deadNavChildren = parentNavigationData.children.suffix(deadNavChildCount)
        let aliveNavChildren = parentNavigationData.children.prefix(aliveNavChildCount)
        
        // Then assemble a new navChild array and everything else
        let newNavChildren = aliveNavChildren + [newNavichildFrame]
        let newNavData = parentNavigationData.replacingChildren(Array(newNavChildren))
        let newFrame = parentFrame.replacingNavigationData(newNavData)
        let newFrames = aliveFrames.replacingLast(with: newFrame)
        
        // Then, write the changes to the state
        oldFrames.dismountFromHost()
        deadNavChildren.dismountFromHost()
        self.frames = Array(newFrames)
            
        // Perform navigation
        let newNavControllers = newNavData.rootController.value.insecAssumeNotNil().wrapToArrayOrEmpty()
        + newNavChildren.compactMap { navichild in
            navichild.controller.value.insecAssumeNotNil()
        }
        
        if let modalController = newFrame.controller.value.insecAssumeNotNil() {
            if modalController.presentedViewController != nil {
                parentNavigationData.navigationController.value.insecAssumeNotNil()?
                    .setViewControllers(newNavControllers, animated: false)
                modalController.dismiss(animated: animated)
            } else {
                parentNavigationData.navigationController.value.insecAssumeNotNil()?
                    .setViewControllers(newNavControllers, animated: false)
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
                naviChildIndex: nil
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
                       scheduledStart: InsecurityHostState.Stage.Batching.ScheduledStart?,
                       animated: Bool) {
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
            let navigationChildIndex = indexNavData.naviChildIndex
        {
            let aliveNavChildrenCount = navigationChildIndex
            let deadNavChildrenCount = navigationData.children.count - aliveNavChildrenCount
            navigationData.children.suffix(deadNavChildrenCount).dismountFromHost()
            
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
            deadFrames.dismountFromHost()
            
            postPurgeFrames = Array(prepurgeFrames.prefix(firstDeadChildIndex))
        }
        
        self.frames = postPurgeFrames
        
        if
            let deadNavIndex = deepestDeadIndex.navigationData?.naviChildIndex,
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
                    navigationController.popToViewController(popToController, animated: false)
                    if let presentingViewController = frameThatNeedsModalDismissal.previousController.value.insecAssumeNotNil() {
                        presentingViewController.dismiss(animated: animated) {
                            scheduledStart?.routine()
                        }
                    }
                } else {
                    navigationController.popToViewController(popToController, animated: animated)
                    scheduledStart?.routineAfterDelay()
                }
            }
        } else {
            if modalIndexThatNeedsDismissing == deepestDeadIndex.modalIndex {
                firstDeadChild.previousController.value.insecAssertNotNil()?
                    .dismiss(animated: animated) {
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
                    scheduledStart: batch.scheduledStart,
                    animated: true
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
                    
                    switch (newlyNavigationData.naviChildIndex, deepestNavigationData.naviChildIndex) {
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
                    if navigationData.naviChildIndex != nil {
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
    
    // MARK: - NEW Dismiss API
    
    func nextNavigationIndex(after index: CoordinatorIndex) -> CoordinatorIndex? {
        let frame = self.frames[index.modalIndex]
        if let navigationIndex = index.asNavigationIndex() {
            // Current frame navigation
            let nextNavichildIndex = navigationIndex.nextNavichildIndex
            
            guard let navigationData = frame.navigationData.insecAssertNotNil() else {
                return nil
            }
            
            let naviChildExists = navigationData.children.at(nextNavichildIndex.navichildIndexUnwrapped) != nil
            
            if naviChildExists {
                // There is a navichild after current index
                
                return nextNavichildIndex.asUntypedIndex
            } else {
                // There is no navichild after current index, so we fallback to the next
                
            }
        } else {
            // Current frame modal
            let nextModalIndex = index.modalIndex + 1
            if let nextFrame = self.frames.at(nextModalIndex) {
                // Next frame exists
                let nextFrameNavData: CoordinatorIndex.NavigationData?
                if nextFrame.navigationData != nil {
                    // Next frame is navigation frame
                    nextFrameNavData = CoordinatorIndex.NavigationData(
                        naviChildIndex: nil
                    )
                } else {
                    // Next frame is modal frame
                    nextFrameNavData = nil
                }
                return CoordinatorIndex(
                    modalIndex: nextModalIndex,
                    navigationData: nextFrameNavData
                )
            } else {
                // Next frame doesnt exist
                return nil
            }
        }
    }
    
    func dismissChildrenV2(animated: Bool, after index: CoordinatorIndex) {
        let firstDeadIndex: CoordinatorIndex
        if let navigationIndex = index.asNavigationIndex() {
            
        } else {
            
        }
        
        dismiss(animated, at: firstDeadIndex)
    }
    
    func dismiss(_ animated: Bool, at index: CoordinatorIndex) {
        
    }
    
    func dismissChildren(animated: Bool, after index: CoordinatorIndex) {
        switch state.stage {
        case .batching, .purging:
            insecAssertFail(.dismiss(.cantDismissDuringBatchingOrPurging))
        case .dead:
            insecAssertFail(.dismiss(.cantDismissWhileDead))
        case .ready:
            let firstDeadIndex: CoordinatorIndex?
            let modalIndexThatNeedsDismissing: Int?
            
            if let indexNavigationData = index.navigationData {
                let firstDeadNavChildIndex: Int
                if let lastAliveNavIndex = indexNavigationData.naviChildIndex {
                    firstDeadNavChildIndex = lastAliveNavIndex + 1
                } else {
                    firstDeadNavChildIndex = 0
                }
                
                if
                    let lastAliveModalFrame = self.frames.at(index.modalIndex).insecAssumeNotNil(),
                    let lastAliveNavData = lastAliveModalFrame.navigationData.insecAssertNotNil()
                {
                    if lastAliveNavData.children.at(firstDeadNavChildIndex) != nil {
                        firstDeadIndex = CoordinatorIndex(
                            modalIndex: index.modalIndex,
                            navigationData: CoordinatorIndex.NavigationData(
                                naviChildIndex: firstDeadNavChildIndex
                            )
                        )
                        
                        let firstDeadModalIndex = index.modalIndex + 1
                        if self.frames.at(firstDeadModalIndex) != nil {
                            modalIndexThatNeedsDismissing = firstDeadModalIndex
                        } else {
                            modalIndexThatNeedsDismissing = nil
                        }
                    } else {
                        // There is no nav child to be dismissed, so it's a no-op
                        firstDeadIndex = nil
                        modalIndexThatNeedsDismissing = nil
                    }
                } else {
                    // error
                    firstDeadIndex = nil
                    modalIndexThatNeedsDismissing = nil
                }
            } else {
                let firstDeadModalIndex = index.modalIndex + 1
                let navigationData: CoordinatorIndex.NavigationData?
                
                if let firstDeadFrame = self.frames.at(firstDeadModalIndex) {
                    if let firstDeadFrameNavData = firstDeadFrame.navigationData {
                        navigationData = CoordinatorIndex.NavigationData(naviChildIndex: nil)
                    } else {
                        navigationData = nil
                    }
                    firstDeadIndex = CoordinatorIndex(modalIndex: firstDeadModalIndex,
                                                      navigationData: navigationData)
                    modalIndexThatNeedsDismissing = firstDeadModalIndex
                } else {
                    // There is no modal frame to kill, so NO-OP
                    
                    firstDeadIndex = nil
                    modalIndexThatNeedsDismissing = nil
                }
            }
            
            if let firstDeadIndex = firstDeadIndex {
                self.state.stage = .purging
                self.purge(deepestDeadIndex: firstDeadIndex,
                           modalIndexThatNeedsDismissing: modalIndexThatNeedsDismissing,
                           scheduledStart: nil,
                           animated: animated)
                self.state.stage = .ready
            }
            
        }
    }
}
