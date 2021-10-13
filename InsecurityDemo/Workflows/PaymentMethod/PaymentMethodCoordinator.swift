import Insecurity
import UIKit

struct PaymentMethodScreenResult {
    let paymentMethodChanged: Bool
}

class PaymentMethodCoordinator: AdaptiveChild<PaymentMethodScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodViewController()
        
        viewController.onDone = { result in
            self.finish(result)
        }
        
        viewController.onNewPaymentMethodRequested = {
            let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
            
            self.navigation.start(addPaymentMethodCoordinator, animated: true) { [weak viewController] result in
                switch result {
                case .normal(let paymentMethod):
                    // User has added a new payment method
                    viewController?.handleNewPaymentMethodAdded(paymentMethod)
                case .dismissed:
                    // User dismissed the screen, nothing to do
                    break
                }
            }
        }
        
        return viewController
    }
}
