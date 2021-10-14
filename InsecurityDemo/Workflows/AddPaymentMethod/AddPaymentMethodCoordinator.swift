import Insecurity
import UIKit

class AddPaymentMethodCoordinator: ModalCoordinator<PaymentMethod> {
    override var viewController: UIViewController {
        let addPaymentMethodViewController = AddPaymentMethodViewController()
        
        addPaymentMethodViewController.onPaymentMethodAdded = { paymentMethod in
            self.finish(paymentMethod)
        }
        
        return addPaymentMethodViewController
    }
}
