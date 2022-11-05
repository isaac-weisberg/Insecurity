import Foundation
import UIKit

open class ModalCoordinator<Result> {
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
        
        enum Dead {
            case result
            case deinitialized
            case dismissedByParent
        }
        
        case idle
        case live(Live)
        case dead(Dead)
    }
    
    var state: State = .idle
    var completionHandler: ((Result?) -> Void)?
    private var child: CommonModalCoordinator?
    
    open var viewController: UIViewController {
        fatalError("Override this getter")
    }
    
    public init() {
        
    }
    
    func mount(on parent: CommonModalCoordinator) -> UIViewController {
        switch state {
        case .idle:
            break
        case .live:
            fatalError("Can not mount a coordinator that's already mounted")
        case .dead:
            fatalError("Can not mount a coordinator that's already been used")
        }
        
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized)
        }
        
        self.state = .live(.mounted(State.Live.Mounted(parent: WeakCommonModalCoordinatorV2(parent), controller: Weak(controller))))
        
        return controller
    }
    
    public func start<Result>(_ coordinator: ModalCoordinator<Result>,
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
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized)
        }
        
        self.state = .live(.root(State.Live.Root(parentViewController: Weak(parentViewController), controller: Weak(controller))))
        
        self.completionHandler = { result in
            completion(result)
        }
        
        parentViewController.present(controller, animated: animated)
    }
    
    enum FinishSource {
        case result
        case deinitialized
    }
    
    public func finish(_ result: Result) {
        finish(result, source: .result)
    }
    
    public func dismiss() {
        finish(nil, source: .result)
    }
    
    func finish(_ result: Result?, source: FinishSource) {
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
        
        let deadReason: State.Dead
        switch source {
        case .result:
            deadReason = .result
        case .deinitialized:
            deadReason = .deinitialized
        }
        self.state = .dead(deadReason)
        
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
                parent.childWillUnmount()
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
    
    public func dismissChildren(animated: Bool,
                                completion: (() -> Void)? = nil) {
        switch self.state {
        case .idle, .dead:
            completion?()
            break
        case .live(let live):
            if let child = child {
                self.child = nil
                child.parentWillDismiss()
                switch live {
                case .mounted(let mounted):
                    if let presentingViewController = mounted.controller.value {
                        if presentingViewController.presentedViewController != nil {
                            presentingViewController.dismiss(animated: animated, completion: {
                                completion?()
                            })
                        }
                    }
                case .root(let root):
                    if let presentingViewController = root.controller.value {
                        if presentingViewController.presentedViewController != nil {
                            presentingViewController.dismiss(animated: animated, completion: {
                                completion?()
                            })
                        }
                    }
                }
            }
        }
    }
}

extension ModalCoordinator: CommonModalCoordinator {
    func childWillUnmount() {
        child = nil
    }
    
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
    
    func parentWillDismiss() {
        switch state {
        case .idle:
            self.state = .dead(.dismissedByParent)
            insecAssertFail("Impossible")
        case .dead:
            break
        case .live:
            self.state = .dead(.dismissedByParent)
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
