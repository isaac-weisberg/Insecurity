import Insecurity
import UIKit

class AddPaymentMethodCoordinator: ModalCoordinator<PaymentMethod> {
    override var viewController: UIViewController {
        let addPaymentMethodViewController = AddPaymentMethodViewController()

        let navigationController = UINavigationController(rootViewController: addPaymentMethodViewController)
        
        addPaymentMethodViewController.onPaymentMethodAdded = { paymentMethod in
            self.finish(paymentMethod)
        }
        
        return navigationController
    }
}
