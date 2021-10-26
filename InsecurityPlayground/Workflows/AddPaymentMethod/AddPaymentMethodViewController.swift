import UIKit

class AddPaymentMethodViewController: UIViewController {
    var onPaymentMethodAdded: ((PaymentMethod) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(0.5) {
            self.onPaymentMethodAdded?(PaymentMethod(cardNumber: "4300123412341234"))
        }
    }
}
