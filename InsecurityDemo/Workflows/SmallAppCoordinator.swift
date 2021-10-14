import Insecurity
import UIKit

class AppCoordinator {
    let host: WindowHost
    
    init(_ window: UIWindow) {
        self.host = WindowHost(window)
    }
    
    func start() {
        let paymentMethodCoordinator = PaymentMethodCoordinator()
        
        self.host.start(paymentMethodCoordinator, duration: 0.5, options: .transitionCrossDissolve) { result in
            // Payment method coordinator result
        }
//
        // OR if we wanted to start it inside a UINavigationController

        self.host.start(UINavigationController(), paymentMethodCoordinator, duration: 0.5, options: .transitionCrossDissolve) { result in
            // Payment method coordinator result
        }
    }
}
