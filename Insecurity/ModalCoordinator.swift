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
            self?.finish(nil, source: .deinitialized, onDismissCompleted: nil)
        }
        
        self.state = .live(
            State.Live(
                parent: .coordinator(parent.weak),
                controller: Weak(controller),
                child: nil
            )
        )
        
        return controller
    }
    
    func startInternal<Result>(_ coordinator: ModalCoordinator<Result>,
                               animated: Bool,
                               completion: @escaping (Result?) -> Void,
                               onPresentCompleted: (() -> Void)?) {
        switch self.state {
        case .live(let live):
            assert(live.child == nil)
            
            guard let presentingViewController = live.controller.value else {
                return
            }
            
            let controller = coordinator.mount(on: self)
            
            coordinator.completionHandler = { result in
                completion(result)
            }
            
            presentingViewController.present(
                controller,
                animated: animated,
                completion: {
                    onPresentCompleted?()
                }
            )
            
            self.state = .live(State.Live(
                parent: live.parent,
                controller: live.controller,
                child: coordinator
            ))
            
        case .idle, .dead:
            insecAssertFail("Can not start on an unmounted coordinator")
            return
        }
    }
    
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
    
    func mountInternal(on parentViewController: UIViewController,
                       animated: Bool,
                       completion: @escaping (Result?) -> Void,
                       onPresentCompleted: (() -> Void)?) {
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.finish(nil, source: .deinitialized, onDismissCompleted: nil)
        }
        
        self.state = .live(
            State.Live(
                parent: .controller(Weak(parentViewController)),
                controller: Weak(controller),
                child: nil
            )
        )
        
        self.completionHandler = { result in
            completion(result)
        }
        
        parentViewController.present(controller, animated: animated, completion: {
            onPresentCompleted?()
        })
    }
    
    public func mount(on parentViewController: UIViewController,
                      animated: Bool,
                      completion: @escaping (Result?) -> Void,
                      onPresentCompleted: @escaping () -> Void) {
        mountInternal(
            on: parentViewController,
            animated: animated,
            completion: completion,
            onPresentCompleted: onPresentCompleted
        )
    }
    
    public func mount(on parentViewController: UIViewController,
                      animated: Bool,
                      completion: @escaping (Result?) -> Void) {
        mountInternal(
            on: parentViewController,
            animated: animated,
            completion: completion,
            onPresentCompleted: nil
        )
    }
    
    enum FinishSource {
        case result
        case deinitialized
    }
    
    public func finish(_ result: Result) {
        finish(result, source: .result, onDismissCompleted: nil)
    }
    
    public func dismiss() {
        finish(nil, source: .result, onDismissCompleted: nil)
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
            if let parent = parentCoordinator.value {
                parent.childWillUnmount()
                if
                    !parent.isInDeadState,
                    let instantiatedParentController = parent.instantiatedViewController,
                    instantiatedParentController.presentedViewController != nil
                {
                    instantiatedParentController.dismiss(animated: true) {
                        onDismissCompleted?()
                    }
                } else {
                    onDismissCompleted?()
                }
            } else {
                onDismissCompleted?()
            }
        }
    }
    
    public func dismissChildren(animated: Bool) {
        
    }
    
    public func dismissChildren(animated: Bool,
                                completion: @escaping () -> Void) {
        switch self.state {
        case .idle, .dead:
            completion()
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
                    completion()
                })
            } else {
                completion()
            }
        }
    }
}

extension ModalCoordinator: CommonModalCoordinator {
    func childWillUnmount() {
        switch self.state {
        case .live(let live):
            let newLive = live.settingChild(to: nil)
            self.state = .live(newLive)
        case .dead, .idle:
            break
        }
    }
    
    var instantiatedViewController: UIViewController? {
        switch state {
        case .live(let live):
            return live.controller.value
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
        case .live(let live):
            self.state = .dead(.dismissedByParent)
            live.child?.parentWillDismiss()
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

extension ModalCoordinator.State.Live {
    func settingChild(to child: CommonModalCoordinator?) -> ModalCoordinator.State.Live {
        ModalCoordinator.State.Live(parent: self.parent,
                                    controller: self.controller,
                                    child: child)
    }
}

//@available(iOS 13, *)
//public extension ModalCoordinator {
//    func start<Result>(_ coordinator: ModalCoordinator<Result>,
//                       animated: Bool) async -> Result? {
//        return await withCheckedContinuation { continuation in
//            self.startInternal(coordinator,
//                               animated: animated,
//                               completion: continuation.resume(returning:),
//                               onPresentCompleted: nil)
//        }
//    }
//
//    struct StartAwaitables {
//        let completed: Task<Result?, Never>
//        let presentCompleted: Task<Void, Never>
//    }
//
//    func start<Result>(_ coordinator: ModalCoordinator<Result>,
//                       animated: Bool) async -> StartAwaitables {
//        let onPresentCompletedTask = Task<Void, Never>()
//
//
//
//        startInternal(T##coordinator: ModalCoordinator<Result>##ModalCoordinator<Result>
//, animated: T##Bool, completion: T##(Result?) -> Void
//, onPresentCompleted: T##(() -> Void)?##(() -> Void)?##() -> Void)
//    }
//}
