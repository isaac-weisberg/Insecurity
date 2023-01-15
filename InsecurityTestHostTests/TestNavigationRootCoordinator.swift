import UIKit
@testable import Insecurity

class TestNavigationRootCoordinator: NavigationRootCoordinator<Int> {
    override var viewController: UIViewController {
        return TestController<Int>()
    }
    
    override var navigationController: UINavigationController {
        UINavigationController()
    }
}
