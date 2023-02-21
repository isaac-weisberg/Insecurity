@frozen enum InsecurityLog {
    // Don't call finish on coordinator that wasn't mounted or that died
    case noFinishOnUnmounted
    case noFinishOnDead
    
    // Some coordinator died while purging was in progress
    case noDyingWhilePurging
    case noStartingWhilePurging
    
    // Navigation host was marked dead while it was performing a navigation chain
    case hostDiedMidBatch
    
    // Coordinator died, but the host doesn't accept death notifications no more
    case hostDiedBeforeCoordinator
    
    // Was about to start, but turns out, host is dead
    case hostDiedBeforeStart
    
    // Frame not found at indexpath
    case noFrameAtIndexPath
    
    // Parent view controller was deallocated
    case parentControllerHasBeenLost
    
    case unexpectedState
    
    // Index was a navigation index, but the frame at this modalIndex has no navigation data
    case indexAssuredNavigationButFrameWasModal
    case twoIndicesHaveSameModalIndexButNavDataDiffers
    
    // Coordinator was already expected to be the deepest dead coordinator yet it died once again
    case coordinatorDiedTwice
    
    case noStartOnDeadOrUnmounted
    case noDismissChildrenOnDeadOrUnmounted
    
    case expectedThisToNotBeNil
    
    case cantStartNavigationOverModalContext
    
    // Can not mount a host twice
    case hostIsAlreadyMounted
    
    // Start was called while there was a chain of finishes;
    // The start was scheduled to happen after all dismisses
    // However, the coordinator that was supposed to precede the new coordinator
    // was suddenly found dead
    //
    // Alternatively, the finish chain didn't actually reach the presumed parent.
    // There is still a coordinator on top of presumed parent
    case presumedParentForBatchedStartWasEitherDeadOrNotAtTheTopOfTheStack
    
    case wantedToBatchedStartButHostIsNotMountedAnymore
    
    enum Dismiss {
        case cantDismissWhileDead
        case cantDismissDuringBatchingOrPurging
    }
    
    case dismiss(Dismiss)
}

@frozen public enum InsecurityAssumption {
    case assumedThisThingWouldntBeNil
}
