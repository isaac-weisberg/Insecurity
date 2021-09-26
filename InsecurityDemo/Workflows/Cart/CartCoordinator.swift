import Insecurity

enum CartCoordinatorResult {
    case purchased
    case canceledPurchase
}

class CartCoordinator: NavichildCoordinator<CartCoordinatorResult> {
    init() {
        super.init { navitroller, finish in
            let cartViewController = CartViewController()
            cartViewController.onPayRequested = {
                let paymentCoordinator = PaymentCoordinator()
                let modaroller = navitroller.asModarollerCoordinator()
                
                modaroller.startChild(paymentCoordinator, animated: true) { result in
                    print("End Payment \(result)")
                    switch result {
                    case .normal(let paymentResult):
                        switch paymentResult {
                        case .success:
                            finish(.purchased)
                        }
                    case .dismissed:
                        finish(.canceledPurchase)
                    }
                }
            }
            return cartViewController
        }
    }
}
