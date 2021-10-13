import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonModalChildAny: AnyObject {
    
}

protocol CommonModalChild: CommonModalChildAny {
    associatedtype Result
    
    var viewController: UIViewController { get }
    
    var _finishImplementation: ((Result) -> Void)? { get set }
    
    func _updateHostReference(_ host: ModalCoordinator)
}
