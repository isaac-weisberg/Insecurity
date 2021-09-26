import UIKit

class CartViewController: UIViewController {
    var onPayRequested: (() -> Void)?    
    
    let payButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.setTitle("Pay", for: .normal)
        view.addSubview(payButton)
        payButton.addTarget(self, action: #selector(onBuyButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onBuyButtonTap() {
        onPayRequested?()
    }
}
