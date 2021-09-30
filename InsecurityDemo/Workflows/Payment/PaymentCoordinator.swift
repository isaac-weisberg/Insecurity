import Insecurity

enum PaymentCoordinatorResult {
    case success
}

class PaymentCoordinator: ModachildCoordinator<PaymentCoordinatorResult> {
    typealias DI = PaymentViewController.DI
    
    init(di: DI) {
        super.init { modaroller, finish in
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
    }
}

