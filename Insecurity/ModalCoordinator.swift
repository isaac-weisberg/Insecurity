import UIKit

open class ModalCoordinator<Result>: CommonModalCoordinator {
    enum State {
        struct Mounted {
            let controller: Weak<UIViewController>
            let host: Weak<InsecurityHost>
            let index: CoordinatorIndex
            let completion: (Result?) -> Void
        }
        
        enum Dead {
            case deinitOrKvo
            case result
            case dismountedByHost
        }
        
        case unmounted
        case mounted(Mounted)
        case dead(Dead)
    }

    var state: State = .unmounted
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    public func finish(_ result: Result) {
        self.handleFinish(result, .result)
    }
    
    public func dismiss() {
        self.handleFinish(nil, .result)
    }
    
    func dismountFromHost() {
        switch state {
        case .mounted(let mounted):
            mounted.controller.value?.deinitObservable.onDeinit = nil
            
            self.state = .dead(.dismountedByHost)
        case .dead, .unmounted:
            break
        }
    }
    
    func mountOnHostModal(_ host: InsecurityHost,
                     _ index: CoordinatorIndex,
                     completion: @escaping (Result?) -> Void) -> UIViewController {
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.handleFinish(nil, .deinitOrKvo)
        }
        
        self.state = .mounted(State.Mounted(controller: Weak(controller),
                                            host: Weak(host),
                                            index: index,
                                            completion: completion))
        return controller
    }
    
    func handleFinish(_ result: Result?, _ reason: CoordinatorDeathReason) {
        switch self.state {
        case .unmounted:
            insecAssertFail(.noFinishOnUnmounted)
        case .dead:
            insecAssertFail(.noFinishOnDead)
        case .mounted(let mounted):
            mounted.controller.value?.deinitObservable.onDeinit = nil
            
            let dead: State.Dead
            switch reason {
            case .deinitOrKvo:
                dead = .deinitOrKvo
            case .result:
                dead = .result
            }
            self.state = .dead(dead)
            
            mounted.host.value?.handleCoordinatorDied(self,
                                                      mounted.index,
                                                      reason,
                                                      result,
                                                      mounted.completion)
        }
    }
    
    public init() {
        
    }
    
    public func start<Result>(
        _ child: ModalCoordinator<Result>,
        animated: Bool,
        _ completion: @escaping (Result?) -> Void
    ) {
        startIfMounted { mounted in
            mounted.host.value.insecAssertNotNil()?.startModal(child,
                                                               after: mounted.index,
                                                               animated: animated,
                                                               completion)
        }
    }
    
    public func dismissChildren(animated: Bool) {
        switch state {
        case .mounted(let mounted):
            mounted.host.value.insecAssertNotNil()?.dismissChildren(animated: animated, after: mounted.index)
        case .dead, .unmounted:
            insecAssertFail(.noDismissChildrenOnDeadOrUnmounted)
        }
    }
    
    private func startIfMounted(_ startBlock: (State.Mounted) -> Void) {
        switch state {
        case .mounted(let mounted):
            startBlock(mounted)
        case .dead, .unmounted:
            insecAssertFail(.noStartOnDeadOrUnmounted)
        }
    }
}
