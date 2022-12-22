import Foundation
import UIKit

open class ModalCoordinator<Result> {
    enum State {
        struct Live {
            enum Parent {
                case controller(Weak<UIViewController>)
                case coordinator(WeakCommonModalCoordinator)
            }
            
            let parent: Parent
            let controller: Weak<UIViewController>
            let child: CommonModalCoordinator?
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
    
    var state: State = .idle
    
    open var viewController: UIViewController {
        // Override this in the subclass
        fatalError()
    }
    
    public init() {
        
    }
    
    // MARK: - Public
    
    public func start<Result>(_ coordinator: ModalCoordinator<Result>,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void) {
        startInternal(
            coordinator,
            animated: animated,
            completion: completion,
            onPresentCompleted: nil
        )
    }
    
    public func start<Result>(_ coordinator: ModalCoordinator<Result>,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void,
                              onPresentCompleted: @escaping () -> Void) {
        startInternal(
            coordinator,
            animated: animated,
            completion: completion,
            onPresentCompleted: onPresentCompleted
        )
    }
    
    public func mount(on parentViewController: UIViewController,
                      animated: Bool,
                      completion: @escaping (Result?) -> Void,
                      onPresentCompleted: @escaping () -> Void) {
        mountOnControllerInternal(
            on: parentViewController,
            animated: animated,
            completion: completion,
            onPresentCompleted: onPresentCompleted
        )
    }
    
    public func mount(on parentViewController: UIViewController,
                      animated: Bool,
                      completion: @escaping (Result?) -> Void) {
        mountOnControllerInternal(
            on: parentViewController,
            animated: animated,
            completion: completion,
            onPresentCompleted: nil
        )
    }
    
    public func finish(_ result: Result) {
        finish(result, source: .finishCall)
    }
    
    public func dismiss() {
        finish(nil, source: .finishCall)
    }
    
    public func dismissChildren(animated: Bool) {
        dismissChildrenInternal(animated: animated, completion: nil)
    }
    
    public func dismissChildren(animated: Bool,
                                completion: @escaping () -> Void) {
        dismissChildrenInternal(animated: animated, completion: completion)
    }
    
    // MARK: - Internal
    
    func mount(on parent: CommonModalCoordinator,
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
                parent: .coordinator(parent.weak),
                controller: Weak(controller),
                child: nil,
                completionHandler: { result in
                    completion(result)
                }
            )
        )
        
        return controller
    }
    
    var _performCoordinatorStartBlock: (() -> Void)?
    
    func performCoordinatorStartIfNeeded() {
        if let _performCoordinatorStartBlock = _performCoordinatorStartBlock {
            self._performCoordinatorStartBlock = nil
            
            _performCoordinatorStartBlock()
        }
    }
    
    func startInternal<NewResult>(_ coordinator: ModalCoordinator<NewResult>,
                                  animated: Bool,
                                  completion: @escaping (NewResult?) -> Void,
                                  onPresentCompleted: (() -> Void)?) {
        assert(coordinator !== self)
        switch self.state {
        case .liveButChildIsStagedForDeath:
            _performCoordinatorStartBlock = { [weak self] in
                guard let self = self else { return }
                
                switch self.state {
                case .live(let live):
                    self._startStateless(live,
                                         coordinator,
                                         animated: animated,
                                         completion: completion,
                                         onPresentCompleted: onPresentCompleted)
                case .liveButChildIsStagedForDeath, .dead, .idle, .liveButStagedForDeath:
                    fatalError()
                }
            }
        case .live(let live):
            _startStateless(live,
                            coordinator,
                            animated: animated,
                            completion: completion,
                            onPresentCompleted: onPresentCompleted)
        case .idle, .dead, .liveButStagedForDeath:
            insecAssertFail(InsecurityMessage.noStartOverDead.s)
            return
        }
    }
    
    func _startStateless<NewResult>(_ live: State.Live,
                                    _ coordinator: ModalCoordinator<NewResult>,
                                    animated: Bool,
                                    completion: @escaping (NewResult?) -> Void,
                                    onPresentCompleted: (() -> Void)?) {
        assert(live.child == nil)
        
        guard let presentingViewController = live.controller.value else {
            return
        }
        
        let controller = coordinator.mount(on: self, completion: { result in
            completion(result)
        })
        
        self.state = .live(live.settingChild(to: coordinator))
        
        presentingViewController.present(
            controller,
            animated: animated,
            completion: {
                onPresentCompleted?()
            }
        )
    }
    
