import Foundation
import UIKit

open class ModalCoordinatorV2<Result> {
    enum State {
        enum Live {
            struct Mounted {
                let parent: WeakCommonModalCoordinatorV2
                let controller: Weak<UIViewController>
            }
            
            struct Root {
                let parentViewController: Weak<UIViewController>
                let controller: Weak<UIViewController>
            }
            case mounted(Mounted)
            case root(Root)
        }
        
        case idle
        case live(Live)
        case dead
    }
    
    var state: State = .idle
    var completionHandler: ((Result?) -> Void)?
    private var child: CommonModalCoordinatorV2?
    
    open var viewController: UIViewController {
        fatalError("Override this getter")
    }
    
    public init() {
        
    }
    
    func mount(on parent: CommonModalCoordinatorV2) -> UIViewController {
        switch state {
        case .idle:
            break
        case .live:
            fatalError("Can not mount a coordinator that's already mounted")
        case .dead:
            fatalError("Can not mount a coordinator that's already been used")
        }
        
        let controller = self.viewController
        
        self.state = .live(.mounted(State.Live.Mounted(parent: WeakCommonModalCoordinatorV2(parent), controller: Weak(controller))))
        
        return controller
    }
    
    public func start<Result>(_ coordinator: ModalCoordinatorV2<Result>,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void) {
        let presentingViewController: UIViewController
        switch self.state {
        case .live(.mounted(let mounted)):
            guard let existingViewController = mounted.controller.value else {
                return
            }
            presentingViewController = existingViewController
        case .live(.root(let root)):
            guard let existingViewController = root.controller.value else {
                return
            }
            presentingViewController = existingViewController
        case .idle, .dead:
            insecAssertFail("Can not start on an unmounted coordinator")
            return
        }
        assert(child == nil)
        let controller = coordinator.mount(on: self)
        
        coordinator.completionHandler = { result in
            completion(result)
        }
        
        presentingViewController.present(controller, animated: animated)
        self.child = coordinator
    }
    
    public func mount(on parentViewController: UIViewController,
                      animated: Bool,
                      _ completion: @escaping (Result?) -> Void) {
        let controller = self.viewController
        
        self.state = .live(.root(State.Live.Root(parentViewController: Weak(parentViewController), controller: Weak(controller))))
        
        self.completionHandler = { result in
            completion(result)
        }
        
        parentViewController.present(controller, animated: animated)
    }
    
    public func finish(_ result: Result?) {
        let live: State.Live
        let oldState = self.state
        switch oldState {
        case .idle:
            fatalError("Can't finish on a coordinator that wasn't mounted")
        case .dead:
            insecAssertFail("Can't finish on something that's dead")
            return
        case .live(let liveData):
            live = liveData
        }
        
        self.state = .dead
        
        completionHandler?(result)
        
        switch live {
        case .root(let root):
            if let presentingController = root.parentViewController.value {
                if presentingController.presentedViewController != nil {
                    presentingController.dismiss(animated: true)
                }
            }
        case .mounted(let mounted):
            if let parent = mounted.parent.value {
                if !parent.isInDeadState {
                    if let instantiatedParentController = parent.instantiatedViewController {
                        if instantiatedParentController.presentedViewController != nil {
                            instantiatedParentController.dismiss(animated: true)
                        }
                    }
                }
            }
        }
        
        self.child = nil
    }
}

extension ModalCoordinatorV2: CommonModalCoordinatorV2 {
    var instantiatedViewController: UIViewController? {
        switch state {
        case .live(let live):
            switch live {
            case .root(let root):
                return root.controller.value
            case .mounted(let mounted):
                return mounted.controller.value
            }
        case .dead, .idle:
            return nil
        }
    }
    
    var isInDeadState: Bool {
        switch self.state {
        case .dead:
            return true
        case .live, .idle:
            return false
        }
    }
}
