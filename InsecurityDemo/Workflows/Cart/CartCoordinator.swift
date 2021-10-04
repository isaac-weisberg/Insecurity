import Insecurity
import UIKit

enum CartCoordinatorResult {
    case purchased
}

class CartCoordinator: NavichildCoordinator<CartCoordinatorResult> {
    typealias DI = PaymentCoordinator.DI
        & LoginPhoneCoordinator.DI
        & ScoringCoordinator.DI
    
    override var viewController: UIViewController {
        let cartViewController = CartViewController()
        
        cartViewController.onPayRequested = { [self] in
            let paymentCoordinator = PaymentCoordinator(di: di)
            
            navitroller.start(paymentCoordinator, animated: true) { result in
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
        
        cartViewController.onPayButLoginFirstRequested = { [self] in
            let loginPhoneCoordinator = LoginPhoneCoordinator(di: di)
            
            navitroller.start(UINavigationController(), loginPhoneCoordinator, animated: true) { result in
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
        
        cartViewController.onPayButScoringFirstRequested = { [self] in
            let scoringCoordinator = ScoringCoordinator(di: di)
            
            navitroller.start(scoringCoordinator, animated: true) { result in
                print("End Login after payWithScoring requested \(result)")
                switch result {
                case .normal:
                    let paymentCoordinator = PaymentCoordinator(di: di)
                    
                    navitroller.start(paymentCoordinator, animated: true) { result in
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
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
