enum InsecComparisonResult {
    case less
    case greater
    case equal
}

func compare(
    _ lhs: CoordinatorIndex.NavigationData,
    _ rhs: CoordinatorIndex.NavigationData
) -> InsecComparisonResult {
    switch (lhs.naviChildIndex, rhs.naviChildIndex) {
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

struct NavichildIndex {
    let modalIndex: Int
    let navichildIndex: Int
    
    func asUntypedIndex() -> CoordinatorIndex {
        return CoordinatorIndex.navigation(NavigationIndex(modalIndex: modalIndex, navichildIndex: navichildIndex))
    }
}

struct NavigationIndex: Equatable {
    let modalIndex: Int
    let navichildIndex: Int?
    
    func asUntypedIndex() -> CoordinatorIndex {
        return CoordinatorIndex.navigation(self)
    }
    
    func nextNavichildIndex() -> NavichildIndex {
        let newNavichildIndex: Int
        if let naviChildIndex = self.navichildIndex {
            newNavichildIndex = naviChildIndex + 1
        } else {
            newNavichildIndex = 0
        }
        let index = NavichildIndex(modalIndex: modalIndex,
                                   navichildIndex: newNavichildIndex)
        return index
    }
}

struct ModalIndex: Equatable {
    let modalIndex: Int
}

enum CoordinatorIndex: Equatable {
    case modal(ModalIndex)
    case navigation(NavigationIndex)
    
    struct NavigationData: Equatable {
        let naviChildIndex: Int?
    }
    
    var modalIndex: Int {
        switch self {
        case .modal(let modal):
            return modal.modalIndex
        case .navigation(let navigation):
            return navigation.modalIndex
        }
    }
    var navigationData: NavigationData? {
        
        switch self {
        case .modal:
            return nil
        case .navigation(let navIndex):
            return NavigationData(naviChildIndex: navIndex.navichildIndex)
        }
    }
    
    #if DEBUG
    var string: String {
        let navIndexString = navigationData?.naviChildIndex.flatMap { "\($0)" } ?? "nil"
        return "(mod: \(modalIndex) nav: \(navIndexString))"
    }
    #endif
    
    func assertNavigationIndex(_ file: StaticString = #file, _ line: UInt = #line) -> NavigationIndex? {
        guard let navigationIndex = self.asNavigationIndex() else {
            insecAssertFail(.indexAssuredNavigationButFrameWasModal, file, line)
            return nil
        }
        return navigationIndex
    }
    
    func asNavigationIndex() -> NavigationIndex? {
        guard let navigationData = self.navigationData else {
            return nil
        }
        return NavigationIndex(modalIndex: modalIndex, navichildIndex: navigationData.naviChildIndex)
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
