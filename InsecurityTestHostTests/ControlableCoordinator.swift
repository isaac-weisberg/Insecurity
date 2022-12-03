import Foundation
import UIKit
@testable import Insecurity

class ControlableCoordinator: ModalCoordinator<Void> {
    override var viewController: UIViewController {
        let controller = UIViewController()
        
        return controller
    }
}
