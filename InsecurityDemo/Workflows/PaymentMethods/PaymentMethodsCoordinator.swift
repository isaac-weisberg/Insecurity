import Insecurity
import UIKit

struct PaymentMethodsScreenResult {
    let paymentMethodChanged: Bool
}

class PaymentMethodsCoordinator: ModalCoordinator<PaymentMethodsScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodsViewController()
        
        viewController.onDone = { result in
            self.finish(result)
        }
        
        viewController.onNewPaymentMethodRequested = {
            let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
            
            self.start(addPaymentMethodCoordinator, animated: true) { [weak viewController] paymentMethod in
                if let paymentMethod = paymentMethod {
                    // User has added a new payment method
                    viewController?.handleNewPaymentMethodAdded(paymentMethod)
                } else {
                    // User dismissed the screen, nothing to do
                }
            }
        }
        
        return viewController
    }
}
