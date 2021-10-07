import Insecurity
import UIKit

class ParentViewController: UIViewController {
    // Propagate event to the parent
    var onCurrencySelectionRequested: (() -> Void)?
    
    // Or, if you want to start a coordinator from outside:
    var customModaroller: ModarollerCoordinatorAny?

    func startCurrencySelection() {
        let modaroller = ModarollerCoordinator(self)
            
        let currencySelectionCoordinator = CurrencySelectionCoordinator()

        self.customModaroller = modaroller // Save the modaroller
        
        modaroller.start(currencySelectionCoordinator, animated: true) { [weak self] result in
            // Release the modaroller, don't forget to `weak self`
            self?.customModaroller = nil
            switch result {
            case .normal(let currencySelection):
                break
            case .dismissed:
                break
            }
        }
    }
}
