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
    
    public func start<Result>(_ coordinator: NavigationCoordinator<Result>,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void) {
        switch state {
        case .live(let live):
            assert(live.child == nil)
            guard let navigationController = live.navigationController.value else {
                return
            }
            
            let controller = coordinator.mount(
                on: self,
                navigationController: navigationController,
                completion: { result in
                    completion(result)
                }
            )
            
            self.state = .live(live.settingChild(to: coordinator))
            
            navigationController.pushViewController(controller, animated: animated)
        case .idle, .dead, .liveButStagedForDeath:
            insecAssertFail(InsecurityMessage.noStartOverDead.s)
            return
        }
    }
    
    public func dismissChildren(animated: Bool) {
        switch self.state {
        case .idle, .dead, .liveButStagedForDeath:
            break
        case .live(let live):
            if let child = live.child {
                let newLive = live.settingChild(to: nil)
                self.state = .live(newLive)
                child.parentWillDismiss()
            }
            
            if
                let navigationController = live.navigationController.value,
                let controller = live.controller.value
            {
                navigationController.popToViewController(controller, animated: animated)
            }
        }
    }
    
    // MARK: - Internal
    
    enum FinishSource {
        case finishCall
        case deinitialized
    }
    
    func finish(_ result: Result?, source: FinishSource) {
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
    
    func mount(on parent: CommonNavigationCoordinator,
               navigationController: UINavigationController,
               completion: @escaping (Result?) -> Void) -> UIViewController {
        assert(parent !== self)
        switch state {
        case .idle:
            break
        case .live:
            fatalError("Can not mount a coordinator that's already mounted")
        case .dead, .liveButStagedForDeath:
            fatalError("Can not mount a coordinator that's already been used")
        }
        
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized)
        }
        
        self.state = .live(
            State.Live(
                navigationController: Weak(navigationController),
                parent: parent.weak,
                controller: Weak(controller),
                child: nil,
                completionHandler: { result in
                    completion(result)
                }
            )
        )
        
        return controller
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
