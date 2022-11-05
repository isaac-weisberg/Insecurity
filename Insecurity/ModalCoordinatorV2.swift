import Foundation
import UIKit

open class ModalCoordinatorV2<Result>: CommonModalCoordinatorV2 {
    enum State {
        struct Mounted {
            let parent: WeakCommonModalCoordinatorV2
            let controller: Weak<UIViewController>
        }
        
        struct Root {
            let parentViewController: Weak<UIViewController>
            let controller: Weak<UIViewController>
        }
        
        case idle
        case mounted(Mounted)
        case root(Root)
    }
    
    var state: State = .idle
    var completionHandler: ((Result?) -> Void)?
    private var child: ModalCoordinatorV2?
    
    open var viewController: UIViewController {
        fatalError("Override this getter")
    }
    
    public init() {
        
    }
    
    func mount(on parent: CommonModalCoordinatorV2) -> UIViewController {
        switch state {
        case .idle:
            break
        case .mounted, .root:
            fatalError("Can not mount a coordinator that's already mounted")
        }
        
        let controller = self.viewController
        
        self.state = .mounted(State.Mounted(parent: WeakCommonModalCoordinatorV2(parent), controller: Weak(controller)))
        
        return controller
    }
    
    public func start<Result>(_ coordinator: ModalCoordinatorV2<Result>,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void) {
        let presentingViewController: UIViewController
        switch self.state {
        case .mounted(let mounted):
            guard let existingViewController = mounted.controller.value else {
                return
            }
            presentingViewController = existingViewController
        case .root(let root):
            guard let existingViewController = root.controller.value else {
                return
            }
            presentingViewController = existingViewController
        case .idle:
            assertionFailure("Can not start on an unmounted coordinator")
            return
        }
        assert(child == nil)
        let controller = coordinator.viewController
        
        coordinator.completionHandler = { result in
            completion(result)
        }
        
        presentingViewController.present(controller, animated: animated)
    }
    
    public func mount(on parentViewController: UIViewController,
                      animated: Bool,
                      _ completion: @escaping (Result?) -> Void) {
        let controller = self.viewController
        
        self.state = .root(State.Root(parentViewController: Weak(parentViewController), controller: Weak(controller)))
        
        parentViewController.present(controller, animated: animated)
    }
    
    public func finish(_ result: Result?) {
        completionHandler?(result)
    }
}
