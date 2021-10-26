import Insecurity
import UIKit

struct PaymentMethodScreenResult {
    let paymentMethodChanged: Bool
}

class PaymentMethodCoordinator: AdaptiveCoordinator<PaymentMethodScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodViewController()
        
        viewController.onDone = { result in
            self.finish(result)
        }
        
        viewController.onNewPaymentMethodRequested = {
            let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
            
            self.navigation.start(addPaymentMethodCoordinator, animated: true) { [weak viewController] paymentMethod in
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
