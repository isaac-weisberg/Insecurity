enum InsecComparisonResult {
    case less
    case greater
    case equal
}

func compare(
    _ lhs: CoordinatorIndex.NavigationData,
    _ rhs: CoordinatorIndex.NavigationData
) -> InsecComparisonResult {
    switch (lhs.navigationIndex, rhs.navigationIndex) {
    case (nil, nil):
        return .equal
    case (.some, nil):
        return .greater
    case (nil, .some):
        return .less
    case (.some(let lhsNavIndex), .some(let rhsNavIndex)):
        if lhsNavIndex > rhsNavIndex {
            return .greater
        } else if lhsNavIndex < rhsNavIndex {
            return .less
        } else { // ==
            return .equal
        }
    }
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

struct CoordinatorIndex {
    struct NavigationData {
        let navigationIndex: Int?
    }
    
    let modalIndex: Int
    let navigationData: NavigationData?
}
