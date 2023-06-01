import UIKit

open class NavigationCoordinator<Result>: CommonNavigationCoordinator {
    enum State {
        struct Mounted {
            let host: Weak<InsecurityHost>
            let controller: Weak<UIViewController>
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
        handleFinish(result, deathReason: .result)
    }
    
    public func dismiss() {
        handleFinish(nil, deathReason: .result)
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
    
    func mountOnHostNavigation(_ host: InsecurityHost,
                     _ index: CoordinatorIndex,
                     completion: @escaping (Result?) -> Void) -> UIViewController {
        let controller = self.viewController
        
        
        controller.deinitObservable.onDeinit = { [weak self] in
            self?.handleFinish(nil, deathReason: .deinitOrKvo)
        }
        
        self.state = .mounted(State.Mounted(host: Weak(host),
                                            controller: Weak(controller),
                                            index: index,
                                            completion: completion))
        
        
        return controller
    }
    
    func handleFinish(_ result: Result?, deathReason: CoordinatorDeathReason) {
        switch state {
        case .mounted(let mounted):
            mounted.controller.value?.deinitObservable.onDeinit = nil
            
            let dead: State.Dead
            switch deathReason {
            case .result:
                dead = .result
            case .deinitOrKvo:
                dead = .deinitOrKvo
            }
            self.state = .dead(dead)
            
            mounted.host.value?.handleCoordinatorDied(self,
                                                      mounted.index,
                                                      deathReason,
                                                      result,
                                                      mounted.completion)
        case .dead:
            insecAssertFail(InsecurityLog.noFinishOnDead)
        case .unmounted:
            insecAssertFail(InsecurityLog.noFinishOnUnmounted)
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
    
    public func start<Result>(
        _ child: NavigationCoordinator<Result>,
        animated: Bool,
        _ completion: @escaping (Result?) -> Void
    ) {
        startIfMounted { mounted in
            mounted.host.value.insecAssertNotNil()?.startNavigation(child,
                                                                    after: mounted.index,
                                                                    animated: animated,
                                                                    completion)
        }
    }
    
    public func start<Result>(
        _ navigationController: UINavigationController,
        _ child: NavigationCoordinator<Result>,
        animated: Bool,
        _ completion: @escaping (Result?) -> Void
    ) {
        startIfMounted { mounted in
            mounted.host.value.insecAssertNotNil()?.startNavigationNew(
                navigationController,
                child,
                after: mounted.index,
                animated: animated,
                completion
            )
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
