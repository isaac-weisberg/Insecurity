import UIKit

class AddPaymentMethodViewController: UIViewController {
    var onPaymentMethodAdded: ((PaymentMethod) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackgroundCompat
        
        DispatchQueue.main.asyncAfter(2) { [weak self] in
            self?.onPaymentMethodAdded?(PaymentMethod(cardNumber: "4300123412341234", name: "GABE ITCHES"))
        }
    }
}
