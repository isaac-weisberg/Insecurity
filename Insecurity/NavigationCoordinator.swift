import UIKit

open class NavigationCoordinator<Result> {
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
        case liveButChildIsStagedForDeath(Live)
        case liveButStagedForDeath(Live, Dead.Reason)
        case dead(Dead)
    }
    
    var state = State.idle
    
    public init() {
        
    }
    
    open var viewController: UIViewController {
        // Override this in the subclass
        fatalError()
    }
    
    // MARK: - Public
    
    public func mount(on navigationController: UINavigationController,
                      completion: @escaping (Result?) -> Void) {
        switch state {
        case .idle:
            break
        case .live, .liveButChildIsStagedForDeath:
            insecAssertFail(InsecurityMessage.noMountAMounted.s)
            return
        case .dead, .liveButStagedForDeath:
            insecAssertFail(InsecurityMessage.noMountAUsedOne.s)
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
        startInternal(coordinator, animated: animated, completion)
    }
    
    public func dismissChildren(animated: Bool) {
        switch self.state {
        case .liveButChildIsStagedForDeath:
            insecAssertFail(InsecurityMessage.noDismissMidOfFin.s)
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
    
    var _childCreaterAndMounterBlock: ((State.Live) -> UIViewController)?
    
    func getChildCreaterAndMounterBlockIfNeeded() -> ((State.Live) -> UIViewController)? {
        if let _childCreaterAndMounterBlock = self._childCreaterAndMounterBlock {
            self._childCreaterAndMounterBlock = nil
            
            return _childCreaterAndMounterBlock
        }
        return nil
    }

    func startInternal<Result>(_ coordinator: NavigationCoordinator<Result>,
                               animated: Bool,
                               _ completion: @escaping (Result?) -> Void) {
        switch state {
        case .liveButChildIsStagedForDeath:
            _childCreaterAndMounterBlock = { [weak self] (live: State.Live) -> UIViewController in
                guard let self = self else { return }
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
                
                return controller
            }
        case .live(let live):
            _startStateless(live: live, coordinator, animated: animated, completion)
        case .idle, .dead, .liveButStagedForDeath:
            insecAssertFail(InsecurityMessage.noStartOverDead.s)
            return
        }
    }
    
    func _startStateless<Result>(live: State.Live,
                                 _ coordinator: NavigationCoordinator<Result>,
                                 animated: Bool,
                                 _ completion: @escaping (Result?) -> Void) {
        
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
    }
    
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
            switch source {
            case .deinitialized:
                // This is kinda expected because there might be an off chance that the deinit handler of the controller will fire during the dismissal
                // Although, a bit lower down the code, we take an extra stride to clean the deinit observable
                // So actually I change my mind
                fatalError()
            case .finishCall:
                insecAssertFail(InsecurityMessage.noFinishOnDead.s)
            }
            return
        case .live(let liveData), .liveButChildIsStagedForDeath(let liveData):
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
        
        live.parent?.value?.childIsStagedForDeath()
        
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
        case .live, .liveButChildIsStagedForDeath:
            fatalError(InsecurityMessage.noMountAMounted.s)
        case .dead, .liveButStagedForDeath:
            fatalError(InsecurityMessage.noMountAUsedOne.s)
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
        case .liveButChildIsStagedForDeath(let live):
            let newLive = live.settingChild(to: nil)
            self.state = .live(newLive)
            
            if let childCreaterAndMounterBlock = getChildCreaterAndMounterBlockIfNeeded() {
                if
                    let navigationController = live.navigationController.value,
                    let controller = live.controller.value
                {
                    
                    let childController = childCreaterAndMounterBlock(newLive)
                    
                    let existingControllers = navigationController.viewControllers
                    
                    let newControllersOpt = existingControllers.removeSuffixAfterElByRef(controller, appending: childController)
                    if let newControllers = newControllersOpt {
                        navigationController.setViewControllers(newControllers, animated: true)
                    } else {
                        insecAssertFail(InsecurityMessage.noLlerInLlersNavi.s)
                    }
                }
            } else {
                if
                    let navigationController = live.navigationController.value,
                    let controller = live.controller.value
                {
                    navigationController.popToViewController(controller, animated: true)
                }
            }
        case .liveButStagedForDeath(let live, let deadReason):
            self.state = .dead(State.Dead(reason: deadReason))
            
            if let parent = live.parent?.value {
                parent.findFirstAliveAncestorAndPerformDismissal()
            } else {
                // There is no parent, which means, that this is the root coordinator,
                // and roots dismissal is handled by the initiator
            }
        case .dead, .idle, .live:
            assertionFailure()
        }
    }
    
    func childIsStagedForDeath() {
        switch state {
        case .live(let live):
            self.state = .liveButChildIsStagedForDeath(live)
        case .liveButChildIsStagedForDeath, .dead, .idle, .liveButStagedForDeath:
            fatalError()
        }
    }
    
    func parentWillDismiss() {
        switch state {
        case .liveButChildIsStagedForDeath:
            insecAssertFail(InsecurityMessage.noDismissMidOfFin.s)
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
        case .live, .liveButChildIsStagedForDeath:
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

extension Array where Element == UIViewController {
    func removeSuffixAfterElByRef(_ element: UIViewController, appending: UIViewController) -> [UIViewController]? {
        if let firstIndexOfElement = self.firstIndex(where: { el in
            el === element
        }) {
            let prefixIncludingElement = self[0...firstIndexOfElement]
            
            let totalArray = prefixIncludingElement + [appending]
            
            return Array(totalArray)
        }
        return nil
    }
}
