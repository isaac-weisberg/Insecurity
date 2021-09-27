import Insecurity
import UIKit

class ApplicationCoordinator: WindowCoordinator {
    func start() {
        let navigationController = UINavigationController()
        let galleryCoordinator = GalleryCoordinator()
        self.startNavitroller(navigationController, galleryCoordinator) { result in
            print("End Gallery \(result)")
            
            let paymentSuccessCoordinator = PaymentCoordinator()
            self.startModaroller(paymentSuccessCoordinator) { result in
                print("End PaymentResult after Gallery ended artificially \(result)")
                
                let navigationController = UINavigationController()
                let productCoordinator = ProductCoordinator()
                self.startNavitroller(navigationController, productCoordinator) { result in
                    print("End Product after Gallery ended artificially \(result)")
                    // Not actually supposed to happen though
                }
            }
            
        }
    }
}
