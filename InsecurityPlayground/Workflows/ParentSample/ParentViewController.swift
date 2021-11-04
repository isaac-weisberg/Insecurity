import Insecurity
import UIKit

class ParentViewController: UIViewController {
    // Propagate event to the parent
    var onCurrencySelectionRequested: (() -> Void)?
    
    // Or, if you want to start a coordinator from outside:
    var customInsecurityHost: InsecurityHost?

    func startCurrencySelection() {
        let insecurityHost = InsecurityHost(modal: self)
            
        let currencySelectionCoordinator = CurrencySelectionCoordinator()

        self.customInsecurityHost = insecurityHost // Save the modalHost
        
        insecurityHost.start(currencySelectionCoordinator, animated: true) { [weak self] result in
            // Release the insecurityHost, don't forget to `weak self`
            self?.customInsecurityHost = nil
            switch result {
            case .some(let currencySelection):
                break
            case nil:
                break
            }
        }
    }
}
