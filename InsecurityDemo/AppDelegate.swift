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
        
        let windowCoordinator = ApplicationCoordinator(window)
        self.windowCoordinator = windowCoordinator
        windowCoordinator.start()
        
        window.makeKeyAndVisible()
        
        return true
    }
}
