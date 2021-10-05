import UIKit

class PaymentViewController: UIViewController {
    typealias DI = HasAuthService
    
    let di: DI
    
    init(di: DI) {
        self.di = di
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onPaymentSuccess: (() -> Void)?
    
    let payButton = UIButton(type: .system)
    let randomLogoutButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBrownCompat
        
        navigationItem.title = "Payment"
        
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.setTitle("Pay", for: .normal)
        view.addSubview(payButton)
        payButton.addTarget(self, action: #selector(onPayButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            payButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        randomLogoutButton.setTitle("Randomly logout", for: .normal)
        randomLogoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(randomLogoutButton)
        randomLogoutButton.addTarget(self, action: #selector(onRandomLogountButtonPressed), for: .touchUpInside)
        NSLayoutConstraint.activate([
            randomLogoutButton.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -8),
            randomLogoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onPayButtonTap() {
        onPaymentSuccess?()
    }
    
    @objc func onRandomLogountButtonPressed() {
        // Let's simulate that randomly turns out that user's credentials have expired and it's time to sent him to the bye-bye
        di.authService.logout()
    }
}
