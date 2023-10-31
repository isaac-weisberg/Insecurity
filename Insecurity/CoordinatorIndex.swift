enum InsecComparisonResult {
    case less
    case greater
    case equal
}

func compare(_ lhs: Int, _ rhs: Int) -> InsecComparisonResult {
    if lhs < rhs {
        return .less
    } else if lhs > rhs {
        return .greater
    } else {
        return .equal
    }
}

struct CoordinatorIndex: Equatable {
    let modalIndex: Int

    #if DEBUG
    var string: String {
        return "(mod: \(modalIndex)"
    }
    #endif
}
