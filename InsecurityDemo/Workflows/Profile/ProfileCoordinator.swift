import UIKit
import Insecurity

class ProfileCoordinator: NavigationCoordinator<Never> {
    override var viewController: UIViewController {
        let profileViewController = ProfileViewController()
        
        profileViewController.onPaymentMethodsRequested = { [weak profileViewController] in
            let paymentMethodsCoordinator = PaymentMethodsCoordinator()
            
            self.navigation.start(paymentMethodsCoordinator, in: .navigation(new: NavigationController()), animated: true) { result in
                if result?.paymentMethodChanged == true {
                    profileViewController?.handleDefaultPaymentMethodChanged()
                }
            }
        }
        
        return profileViewController
    }
}