    func mountOnControllerInternal(
        on parentViewController: UIViewController,
        animated: Bool,
        completion: @escaping (Result?) -> Void,
        onPresentCompleted: (() -> Void)?
    ) {
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized)
        }
        
        self.state = .live(
            State.Live(
                parent: .controller(Weak(parentViewController)),
                controller: Weak(controller),
                child: nil,
                completionHandler: { result in
                    completion(result)
                }
            )
        )
        
        parentViewController.present(controller, animated: animated, completion: {
            onPresentCompleted?()
        })
    }
    
    enum FinishSource {
        case finishCall
        case deinitialized
    }
    
    func finish(
        _ result: Result?,
        source: FinishSource
    ) {
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
        
        switch live.parent {
        case .controller:
            break
        case .coordinator(let parent):
            parent.value?.childIsStagedForDeath()
        }
        
        live.completionHandler(result)
        
        let shouldStartDismissPropagationChain: Bool
        if let child = live.child {
            shouldStartDismissPropagationChain = child.isInLiveState
            // This means, that the child and its children are not participating in
            // this finish call chain and `self` is the topmost handler of this finishing chain
        } else {
            shouldStartDismissPropagationChain = true
        }
        
        if shouldStartDismissPropagationChain {
            self.state = .dead(State.Dead(reason: deadReason))
            live.child?.parentWillDismiss()
            
            switch live.parent {
            case .controller(let parentController):
                if
                    let presentingController = parentController.value,
                    presentingController.presentedViewController != nil
                {
                    presentingController.dismiss(animated: true)
                }
            case .coordinator(let parentCoordinator):
                if let parentCoordinator = parentCoordinator.value {
                    parentCoordinator.findFirstAliveAncestorAndCutTheChainDismissing()
                }
            }
        }
    }
    
    func dismissChildrenInternal(animated: Bool,
                                 completion: (() -> Void)?) {
        switch self.state {
        case .liveButChildIsStagedForDeath:
            insecAssertFail(InsecurityMessage.noDismissMidOfFin.s)
        case .idle, .dead, .liveButStagedForDeath:
            completion?()
        case .live(let live):
            if let child = live.child {
                let newLive = live.settingChild(to: nil)
                self.state = .live(newLive)
                child.parentWillDismiss()
            }
            if
                let presentingViewController = live.controller.value,
                presentingViewController.presentedViewController != nil
            {
                presentingViewController.dismiss(animated: animated, completion: {
                    completion?()
                })
            } else {
                completion?()
            }
        }
    }
}

extension ModalCoordinator: CommonModalCoordinator {
    func findFirstAliveAncestorAndCutTheChainDismissing() {
        switch state {
        case .liveButChildIsStagedForDeath(let live):
            self.state = .live(live.settingChild(to: nil))
            if
                let controller = live.controller.value,
                controller.presentedViewController != nil
            {
                controller.dismiss(animated: true) {
                    self.performCoordinatorStartIfNeeded()
                }
            } else {
                self.performCoordinatorStartIfNeeded()
            }
        case .liveButStagedForDeath(let live, let deadReason):
            self.state = .dead(State.Dead(reason: deadReason))
            
            switch live.parent {
            case .coordinator(let parentCoordinator):
                if let parentCoordinator = parentCoordinator.value {
                    parentCoordinator.findFirstAliveAncestorAndCutTheChainDismissing()
                }
            case .controller(let parentController):
                if
                    let parentController = parentController.value,
                    parentController.presentedViewController != nil
                {
                    parentController.dismiss(animated: true)
                }
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
            insecAssertFail(InsecurityMessage.impossible.s)
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

extension ModalCoordinator.State.Live {
    func settingChild(to child: CommonModalCoordinator?) -> ModalCoordinator.State.Live {
        ModalCoordinator.State.Live(
            parent: self.parent,
            controller: self.controller,
            child: child,
            completionHandler: self.completionHandler
        )
    }
}
