import UIKit

protocol CommonNavigationCoordinator: AnyObject {
    var isInLiveState: Bool { get }
    
    func parentWillDismiss()
    
    func findFirstAliveAncestorAndPerformDismissal()
}

struct WeakCommonNavigationCoordinator {
    weak var value: CommonNavigationCoordinator?
    
    init(_ value: CommonNavigationCoordinator) {
        self.value = value
    }
}

extension CommonNavigationCoordinator {
    var weak: WeakCommonNavigationCoordinator {
        WeakCommonNavigationCoordinator(self)
    }
}
