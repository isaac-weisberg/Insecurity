import Insecurity
import UIKit

enum GenericEventAction {
    case finish
    case start(GenericChild)
    case startNavigation(GenericChild)
    case startModal(GenericChild)
    case nothing
}

enum GenericFinishAction {
    case finish
    case nothing
}

class GenericChild: AdaptiveChild<Void> {
    let action: GenericEventAction
    let finishAction: GenericFinishAction
    
    init(_ action: GenericEventAction, _ finishAction: GenericFinishAction = .finish) {
        self.action = action
        self.finishAction = finishAction
    }
    
    override var viewController: UIViewController {
        let genericViewController = GenericViewController()
        
        let finish: (()) -> Void = { [weak self] _ in
            guard let self = self else { return }
            switch self.finishAction {
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
            case .start(let genericChild):
                self.navigation.start(genericChild, in: .current, animated: true) { result in
                    print("End GenericChild regular start \(result)")
                    finish(())
                }
            case .startNavigation(let genericChild):
                self.navigation.start(genericChild, in: .new(UINavigationController()), animated: true) { result in
                    print("End GenericChild navigation \(result)")
                    finish(())
                }
            case .startModal(let genericChild):
                self.navigation.start(genericChild, in: .newModal, animated: true) { result in
                    print("End GenericChild modal \(result)")
                    finish(())
                }
            }
        }
        
        return genericViewController
    }
}
