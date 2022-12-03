import UIKit

class NavigationCoordinator<Result> {
    enum State {
        struct Live {
            let navigationController: Weak<UINavigationController>
            let parent: WeakCommonNavigationCoordinator?
            let controller: Weak<UIViewController>
        }
        
        enum Dead {
            case finishCalled
            case deinitialized
        }
        
        case idle
        case live(Live)
        case dead(Dead)
    }
    
    var state = State.idle
    var completionHandler: ((Result?) -> Void)?
    
    public init() {
        
    }
    
    open var viewController: UIViewController {
        fatalError("Override this")
    }
    
    public func mount(on navigationController: UINavigationController,
                      animated: Bool,
                      completion: @escaping (Result?) -> Void) {
        switch state {
        case .idle:
            break
        case .dead:
            insecAssertFail("Can not reuse a coordinator")
            return
        case .live:
            insecAssertFail("Coordinator already in use")
            return
        }
        assert(navigationController.viewControllers.count == 1)
        
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized)
        }
        
        self.completionHandler = { result in
            completion(result)
        }
        
        self.state = .live(State.Live(navigationController: Weak(navigationController),
                                      parent: nil,
                                      controller: Weak(controller)))
        
        navigationController.pushViewController(controller, animated: animated)
    }
    
    public func finish(_ result: Result) {
        finish(result, source: .finishCall)
    }
    
    public func dismiss() {
        finish(nil, source: .finishCall)
    }
    
    enum FinishSource {
        case finishCall
        case deinitialized
    }
    
    public func finish(_ result: Result?, source: FinishSource) {
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
        case .finishCall:
            deadReason = .finishCalled
        case .deinitialized:
            deadReason = .deinitialized
        }
        self.state = .dead(deadReason)
        
        completionHandler?(result)
        
        if let navigationController = live.navigationController.value {
            if let liveParent = live.parent?.value {
                if !liveParent.isInDeadState {
                    if let parentViewController = liveParent.instantiatedViewController {
                        if navigationController.viewControllers.preLast() === parentViewController {
                            navigationController.popToViewController(parentViewController, animated: true)
                        }
                    }
                    
                }
            } else {
                navigationController.popToRootViewController(animated: true)
            }
        }
    }
    
    private var viewControllerIfExists: UIViewController? {
        switch state {
        case .live(let live):
            if let controller = live.controller.value {
                return controller
            } else {
                return nil
            }
        case .dead, .idle:
            return nil
        }
    }
}

extension NavigationCoordinator: CommonNavigationCoordinator {
    var instantiatedViewController: UIViewController? {
        viewControllerIfExists
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
