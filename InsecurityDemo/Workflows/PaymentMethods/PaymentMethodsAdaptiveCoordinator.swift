import Insecurity
import UIKit

struct PaymentMethodsAdaptiveScreenResult {
    let paymentMethodChanged: Bool
}

class PaymentMethodsAdaptiveCoordinator: AdaptiveCoordinator<PaymentMethodsScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodsViewController()
        
        viewController.onDone = { result in
            self.finish(result)
        }
        
        viewController.onNewPaymentMethodRequested = {
            let addPaymentMethodCoordinator = AddPaymentMethodAdaptiveCoordinator()
            
            self.navigation.start(addPaymentMethodCoordinator, in: .current, animated: true) { [weak viewController] paymentMethod in
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
