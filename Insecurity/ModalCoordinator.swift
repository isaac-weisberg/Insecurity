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
            case byDeinit
            case byKVO
            case byResult
        }
        
        case unmounted
        case mounted(Mounted)
        case dead(Dead)
    }

    private var state: State = .unmounted
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    public func finish(_ result: Result) {
        self.handleFinish(result, .byResult)
    }
    
    public func dismiss() {
        self.handleFinish(nil, .byResult)
    }
    
    func mountOnHostModal(_ host: InsecurityHost,
                     _ index: CoordinatorIndex,
                     completion: @escaping (Result?) -> Void) -> UIViewController {
        let controller = self.viewController
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.handleFinish(nil, .byDeinit)
        }
        
        self.state = .mounted(State.Mounted(controller: Weak(controller),
                                            host: Weak(host),
                                            index: index,
                                            completion: completion))
        return controller
    }
    
    func handleFinish(_ result: Result?, _ reason: State.Dead) {
        switch self.state {
        case .unmounted:
            insecAssertFail(.noFinishOnUnmounted)
        case .dead:
            insecAssertFail(.noFinishOnDead)
        case .mounted(let mounted):
            mounted.controller.value?.deinitObservable.onDeinit = nil
            
            self.state = .dead(reason)
            
            let deadReason: CoordinatorDeathReason
            switch reason {
            case .byResult:
                deadReason = .result
            case .byDeinit, .byKVO:
                deadReason = .deinitOrKvo
            }
            
            mounted.host.value?.handleCoordinatorDied(self,
                                                      mounted.index,
                                                      deadReason,
                                                      result,
                                                      mounted.completion)
        }
    }
    
    public init() {
        
    }
    
    func start<Result>(
        _ child: ModalCoordinator<Result>,
        animated: Bool,
        _ completion: @escaping (Result?) -> Void
    ) {
        switch state {
        case .mounted(let mounted):
            mounted.host.value.insecAssertNotNil()?.startModal(child,
                                                               after: mounted.index,
                                                               animated: animated,
                                                               completion)
        case .dead, .unmounted:
            insecAssertFail(.noStartOnDeadOrUnmounted)
        }
    }
}
