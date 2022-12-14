enum InsecurityMessage {
    static let emptyString = ""
    
    case noStartOverDead
    case noDismissMidOfFin
    
    var s: String {
        #if DEBUG
        switch self {
        case .noStartOverDead:
            return "Can not start on an unmounted or dead coordinator"
        case .noDismissMidOfFin:
            return "Can not dismiss in the middle of a finish chain"
        }
        #else
        return InsecurityMessage.emptyString
        #endif
    }
}
