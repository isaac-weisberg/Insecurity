import Insecurity
import UIKit

class ProductCoordinator: NavigationCoordinator<Void> {
    typealias DI = CartCoordinator.DI
    
    override var viewController: UIViewController {
        let viewController = ProductViewController()
        
        viewController.onCartRequested = { [self] in
            let contentsCoordinator = CartCoordinator(di: di)
            
            navigation.start(contentsCoordinator, animated: true) { result in
                print("End Cart \(result)")
                
                let paymentCoordinator = PaymentCoordinator(di: self.di)
                self.navigation.start(paymentCoordinator, in: .current, animated: true) { result in
                    print("End Payment after cart \(result)")
                }
            }
        }
        
        return viewController
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
