import Insecurity
import UIKit

class ApplicationCoordinator: WindowCoordinator {
    func start() {
        let profileCoordinator = ProfileCoordinator()
        
        navigation.start(profileCoordinator, animated: true) { result in
            
        }
    }
}
