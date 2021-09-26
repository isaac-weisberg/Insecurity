import UIKit
import Insecurity

class ApplicationCoordinator {
    let window: UIWindow
    
    init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerCoordinator: NavitrollerCoordinator<Void>?
    
    func start() {
        let navigationController = UINavigationController()
        
        window.rootViewController = navigationController
        
        let navitrollerCoordinator = NavitrollerCoordinator(navigationController, GalleryCoordinator()) { result in
            print("End Gallery \(result)")
            self.navitrollerCoordinator = nil
        }
        self.navitrollerCoordinator = navitrollerCoordinator
        
        window.makeKeyAndVisible()
    }
}
