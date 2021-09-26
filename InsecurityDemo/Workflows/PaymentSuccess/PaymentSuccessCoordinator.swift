import Insecurity

class PaymentSuccessCoordinator: ModachildCoordinator<Void> {
    init() {
        super.init { _, finish in
            let viewController = PaymentSuccessViewController()
            
            viewController.onConfirm = {
//                let navigationCoordinator = NavitrollerCoordinator(<#T##navigationController: UINavigationController##UINavigationController#>)
                finish(())
            }
            
            return viewController
        }
    }
}
