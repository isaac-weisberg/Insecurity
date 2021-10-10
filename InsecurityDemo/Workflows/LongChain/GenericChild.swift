import Insecurity
import UIKit

enum GenericAction {
    case finish
    case start(GenericChild)
    case startNavigation(GenericChild)
    case startModal(GenericChild)
}

class GenericChild: InsecurityChild<Void> {
    let action: GenericAction
    
    init(_ action: GenericAction) {
        self.action = action
    }
    
    override var viewController: UIViewController {
        let genericViewController = GenericViewController()
        
        genericViewController.onEvent = {
            switch self.action {
            case .finish:
                self.finish(())
            case .start(let genericChild):
                self.navigation.start(genericChild, animated: true) { result in
                    print("End GenericChild regular start \(result)")
                    self.finish(())
                }
            case .startNavigation(let genericChild):
                self.navigation.start(UINavigationController(), genericChild, animated: true) { result in
                    print("End GenericChild navigation \(result)")
                    self.finish(())
                }
            case .startModal(let genericChild):
                self.navigation.startModal(genericChild, animated: true) { result in
                    print("End GenericChild modal \(result)")
                    self.finish(())
                }
            }
        }
        
        return genericViewController
    }
}
