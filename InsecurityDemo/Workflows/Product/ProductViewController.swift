import UIKit

class ProductViewController: UIViewController {
    var onCartRequested: (() -> Void)?
    
    let cartButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        cartButton.translatesAutoresizingMaskIntoConstraints = false
        cartButton.setTitle("Go to cart", for: .normal)
        view.addSubview(cartButton)
        cartButton.addTarget(self, action: #selector(onCartButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            cartButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            cartButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onCartButtonTap() {
        onCartRequested?()
    }
}
