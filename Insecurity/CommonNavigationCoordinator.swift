import UIKit

protocol CommonNavigationCoordinator: AnyObject {
    var isInDeadState: Bool { get }
    
    var instantiatedViewController: UIViewController? { get }
}

struct WeakCommonNavigationCoordinator {
    weak var value: CommonNavigationCoordinator?
}
