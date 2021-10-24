import Insecurity
import UIKit

class ParentViewController: UIViewController {
    // Propagate event to the parent
    var onCurrencySelectionRequested: (() -> Void)?
    
    // Or, if you want to start a coordinator from outside:
    var customModalHost: ModalHost?

    func startCurrencySelection() {
        let modalHost = ModalHost(self)
            
        let currencySelectionCoordinator = CurrencySelectionCoordinator()

        self.customModalHost = modalHost // Save the modalHost
        
        modalHost.start(currencySelectionCoordinator, animated: true) { [weak self] result in
            // Release the modalHost, don't forget to `weak self`
            self?.customModalHost = nil
            switch result {
            case .some(let currencySelection):
                break
            case nil:
                break
            }
        }
    }
}
