import UIKit

protocol CommonModalCoordinator: AnyObject {
    var isInDeadState: Bool { get }
    
    func parentWillDismiss()
    
    func childWillUnmount()
    
    var instantiatedViewController: UIViewController? { get }
}

struct WeakCommonModalCoordinatorV2 {
    weak var value: CommonModalCoordinator?
    
    init(_ value: CommonModalCoordinator) {
        self.value = value
    }
}
