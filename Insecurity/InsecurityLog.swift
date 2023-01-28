enum InsecurityLog {
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
    
    case expectedThisToNotBeNil
    
    case cantStartNavigationOverModalContext
}
