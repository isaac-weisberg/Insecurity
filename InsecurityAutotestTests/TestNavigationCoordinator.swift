import Insecurity
import UIKit

class TestNavigationChildController: UIViewController {
     
}

class TestNavigationController: UINavigationController {
    
}

class TestNavigationCoordinator<Result>: NavigationCoordinator<Result> {
    override var viewController: UIViewController {
        let controller = TestNavigationChildController()
        
        return controller
    }
}
