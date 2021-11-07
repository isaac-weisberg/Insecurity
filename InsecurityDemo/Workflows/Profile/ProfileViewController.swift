import Insecurity
import UIKit

class ProfileViewController: UIViewController {
    var onPaymentMethodsRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackgroundCompat
        
        DispatchQueue.main.asyncAfter(0.25) { [weak self] in
            guard let self = self else { return }
            
            self.onPaymentMethodsRequested?()
//            self.startPaymentMethodScreen()
//            self.startPaymentMethodScreenNavigation()
//            self.startPaymentMethodScreenWithNewNavigation()
        }
    }
    
    func handleDefaultPaymentMethodChanged() {
        
    }
    
    func startPaymentMethodScreen() {
        let insecurityHost = InsecurityHost(modal: self)
        self.customInsecurityHost = insecurityHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        insecurityHost.start(paymentMethodCoordinator, in: .current, animated: true) { [weak self] result in
            self?.customInsecurityHost = nil
            // result is PaymentMethodsScreenResult?
        }
    }
    
    var customInsecurityHost: InsecurityHost?
    
    func startPaymentMethodScreenNavigation() {
        let navigationController = self.navigationController!
        
        let insecurityHost = InsecurityHost(navigation: navigationController)
        self.customInsecurityHost = insecurityHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        insecurityHost.start(paymentMethodCoordinator, in: .current, animated: true) { [weak self] result in
            self?.customInsecurityHost = nil
            // result is PaymentMethodsScreenResult?
        }
    }
    
    func startPaymentMethodScreenWithNewNavigation() {
        let navigationController = UINavigationController()
        
        // Providing a UINavigationController that doesn't have only exactly one viewController causes an assertion failure
        navigationController.setViewControllers([UIViewController(), UIViewController(), UIViewController()], animated: false)
        
        self.present(navigationController, animated: true)
        
        let insecurityHost = InsecurityHost(navigation: navigationController)
        self.customInsecurityHost = insecurityHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        insecurityHost.start(paymentMethodCoordinator, in: .current, animated: true) { [weak self] result in
            self?.customInsecurityHost = nil
            // result is PaymentMethodsScreenResult
        }
    }
}
