import UIKit
import Insecurity

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var windowCoordinator: WindowCoordinator?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let windowCoordinator = WindowCoordinator(window)
        
        let navigationController = UINavigationController()
        let galleryCoordinator = GalleryCoordinator()
        windowCoordinator.startNavitroller(navigationController, galleryCoordinator) { result in
            print("End Gallery \(result)")
            
            let paymentSuccessCoordinator = PaymentCoordinator()
            windowCoordinator.startModaroller(paymentSuccessCoordinator) { result in
                print("End PaymentResult after Gallery ended artificially \(result)")
                
                let navigationController = UINavigationController()
                let productCoordinator = ProductCoordinator()
                windowCoordinator.startNavitroller(navigationController, productCoordinator) { result in
                    print("End Product after Gallery ended artificially \(result)")
                    // Not actually supposed to happen though
                }
            }
            
        }
        window.makeKeyAndVisible()

        return true
    }
}
