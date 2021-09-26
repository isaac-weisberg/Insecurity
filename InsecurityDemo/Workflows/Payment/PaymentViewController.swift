import UIKit

class PaymentViewController: UIViewController {
    var onPaymentSuccess: (() -> Void)?
    
    let payButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBrown
        
        navigationItem.title = "Payment"
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.setTitle("Pay", for: .normal)
        view.addSubview(payButton)
        payButton.addTarget(self, action: #selector(onPayButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onPayButtonTap() {
        onPaymentSuccess?()
    }
}
