import UIKit
import Insecurity

class ProfileCoordinator: ModalCoordinator<Never> {
    override var viewController: UIViewController {

        let profileViewController = ProfileViewController()

        let navigationController = UINavigationController(rootViewController: profileViewController)
        
        profileViewController.onPaymentMethodsRequested = { [weak profileViewController] in
//            let addPM = AddPaymentMethodCoordinator()
//
//            self.start(addPM, animated: true) { _ in
//
//            }

            let paymentMethodsCoordinator = PaymentMethodsCoordinator()

            self.start(paymentMethodsCoordinator, animated: true) { result in
                if result?.paymentMethodChanged == true {
                    profileViewController?.handleDefaultPaymentMethodChanged()
                }
            }
        }
        
        return navigationController
    }
}
