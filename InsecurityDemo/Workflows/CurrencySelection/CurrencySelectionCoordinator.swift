import Insecurity
import UIKit

class CurrencySelectionCoordinator: ModachildCoordinator<CurrencySelection> {
    override var viewController: UIViewController {
        let viewController = CurrencySelectionViewController()
        
        viewController.onCurrencySelected = { selection in
            self.finish(selection)
        }
        
        return viewController
    }
}
