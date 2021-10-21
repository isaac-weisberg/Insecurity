import Insecurity

class MainCoordinator: ModalCoordinator<Never> {
    override var viewController: UIViewController {
        let viewController = MainViewController()
        
        return viewController
    }
}
