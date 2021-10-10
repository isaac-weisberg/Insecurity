import Insecurity
import UIKit

class ApplicationCoordinator: WindowCoordinator {
    let di = DIContainer()
    
    func start() {
        startGallery()
        
        return
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
        self.start(UINavigationController(), loginCoordinator, duration: 0.3, options: [.transitionFlipFromRight, .curveEaseInOut]) { [weak self] result in
            switch result {
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
        self.start(navigationController, galleryCoordinator, duration: 0.3, options: [.transitionFlipFromTop, .curveEaseInOut]) { [weak self] result in
            print("End Gallery \(result)")
            
            let paymentSuccessCoordinator = PaymentCoordinator(di: di)
            self?.start(paymentSuccessCoordinator, duration: 0.3, options: [.transitionCurlUp, .curveEaseInOut]) { [weak self] result in
                print("End PaymentResult after Gallery ended artificially \(result)")
                
                let navigationController = UINavigationController()
                let productCoordinator = ProductCoordinator(di: di)
                self?.start(navigationController, productCoordinator, duration: 0.3, options: [.transitionCrossDissolve, .curveEaseInOut]) { result in
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
