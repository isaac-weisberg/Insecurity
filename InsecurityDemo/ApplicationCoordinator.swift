import UIKit
import Insecurity

class ApplicationCoordinator {
    let window: UIWindow
    
    init(_ window: UIWindow) {
        self.window = window
    }
    
    var navitrollerCoordinator: NavitrollerCoordinator?
    
    func start() {
        let navigationController = UINavigationController()
        
        window.rootViewController = navigationController
        
        let navitrollerCoordinator = NavitrollerCoordinator(navigationController)
        
        let galleryCoordinator = GalleryCoordinator()
        
        navitrollerCoordinator.startChild(galleryCoordinator, animated: false) { result in
            switch result {
            case .normal:
                // Impossible because it's Never
                break
            case .dismissed:
                // Impossible because it's a root controller
                break
            }
        }
        
        window.makeKeyAndVisible()
    }
}
