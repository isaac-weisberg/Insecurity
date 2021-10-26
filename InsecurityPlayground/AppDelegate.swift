import UIKit
import Insecurity

class PlaygroundAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var coordinator: ApplicationCoordinator?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let coordinator = ApplicationCoordinator(window)
        self.coordinator = coordinator
        coordinator.start()
        
        window.makeKeyAndVisible()
        
        return true
    }
    
    func shakeDetected() {
        coordinator?.deviceShaken()
    }
}
