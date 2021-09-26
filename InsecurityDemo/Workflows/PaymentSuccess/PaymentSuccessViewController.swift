import UIKit

class PaymentSuccessViewController: UIViewController {
    var onConfirm: (() -> Void)?
    
    let confirmButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBrown
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.setTitle("Confirm", for: .normal)
        view.addSubview(confirmButton)
        confirmButton.addTarget(self, action: #selector(onConfirmTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            confirmButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onConfirmTap() {
        onConfirm?()
    }
}
