import Insecurity
import UIKit

class ApplicationCoordinator: WindowCoordinator {
    func start() {
        let profileCoordinator = ProfileCoordinator()
        
        navigation.start(NavigationController(), profileCoordinator, animated: true) { result in
            
        }
    }
}
