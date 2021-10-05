import UIKit

class CurrencySelectionViewController: UIViewController {
    var onCurrencySelected: ((CurrencySelection) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        DispatchQueue.main.asyncAfter(0.5) {
            self.onCurrencySelected?(CurrencySelection(currencyCode: "USD"))
        }
    }
}
