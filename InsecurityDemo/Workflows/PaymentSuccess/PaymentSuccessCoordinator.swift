import Insecurity

class PaymentSuccessCoordinator: ModachildCoordinator<Void> {
    init() {
        super.init { _, finish in
            let viewController = PaymentSuccessViewController()
            
            viewController.onConfirm = {
                finish(())
            }
            
            return viewController
        }
    }
}
