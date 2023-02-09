import Insecurity
import UIKit

class TestModalController: UIViewController {
    
}

class TestModalCoordinator<Result>: ModalCoordinator<Result> {
    override var viewController: UIViewController {
        let controller = TestModalController()
        
        return controller
    }
}
