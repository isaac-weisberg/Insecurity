import UIKit

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let controller = ViewController.shared
        
        window.rootViewController = controller
        
        window.makeKeyAndVisible()
        
        return true
    }
}
