import Insecurity
import UIKit

enum PaymentCoordinatorResult {
    case success
}

class PaymentCoordinator: AdaptiveCoordinator<PaymentCoordinatorResult> {
    typealias DI = PaymentViewController.DI
    
    override var viewController: UIViewController {
        let paymentViewController = PaymentViewController(di: di)
        paymentViewController.onPaymentSuccess = {
            let successCoordinator = PaymentSuccessCoordinator()
            
            self.navigation.start(successCoordinator, animated: true) { result in
                print("End PaymentSuccess \(result)")
                self.finish(.success)
            }
        }
        return paymentViewController
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}

