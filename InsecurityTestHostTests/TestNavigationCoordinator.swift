import UIKit
@testable import Insecurity

class TestNavigationCoordinator<Result>: NavigationCoordinator<Result> {
    override var viewController: UIViewController {
        let controller = TestController<Result>()
        
        controller.view.backgroundColor = UIColor(white: Double.random(in: 0.4...0.8), alpha: 1)
        
        return controller
    }
}

class TestController<Result>: UIViewController {
    
}
