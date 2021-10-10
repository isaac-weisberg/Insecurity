import Insecurity
import UIKit

class AddPaymentMethodCoordinator: InsecurityChild<PaymentMethod> {
    override var viewController: UIViewController {
        let addPaymentMethodViewController = AddPaymentMethodViewController()
        
        addPaymentMethodViewController.onPaymentMethodAdded = { paymentMethod in
            self.finish(paymentMethod)
        }
        
        return addPaymentMethodViewController
    }
}
