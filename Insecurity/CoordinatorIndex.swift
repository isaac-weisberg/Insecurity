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

struct NavigationIndex {
    let modalIndex: Int
    let navigationData: CoordinatorIndex.NavigationData
    
    var asUntypedIndex: CoordinatorIndex {
        return CoordinatorIndex(
            modalIndex: modalIndex,
            navigationData: CoordinatorIndex.NavigationData(
                navigationIndex: navigationData.navigationIndex
            )
        )
    }
    
    var nextNavigationIndex: NavigationIndex {
        let newNavigationIndex: Int
        if let naviChildIndex = navigationData.navigationIndex {
            newNavigationIndex = naviChildIndex + 1
        } else {
            newNavigationIndex = 0
        }
        let index = NavigationIndex(
            modalIndex: modalIndex,
            navigationData: CoordinatorIndex.NavigationData(
                navigationIndex: newNavigationIndex
            )
        )
        return index
    }
}

struct CoordinatorIndex: Equatable {
    struct NavigationData: Equatable {
        let navigationIndex: Int?
    }
    
    let modalIndex: Int
    let navigationData: NavigationData?
    
    #if DEBUG
    var string: String {
        let navIndexString = navigationData?.navigationIndex.flatMap { "\($0)" } ?? "nil"
        return "(mod: \(modalIndex) nav: \(navIndexString))"
    }
    #endif
    
    func asNavigationIndex(_ file: StaticString = #file, _ line: UInt = #line) -> NavigationIndex? {
        guard let navigationData = self.navigationData else {
            insecAssertFail(.indexAssuredNavigationButFrameWasModal, file, line)
            return nil
        }
        return NavigationIndex(modalIndex: modalIndex, navigationData: navigationData)
    }
}

extension Optional where Wrapped == CoordinatorIndex.NavigationData {
    func presenceAssuredByIndex(_ file: StaticString = #file, _ line: UInt = #line) -> CoordinatorIndex.NavigationData? {
        if let navigationData = self {
            return navigationData
        }
        insecAssertFail(.indexAssuredNavigationButFrameWasModal, file, line)
        return nil
    }
}
