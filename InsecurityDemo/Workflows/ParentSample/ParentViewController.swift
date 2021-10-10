import Insecurity
import UIKit

class ParentViewController: UIViewController {
    // Propagate event to the parent
    var onCurrencySelectionRequested: (() -> Void)?
    
    // Or, if you want to start a coordinator from outside:
    var customModalCoordinator: ModalCoordinatorAny?

    func startCurrencySelection() {
        let modalCoordinator = ModalCoordinator(self)
            
        let currencySelectionCoordinator = CurrencySelectionCoordinator()

        self.customModalCoordinator = modalCoordinator // Save the modalCoordinator
        
        modalCoordinator.start(currencySelectionCoordinator, animated: true) { [weak self] result in
            // Release the modalCoordinator, don't forget to `weak self`
            self?.customModalCoordinator = nil
            switch result {
            case .normal(let currencySelection):
                break
            case .dismissed:
                break
            }
        }
    }
}
