import Insecurity
import UIKit

class TestModalController: UIViewController {
    
}

class TestModalCoordinator<Result>: ModalCoordinator<Result> {
    override init() {

    }

    init(_ t: Result.Type) {

    }

    override var viewController: UIViewController {
        let controller = TestModalController()
        
        return controller
    }
}
