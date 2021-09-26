import UIKit
import Insecurity

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var applicationCoordinator: ApplicationCoordinator?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .white

        window.rootViewController = rootViewController
        
        let applicationCoordinator = ApplicationCoordinator(window)
        self.applicationCoordinator = applicationCoordinator
        applicationCoordinator.start()

        return true
    }
}
