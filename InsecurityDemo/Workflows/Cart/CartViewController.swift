import UIKit

class CartViewController: UIViewController {
    var onPayRequested: (() -> Void)?
    var onPayButLoginFirstRequested: (() -> Void)?
    var onPayButScoringFirstRequested: (() -> Void)?
    
    let payButton = UIButton(type: .system)
    let payButLoginFirstButton = UIButton(type: .system)
    let payButScoringFirstButton = UIButton(type: .system)
    
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
        
        payButLoginFirstButton.translatesAutoresizingMaskIntoConstraints = false
        payButLoginFirstButton.setTitle("Pay but loging first", for: .normal)
        view.addSubview(payButLoginFirstButton)
        payButLoginFirstButton.addTarget(self, action: #selector(onPayButLogingFirstButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButLoginFirstButton.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -8),
            payButLoginFirstButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        payButScoringFirstButton.translatesAutoresizingMaskIntoConstraints = false
        payButScoringFirstButton.setTitle("Pay but scoring first", for: .normal)
        view.addSubview(payButScoringFirstButton)
        payButScoringFirstButton.addTarget(self, action: #selector(onPayButScoringFirstButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButScoringFirstButton.bottomAnchor.constraint(equalTo: payButLoginFirstButton.topAnchor, constant: -8),
            payButScoringFirstButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onBuyButtonTap() {
        onPayRequested?()
    }
    
    @objc func onPayButLogingFirstButtonTap() {
        onPayButLoginFirstRequested?()
    }
    
    @objc func onPayButScoringFirstButtonTap() {
        onPayButScoringFirstRequested?()
    }
}
