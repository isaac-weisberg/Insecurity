import Insecurity

enum PaymentCoordinatorResult {
    case success
}

class PaymentCoordinator: ModachildCoordinator<PaymentCoordinatorResult> {
    init() {
        super.init { modaroller, finish in
            let paymentViewController = PaymentViewController()
            paymentViewController.onPaymentSuccess = {
                let successCoordinator = PaymentSuccessCoordinator()
                
                modaroller.startChild(successCoordinator, animated: true) { result in
                    print("End PaymentSuccess \(result)")
                    finish(.success)
                }
            }
            return paymentViewController
        }
    }
}

