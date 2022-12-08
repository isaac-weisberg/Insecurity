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
                case result
                case deinitialized
                case dismissedByParent
            }
            
            let reason: Reason
        }
        
        case idle
        case live(Live)
        case liveButStagedForDeath(Live, Dead.Reason)
        case dead(Dead)
    }
    
    var state: State = .idle
    
    open var viewController: UIViewController {
        fatalError("Override this getter")
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
        finish(result, source: .result, onDismissCompleted: nil)
    }
    
    public func dismiss() {
        finish(nil, source: .result, onDismissCompleted: nil)
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
               completionHandler: @escaping (Result?) -> Void) -> UIViewController {
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
            self?.finish(nil, source: .deinitialized, onDismissCompleted: nil)
        }
        
        self.state = .live(
            State.Live(
                parent: .coordinator(parent.weak),
                controller: Weak(controller),
                child: nil,
                completionHandler: { result in
                    completionHandler(result)
                }
            )
        )
        
        return controller
    }
    
    func startInternal<Result>(_ coordinator: ModalCoordinator<Result>,
                               animated: Bool,
                               completion: @escaping (Result?) -> Void,
                               onPresentCompleted: (() -> Void)?) {
        assert(coordinator !== self)
        switch self.state {
        case .live(let live):
            assert(live.child == nil)
            
            guard let presentingViewController = live.controller.value else {
                return
            }
            
            let controller = coordinator.mount(on: self, completionHandler: { result in
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
        case .idle, .dead, .liveButStagedForDeath:
            insecAssertFail(InsecurityMessage.noStartOverDead.s)
            return
        }
    }
    
    func mountOnControllerInternal(
        on parentViewController: UIViewController,
        animated: Bool,
        completion: @escaping (Result?) -> Void,
        onPresentCompleted: (() -> Void)?
    ) {
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized, onDismissCompleted: nil)
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
        case result
        case deinitialized
    }
    
    func finish(
        _ result: Result?,
        source: FinishSource,
        onDismissCompleted: (() -> Void)?
    ) {
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
        case .result:
            deadReason = .result
        case .deinitialized:
            deadReason = .deinitialized
        }
        live.controller.value?.deinitObservable.onDeinit = nil
        self.state = .liveButStagedForDeath(live, deadReason)
        
        live.completionHandler(result)
        
        let shouldDismiss: Bool
        if let child = live.child {
            shouldDismiss = child.isInLiveState
            // This means, that the child and its children are not participating in
            // this finish call chain and `self` is the topmost handler of this finishing
        } else {
            shouldDismiss = true
        }
        
        if shouldDismiss {
            self.state = .dead(State.Dead(reason: deadReason))
            live.child?.parentWillDismiss()
            
            switch live.parent {
            case .controller(let parentController):
                if
                    let presentingController = parentController.value,
                    presentingController.presentedViewController != nil
                {
                    presentingController.dismiss(animated: true) {
                        onDismissCompleted?()
                    }
                } else {
                    onDismissCompleted?()
                }
            case .coordinator(let parentCoordinator):
                if let parentCoordinator = parentCoordinator.value {
                    parentCoordinator.findFirstAliveAncestorAndCutTheChainDismissing {
                        onDismissCompleted?()
                    }
                } else {
                    onDismissCompleted?()
                }
            }
        } else {
            insecAssert(onDismissCompleted == nil, "onDismissCompleted was passed in the middle of finish chain, so it wont be called")
        }
    }
    
    func dismissChildrenInternal(animated: Bool,
                                 completion: (() -> Void)?) {
        switch self.state {
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
    func findFirstAliveAncestorAndCutTheChainDismissing(_ completion: @escaping () -> Void) {
        switch state {
        case .live(let live):
            self.state = .live(live.settingChild(to: nil))
            if
                let controller = live.controller.value,
                controller.presentedViewController != nil
            {
                controller.dismiss(animated: true) {
                    completion()
                }
            } else {
                completion()
            }
        case .liveButStagedForDeath(let live, let deadReason):
            self.state = .dead(State.Dead(reason: deadReason))
            
            switch live.parent {
            case .coordinator(let parentCoordinator):
                if let parentCoordinator = parentCoordinator.value {
                    parentCoordinator.findFirstAliveAncestorAndCutTheChainDismissing {
                        completion()
                    }
                } else {
                    completion()
                }
            case .controller(let parentController):
                if
                    let parentController = parentController.value,
                    parentController.presentedViewController != nil
                {
                    parentController.dismiss(animated: true) {
                        completion()
                    }
                } else {
                    completion()
                }
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
