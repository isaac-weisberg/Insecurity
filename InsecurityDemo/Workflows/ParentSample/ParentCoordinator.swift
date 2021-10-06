import Insecurity
import UIKit

class ParentCoordinator: ModachildCoordinator<Never> {
    override var viewController: UIViewController {
        let parentViewController = ParentViewController()
        
        parentViewController.onCurrencySelectionRequested = {
            let currencySelectionCoordinator = CurrencySelectionCoordinator()
            
            self.modaroller.start(currencySelectionCoordinator,
                                  animated: true) { result in
                
                switch result {
                case .normal(let currencySelection):
                    // Good old currencySelection result
                    break
                case .dismissed:
                    break
                }
            }
        }
        
        return parentViewController
    }
}
