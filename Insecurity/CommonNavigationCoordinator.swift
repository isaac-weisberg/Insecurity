import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonNavigationCoordinatorAny: CommonCoordinatorAny {
    
}

protocol CommonNavigationCoordinator: CommonNavigationCoordinatorAny {
    associatedtype Result
    
    var viewController: UIViewController { get }
    
    var _finishImplementation: ((Result?) -> Void)? { get set }
    
    var _abortChildrenImplementation: (() -> Void)? { get set }
    
    func _updateHostReference(_ host: NavigationControllerNavigation & AdaptiveNavigation)
    
    var kvoContext: InsecurityKVOContext? { get set }
    
    var assignedController: UIViewController? { get set }
}
