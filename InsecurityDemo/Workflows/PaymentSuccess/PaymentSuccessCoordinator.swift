import Insecurity
import UIKit

class PaymentSuccessCoordinator: ModachildCoordinator<Void> {
    override var viewController: UIViewController {
        let viewController = PaymentSuccessViewController()
        
        viewController.onConfirm = {
            self.finish(())
        }
        
        return viewController
    }
}
