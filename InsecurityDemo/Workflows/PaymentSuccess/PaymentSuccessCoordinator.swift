import Insecurity
import UIKit

class PaymentSuccessCoordinator: ModalCoordinator<Void> {
    override var viewController: UIViewController {
        let viewController = PaymentSuccessViewController()
        
        viewController.onConfirm = {
            self.finish(())
        }
        
        return viewController
    }
}
