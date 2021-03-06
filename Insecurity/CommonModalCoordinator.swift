import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonModalCoordinatorAny: CommonCoordinatorAny {
    
}

protocol CommonModalCoordinator: CommonModalCoordinatorAny {
    associatedtype Result
    
    var viewController: UIViewController { get }
    
    var _finishImplementation: ((Result?) -> Void)? { get set }
    
    func _updateHostReference(_ host: ModalNavigation & AdaptiveNavigation)
}
