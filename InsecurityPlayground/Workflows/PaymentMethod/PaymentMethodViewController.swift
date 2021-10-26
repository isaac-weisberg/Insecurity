import UIKit

class PaymentMethodViewController: UIViewController {
    var onDone: ((PaymentMethodScreenResult) -> Void)?
    var onNewPaymentMethodRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackgroundCompat
        
        DispatchQueue.main.asyncAfter(0.5) {
            self.onNewPaymentMethodRequested?()
        }
    }
    
    func handleNewPaymentMethodAdded(_ paymentMethod: PaymentMethod) {
        DispatchQueue.main.asyncAfter(0.5) {
            self.onDone?(PaymentMethodScreenResult(paymentMethodChanged: false))
        }
    }
}
