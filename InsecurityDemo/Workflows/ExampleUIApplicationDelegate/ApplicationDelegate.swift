import UIKit

// @main
class ApplicationDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let appCoordinator = AppCoordinator(window)
        self.appCoordinator = appCoordinator
        
        appCoordinator.start()
        
        window.makeKeyAndVisible()
        
        return true
    }
}
