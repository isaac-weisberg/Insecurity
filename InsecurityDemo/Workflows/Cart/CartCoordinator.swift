import Insecurity
import UIKit

enum CartCoordinatorResult {
    case purchased
}

class CartCoordinator: NavichildCoordinator<CartCoordinatorResult> {
    typealias DI = PaymentCoordinator.DI
        & LoginPhoneCoordinator.DI
        & ScoringCoordinator.DI
    
    init(di: DI) {
        super.init { navitroller, finish in
            let cartViewController = CartViewController()
            
            cartViewController.onPayRequested = {
                let paymentCoordinator = PaymentCoordinator(di: di)
                
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
                let loginPhoneCoordinator = LoginPhoneCoordinator(di: di)
                
                navitroller.startModalNavitrollerChild(UINavigationController(), loginPhoneCoordinator, animated: true) { result in
                    print("End Login after payWithLogin requested \(result)")
                    switch result {
                    case .normal(let loginResult):
                        switch loginResult {
                        case .loggedIn:
                            let paymentCoordinator = PaymentCoordinator(di: di)
                            
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
            
            cartViewController.onPayButScoringFirstRequested = {
                let scoringCoordinator = ScoringCoordinator(di: di)
                
                navitroller.startModachild(scoringCoordinator, animated: true) { result in
                    print("End Login after payWithScoring requested \(result)")
                    switch result {
                    case .normal:
                        let paymentCoordinator = PaymentCoordinator(di: di)
                        
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
                    case .dismissed:
                        break
                    }
                }
            }
            
            return cartViewController
        }
    }
}
