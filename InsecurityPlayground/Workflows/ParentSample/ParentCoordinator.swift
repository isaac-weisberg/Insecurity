import Insecurity
import UIKit

class ParentCoordinator: ModalCoordinator<Never> {
    override var viewController: UIViewController {
        let parentViewController = ParentViewController()
        
        parentViewController.onCurrencySelectionRequested = {
            let currencySelectionCoordinator = CurrencySelectionCoordinator()
            
            self.navigation.start(currencySelectionCoordinator,
                                  animated: true) { result in
                
                switch result {
                case .some(let currencySelection):
                    // Good old currencySelection result
                    break
                case nil:
                    break
                }
            }
        }
        
        return parentViewController
    }
}
