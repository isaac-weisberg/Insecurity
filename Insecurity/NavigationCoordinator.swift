import UIKit

class NavigationCoordinator<Result> {
    enum State {
        struct Live {
            let navigationController: Weak<UINavigationController>
            let parent: WeakCommonNavigationCoordinator?
            let controller: Weak<UIViewController>
            let child: CommonNavigationCoordinator?
            let completionHandler: (Result?) -> Void
        }
        
        struct Dead {
            enum Reason {
                case finishCalled
                case dismissedByParent
                case deinitialized
            }
            
            let reason: Reason
        }
        
        case idle
        case live(Live)
        case liveButStagedForDeath(Live, Dead.Reason)
        case dead(Dead)
    }
    
    var state = State.idle
    
    public init() {
        
    }
    
    open var viewController: UIViewController {
        fatalError("Override this")
    }
    
    // MARK: - Public
    
    public func mount(on navigationController: UINavigationController,
                      completion: @escaping (Result?) -> Void) {
        switch state {
        case .idle:
            break
        case .dead, .live, .liveButStagedForDeath:
            insecAssertFail("Can not reuse a coordinator")
            return
        }
        assert(navigationController.viewControllers.isEmpty)
        
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized)
        }
        
        self.state = .live(State.Live(
            navigationController: Weak(navigationController),
            parent: nil,
            controller: Weak(controller),
            child: nil,
            completionHandler: { result in
                completion(result)
            }
        ))
        
        navigationController.setViewControllers([controller], animated: false)
    }
    
    public func finish(_ result: Result) {
        finish(result, source: .finishCall)
    }
    
    public func dismiss() {
        finish(nil, source: .finishCall)
    }
    
    // MARK: - Internal
    
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
        case .dead, .liveButStagedForDeath:
            insecAssert(source == .deinitialized, "Can't finish on something that's dead")
            return
        case .live(let liveData):
            live = liveData
        }
        
        let deadReason: State.Dead.Reason
        switch source {
        case .finishCall:
            deadReason = .finishCalled
        case .deinitialized:
            deadReason = .deinitialized
        }
        live.controller.value?.deinitObservable.onDeinit = nil
        self.state = .liveButStagedForDeath(live, deadReason)
        
        live.completionHandler(result)
        
        let shouldDismiss: Bool
        if let child = live.child {
            shouldDismiss = child.isInLiveState
        } else {
            shouldDismiss = true
        }
        
        if shouldDismiss {
            self.state = .dead(State.Dead(reason: deadReason))
            live.child?.parentWillDismiss()
            
            if
                let parent = live.parent?.value
            {
                parent.findFirstAliveAncestorAndPerformDismissal()
            } else {
                // There is no parent, which means, that this is the root coordinator,
                // and roots dismissal is handled by the initiator
            }
        }
    }
}

extension NavigationCoordinator: CommonNavigationCoordinator {
    func findFirstAliveAncestorAndPerformDismissal() {
        switch state {
        case .live(let live):
            if
                let navigationController = live.navigationController.value,
                let controller = live.controller.value
            {
                navigationController.popToViewController(controller, animated: true)
            }
        case .liveButStagedForDeath(let live, let deadReason):
            self.state = .dead(State.Dead(reason: deadReason))
            
            if let parent = live.parent?.value {
                parent.findFirstAliveAncestorAndPerformDismissal()
            } else {
                // There is no parent, which means, that this is the root coordinator,
                // and roots dismissal is handled by the initiator
            }
        case .dead, .idle:
            assertionFailure()
        }
    }
    
    func parentWillDismiss() {
        switch state {
        case .idle:
            insecAssertFail("Impossible")
        case .dead, .liveButStagedForDeath:
            break
        case .live(let live):
            live.controller.value?.deinitObservable.onDeinit = nil
            self.state = .dead(State.Dead(reason: .dismissedByParent))
            live.child?.parentWillDismiss()
        }
    }
    
    var isInLiveState: Bool {
        switch self.state {
        case .live:
            return true
        case .dead, .idle, .liveButStagedForDeath:
            return false
        }
    }
}

extension NavigationCoordinator.State.Live {
    func settingChild(to child: CommonNavigationCoordinator?) -> NavigationCoordinator.State.Live {
        NavigationCoordinator.State.Live(
            navigationController: self.navigationController,
            parent: self.parent,
            controller: self.controller,
            child: child,
            completionHandler: self.completionHandler
        )
    }
}
