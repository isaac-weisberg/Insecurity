import Insecurity
import UIKit

enum GenericEventAction {
    case nothing
    case finish
    case start(GenericCoordinator)
    case startNavigation(GenericCoordinator)
    case startModal(GenericCoordinator)
}

enum GenericFinishAction {
    case finish
    case dismiss
    case nothing
}

class GenericCoordinator: AdaptiveCoordinator<Void> {
    let action: GenericEventAction
    let finishAction: GenericFinishAction
    
    init(_ action: GenericEventAction, _ finishAction: GenericFinishAction = .dismiss) {
        self.action = action
        self.finishAction = finishAction
    }
    
    override var viewController: UIViewController {
        let genericViewController = GenericViewController()
        
        let finish: (()) -> Void = { [weak self] _ in
            guard let self = self else { return }
            switch self.finishAction {
            case .dismiss:
                self.dismiss()
            case .finish:
                self.finish(())
            case .nothing:
                break
            }
        }
        
        genericViewController.onEvent = {
            switch self.action {
            case .nothing:
                break
            case .finish:
                finish(())
            case .start(let genericCoordinator):
                self.navigation.start(genericCoordinator, in: .current, animated: true) { result in
                    print("End GenericCoordinator regular start \(result)")
                    finish(())
                }
            case .startNavigation(let genericCoordinator):
                self.navigation.start(genericCoordinator, in: .new(UINavigationController()), animated: true) { result in
                    print("End GenericCoordinator navigation \(result)")
                    finish(())
                }
            case .startModal(let genericCoordinator):
                self.navigation.start(genericCoordinator, in: .newModal, animated: true) { result in
                    print("End GenericCoordinator modal \(result)")
                    finish(())
                }
            }
        }
        
        return genericViewController
    }
}
