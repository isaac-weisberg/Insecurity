import UIKit

class CartViewController: UIViewController {
    var onPayRequested: (() -> Void)?
    var onPayButLoginFirstRequested: (() -> Void)?
    
    let payButton = UIButton(type: .system)
    let payButLogingFirstButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        
        navigationItem.title = "Cart"
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.setTitle("Pay", for: .normal)
        view.addSubview(payButton)
        payButton.addTarget(self, action: #selector(onBuyButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        payButLogingFirstButton.translatesAutoresizingMaskIntoConstraints = false
        payButLogingFirstButton.setTitle("Pay but loging first", for: .normal)
        view.addSubview(payButLogingFirstButton)
        payButLogingFirstButton.addTarget(self, action: #selector(onPayButLogingFirstButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButLogingFirstButton.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -8),
            payButLogingFirstButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onBuyButtonTap() {
        onPayRequested?()
    }
    
    @objc func onPayButLogingFirstButtonTap() {
        onPayButLoginFirstRequested?()
    }
}
