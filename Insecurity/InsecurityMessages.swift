enum InsecurityMessage {
    static let emptyString = ""
    
    case noStartOverDead
    
    var s: String {
        #if DEBUG
        switch self {
        case .noStartOverDead:
            return "Can not start on an unmounted or dead coordinator"
        }
        #else
        return InsecurityMessage.emptyString
        #endif
    }
}
