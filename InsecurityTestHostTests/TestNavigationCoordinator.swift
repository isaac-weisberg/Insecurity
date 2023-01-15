import UIKit
@testable import Insecurity

class TestNavigationCoordinator<Result>: NavigationCoordinator<Result> {
    override var viewController: UIViewController {
        return TestController<Result>()
    }
}

class TestController<Result>: UIViewController {
    override func viewDidLoad() {
        view.backgroundColor = UIColor(white: Double.random(in: 0.4...0.8), alpha: 1)
    }
}
