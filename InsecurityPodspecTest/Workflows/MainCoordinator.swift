import Insecurity

class MainCoordinator: InsecurityChild<Never> {
    override var viewController: UIViewController {
        let viewController = MainViewController()
        
        return viewController
    }
}
