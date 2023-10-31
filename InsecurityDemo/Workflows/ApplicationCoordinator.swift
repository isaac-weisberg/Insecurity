import Insecurity
import UIKit

class ApplicationCoordinator {
    let window: UIWindow
    let insecurityHost = InsecurityHost()

    init(_ window: UIWindow) {
        self.window = window
    }

    func start() {
        let profileCoordinator = ProfileCoordinator()

        let controller = insecurityHost.mountForManualManagement(profileCoordinator) { _ in

        }

        window.rootViewController = controller
    }
}
