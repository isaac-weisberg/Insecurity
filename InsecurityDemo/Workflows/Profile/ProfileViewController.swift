import Insecurity
import UIKit

class ProfileViewController: UIViewController {
    var onPaymentMethodsRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackgroundCompat
        
        DispatchQueue.main.asyncAfter(0.25) {
            self.onPaymentMethodsRequested?()
        }
    }
    
    func handleDefaultPaymentMethodChanged() {
        
    }
    
    var customModalHost: InsecurityHost?
    
    func startPaymentMethodScreen() {
        let modalHost = InsecurityHost(modal: self)
        self.customModalHost = modalHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        modalHost.start(paymentMethodCoordinator, in: .current, animated: true) { [weak self] result in
            self?.customModalHost = nil
            // result is PaymentMethodsScreenResult
        }
    }
    
    var customNavigationHost: InsecurityHost?
    
    func startPaymentMethodScreenNavigation() {
        let navigationController = self.navigationController!
        
        let navigationHost = InsecurityHost(navigation: navigationController)
        self.customNavigationHost = navigationHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        navigationHost.start(paymentMethodCoordinator, in: .current, animated: true) { [weak self] result in
            self?.customNavigationHost = nil
            // result is PaymentMethodsScreenResult
        }
    }
    
    func startPaymentMethodScreenWithNewNavigation() {
        let navigationController = UINavigationController()
        
        // Providing a UINavigationController that doesn't have a root AND only exactly one root with no other view controllers causes a crashs
        navigationController.setViewControllers([UIViewController(), UIViewController(), UIViewController()], animated: false)
        
        self.present(navigationController, animated: true)
        
        let navigationHost = InsecurityHost(navigation: navigationController)
        self.customNavigationHost = navigationHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        navigationHost.start(paymentMethodCoordinator, in: .current, animated: true) { [weak self] result in
            self?.customNavigationHost = nil
            // result is PaymentMethodsScreenResult
        }
    }
}
