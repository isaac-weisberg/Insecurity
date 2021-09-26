import Insecurity
import UIKit

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
                    print("End Payment Regular \(result)")
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
            
            cartViewController.onPayButLoginFirstRequested = {
                let loginPhoneCoordinator = LoginPhoneCoordinator()
                
                let modaroller = navitroller.asModarollerCoordinator()
                
                modaroller.startNavitrollerChild(UINavigationController(), loginPhoneCoordinator) { result in
                    print("End Login \(result)")
                    switch result {
                    case .normal(let loginResult):
                        switch loginResult {
                        case .loggedIn:
                            let paymentCoordinator = PaymentCoordinator()
                            
                            modaroller.startChild(paymentCoordinator, animated: true) { result in
                                print("End Payment After Login \(result)")
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
                    case .dismissed:
                        break
                    }
                }
            }
            
            return cartViewController
        }
    }
}
