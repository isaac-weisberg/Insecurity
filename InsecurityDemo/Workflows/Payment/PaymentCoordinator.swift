import Insecurity
import UIKit

enum PaymentCoordinatorResult {
    case success
}

class PaymentCoordinator: ModachildCoordinator<PaymentCoordinatorResult> {
    typealias DI = PaymentViewController.DI
    
    override var viewController: UIViewController {
        let paymentViewController = PaymentViewController(di: di)
        paymentViewController.onPaymentSuccess = {
            let successCoordinator = PaymentSuccessCoordinator()
            
            modaroller.startChild(successCoordinator, animated: true) { result in
                print("End PaymentSuccess \(result)")
                finish(.success)
            }
        }
        return paymentViewController
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}

