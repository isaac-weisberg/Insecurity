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
        let index = CoordinatorIndex(modalIndex: parentIndex.modalIndex + 1)
        if let parentFrame = frames.at(parentIndex.modalIndex) {
            if let existingFrame = frames.at(index.modalIndex) {
                let aliveFramesCount = parentIndex.modalIndex + 1
                let aliveFrames = self.frames.prefix(aliveFramesCount)
                
                if let parentController = existingFrame.controller.value.insecAssertNotNil() {
                    let deadFrames = self.frames.suffix(self.frames.count - aliveFramesCount)
                    deadFrames.dismountFromHost()
                    
                    let controller = child.mountOnHostModal(self, index, completion: completion)
                    
                    let frame = Frame(
                        coordinator: child,
                        controller: controller
                    )
                    
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
                    
                    let frame = Frame(
                        coordinator: child,
                        controller: controller
                    )
                    
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
    
    // MARK: - Purge
    
    private func purge(_ firstDeadIndex: CoordinatorIndex,
                       scheduledStart: InsecurityHostState.Stage.Batching.ScheduledStart?,
                       animated: Bool) {
        if let scheduledStart = scheduledStart {
            scheduledStart.routine()
        } else {
            dismissImmediately(animated, firstDeadIndex: firstDeadIndex)
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
                self.purge(batch.deepestDeadIndex,
                           scheduledStart: batch.scheduledStart,
                           animated: true)
                self.state.stage = .ready
            case .ready, .purging:
                insecAssertFail(.unexpectedState)
            case .dead:
                break
            }
        case .batching(let batching):
            let newDeepestDeadIndex: CoordinatorIndex
            let modalIndexThatNeedsDismissing: Int?
            
            let modalComparison = compare(index.modalIndex, batching.deepestDeadIndex.modalIndex)
            
            switch modalComparison {
            case .equal:
                // This is the same modal frame that died twice
                insecFatalError(.coordinatorDiedTwice)
            case .less:
                // Modal index is less than current deepest - definitely deeper!
                newDeepestDeadIndex = index

                // This is a pure modal frame

                // Modal dismissal is determined by deathReason
                switch deathReason {
                case .result:
                    modalIndexThatNeedsDismissing = index.modalIndex
                case .deinitOrKvo:
                    modalIndexThatNeedsDismissing = nil
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

    public func mountForManualManagement<
        Result
    >(
        _ coordinator: ModalCoordinator<Result>,
        _ completion: @escaping (Result?) -> Void
    ) -> UIViewController {
        guard frames.isEmpty else {
            insecFatalError(.hostIsAlreadyMounted)
        }

        let index = CoordinatorIndex(modalIndex: 0)
        let controller = coordinator.mountOnHostModal(self, index, completion: completion)
        let frame = Frame(coordinator: coordinator,
                          controller: controller)
        self.frames = [frame]

        return controller
    }
    
    public func mountOnExistingController<Result>(
        _ coordinator: ModalCoordinator<Result>,
        on parentController: UIViewController,
        animated: Bool,
        _ completion: @escaping (Result?) -> Void
    ) {
        guard frames.isEmpty else {
            insecFatalError(.hostIsAlreadyMounted)
        }
            
        let index = CoordinatorIndex(modalIndex: 0)
        let controller = coordinator.mountOnHostModal(self, index, completion: completion)
        let frame = Frame(coordinator: coordinator,
                          controller: controller)
        self.frames = [frame]
        
        parentController.present(controller, animated: animated)
    }

    // MARK: - NEW Dismiss API
    
    func nextIndex(after index: CoordinatorIndex) -> CoordinatorIndex? {
        return nextIndexAfterModal(index)
    }
    
    func nextIndexAfterModal(_ index: CoordinatorIndex) -> CoordinatorIndex? {
        let nextModalIndex = index.modalIndex + 1
        if nextModalIndex < frames.count {
            // Next frame exists
            return CoordinatorIndex(modalIndex: nextModalIndex)
        } else {
            // Next frame doesnt exist
            return nil
        }
    }
    
    func dismissChildren(animated: Bool, after index: CoordinatorIndex) {
        switch state.stage {
        case .ready:
            if let firstDeadIndex = nextIndex(after: index) {
                dismissImmediately(animated, firstDeadIndex: firstDeadIndex)
            }
        case .batching, .dead, .purging:
            insecAssertFail(.dismiss(.cantDismissDuringBatchingOrPurging))
        }
    }
    
    func dismissImmediately(_ animated: Bool,
                            firstDeadIndex: CoordinatorIndex) {
        let prePurgeFrames = self.frames
        
        let aliveFramesCount = firstDeadIndex.modalIndex
        let deadFramesCount = prePurgeFrames.count - aliveFramesCount
        let deadFrames = prePurgeFrames.suffix(deadFramesCount)
        let aliveFrames = prePurgeFrames.prefix(aliveFramesCount)
        
        deadFrames.dismountFromHost()
        
        let resultingFrames = aliveFrames
        
        let postPurgeFrames = Array(resultingFrames)
        
        self.frames = postPurgeFrames

        if let deadFrame = deadFrames.first.insecAssumeNotNil() {
            deadFrame.controller.value?.presentingViewController?.dismiss(animated: animated)
        }
    }

}
