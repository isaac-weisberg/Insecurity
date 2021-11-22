import Insecurity
import UIKit

class AddPaymentMethodAdaptiveCoordinator: AdaptiveCoordinator<PaymentMethod> {
    override var viewController: UIViewController {
        let addPaymentMethodViewController = AddPaymentMethodViewController()
        
        addPaymentMethodViewController.onPaymentMethodAdded = { paymentMethod in
            self.finish(paymentMethod)
        }
        
        return addPaymentMethodViewController
    }
}
