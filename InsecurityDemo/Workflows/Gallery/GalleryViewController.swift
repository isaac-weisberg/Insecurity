import UIKit
import Insecurity

class GalleryViewController: UIViewController {
    var onProductRequested: (() -> Void)?
    var onAltButton: (() -> Void)?
    
    let button = UIButton(type: .system)
    let magicEndButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        
        navigationItem.title = "Catalog"
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("See product details", for: .normal)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        magicEndButton.translatesAutoresizingMaskIntoConstraints = false
        magicEndButton.setTitle("Magic end", for: .normal)
        view.addSubview(magicEndButton)
        NSLayoutConstraint.activate([
            magicEndButton.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -8),
            magicEndButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        magicEndButton.addTarget(self, action: #selector(onMagicEndButtonTap), for: .touchUpInside)
        
        DispatchQueue.main.asyncAfter(0.5) {
//            self.startPaymentMethodScreen()
//            self.startPaymentMethodScreenNavigation()
            self.startPaymentMethodScreenWithNewNavigation()
        }
    }
    
    @objc func onTap() {
        onProductRequested?()
    }
    
    @objc func onMagicEndButtonTap() {
        onAltButton?()
    }
    
    var customModalCoordinator: ModalCoordinatorAny?
    
    func startPaymentMethodScreen() {
        let modalCoordinator = ModalCoordinator(self)
        self.customModalCoordinator = modalCoordinator

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        modalCoordinator.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customModalCoordinator = nil
            // result is PaymentMethodScreenResult
        }
    }
    
    var customNavigationCoordinator: NavigationCoordinatorAny?
    
    func startPaymentMethodScreenNavigation() {
        let navigationController = self.navigationController!
        
        let navigationCoordinator = NavigationCoordinator(navigationController)
        self.customNavigationCoordinator = navigationCoordinator

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        navigationCoordinator.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customNavigationCoordinator = nil
            // result is PaymentMethodScreenResult
        }
    }
    
    func startPaymentMethodScreenWithNewNavigation() {
        let navigationController = UINavigationController()
        navigationController.setViewControllers([UIViewController(), UIViewController(), UIViewController()], animated: false)
        
        self.present(navigationController, animated: true)
        
        let navigationCoordinator = NavigationCoordinator(navigationController)
        self.customNavigationCoordinator = navigationCoordinator

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        navigationCoordinator.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customNavigationCoordinator = nil
            // result is PaymentMethodScreenResult
        }
    }
}
