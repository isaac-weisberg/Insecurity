enum InsecurityMessage {
    static let emptyString = ""
    
    case noStartOverDead
    case noDismissMidOfFin
    case noMountAMounted
    case noMountAUsedOne
    case noFinishOnDead
    case impossible
    case noLlerInLlersNavi
    
    var s: String {
        #if DEBUG
        switch self {
        case .noStartOverDead:
            return "Can not start on an unmounted or dead coordinator"
        case .noDismissMidOfFin:
            return "Can not dismiss in the middle of a finish chain"
        case .noMountAMounted:
            return "Can not mount a coordinator that's already mounted"
        case .noMountAUsedOne:
            return "Can not mount a coordinator that's already been used"
        case .noFinishOnDead:
            return "Can't finish coordinator that's dead"
        case .impossible:
            return "Impossible"
        case .noLlerInLlersNavi:
            return "The controller of this navigation coordinator is somehow not in the view controllers array of UINavigationController, which is like ---what?"
        }
        #else
        return InsecurityMessage.emptyString
        #endif
    }
}
