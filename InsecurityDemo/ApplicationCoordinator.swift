import Insecurity
import UIKit

class ApplicationCoordinator: WindowCoordinator {
    let di = DIContainer()
    
    func start() {
        if di.authService.hasCreds {
            startGallery()
        } else {
            startLogin()
        }
        
        di.authService.onLogout = { [weak self] in
            guard let self = self else { return }
            self.startLogin()
        }
    }
    
    func startLogin() {
        let loginCoordinator = LoginPhoneCoordinator(di: di)
        self.startNavitroller(UINavigationController(), loginCoordinator) { [weak self] loginResult in
            switch loginResult {
            case .loggedIn:
                print("End Login after logout")
                
                self?.startGallery()
            }
        }
    }
    
    func startGallery() {
        let di = self.di
        let navigationController = UINavigationController()
        let galleryCoordinator = GalleryCoordinator(di: di)
        self.startNavitroller(navigationController, galleryCoordinator) { [weak self] result in
            print("End Gallery \(result)")
            
            let paymentSuccessCoordinator = PaymentCoordinator(di: di)
            self?.startModaroller(paymentSuccessCoordinator) { [weak self] result in
                print("End PaymentResult after Gallery ended artificially \(result)")
                
                let navigationController = UINavigationController()
                let productCoordinator = ProductCoordinator(di: di)
                self?.startNavitroller(navigationController, productCoordinator) { result in
                    print("End Product after Gallery ended artificially \(result)")
                    // Not actually supposed to happen though
                }
            }
            
        }
    }
    
    func deviceShaken() {
        startDebugCoordinator()
    }
    
    var startedDebugCoordinator = false
    
    func startDebugCoordinator() {
        guard !startedDebugCoordinator else {
            return
        }
        startedDebugCoordinator = true
        
        let debugCoordinator = DebugViewCoordinator(di: di)
        
        self.startOverTop(debugCoordinator, animated: true) { [weak self] result in
            self?.startedDebugCoordinator = false
            print("End DebugView \(result)")
        }
    }
}
