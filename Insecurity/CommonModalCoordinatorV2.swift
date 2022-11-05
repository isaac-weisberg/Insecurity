import UIKit

protocol CommonModalCoordinatorV2: AnyObject {
    var isInDeadState: Bool { get }
    
    var instantiatedViewController: UIViewController? { get }
}

struct WeakCommonModalCoordinatorV2 {
    weak var value: CommonModalCoordinatorV2?
    
    init(_ value: CommonModalCoordinatorV2) {
        self.value = value
    }
}
