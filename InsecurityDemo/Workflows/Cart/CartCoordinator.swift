import Insecurity
import UIKit

enum CartCoordinatorResult {
    case purchased
}

class CartCoordinator: NavichildCoordinator<CartCoordinatorResult> {
    init() {
        super.init { navitroller, finish in
            let cartViewController = CartViewController()
            
            cartViewController.onPayRequested = {
                let paymentCoordinator = PaymentCoordinator()
                
                navitroller.startModachild(paymentCoordinator, animated: true) { result in
                    print("End Payment Regular \(result)")
                    switch result {
                    case .normal(let paymentResult):
                        switch paymentResult {
                        case .success:
                            finish(.purchased)
                        }
                    case .dismissed:
                        break
                    }
                }
            }
            
            cartViewController.onPayButLoginFirstRequested = {
                let loginPhoneCoordinator = LoginPhoneCoordinator()
                
                navitroller.startModalNavitrollerChild(UINavigationController(), loginPhoneCoordinator, animated: true) { result in
                    print("End Login \(result)")
                    switch result {
                    case .normal(let loginResult):
                        switch loginResult {
                        case .loggedIn:
                            let paymentCoordinator = PaymentCoordinator()
                            
                            navitroller.startModachild(paymentCoordinator, animated: true) { result in
                                print("End Payment After Login \(result)")
                                switch result {
                                case .normal(let paymentResult):
                                    switch paymentResult {
                                    case .success:
                                        finish(.purchased)
                                    }
                                case .dismissed:
                                    break
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
