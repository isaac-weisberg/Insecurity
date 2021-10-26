import Insecurity
import UIKit

class AppCoordinator: WindowCoordinator {
    func start() {
        let paymentMethodCoordinator = PaymentMethodCoordinator()
        
        self.navigation.start(paymentMethodCoordinator, duration: 0.5, options: .transitionCrossDissolve) { result in
            // Payment method coordinator result
        }

// OR if we wanted to start it inside a UINavigationController:

//        self.navigation.start(UINavigationController(), paymentMethodCoordinator, duration: 0.5, options: .transitionCrossDissolve) { result in
//            // Payment method coordinator result
//        }
    }
}
