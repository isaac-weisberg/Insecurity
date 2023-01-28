import UIKit

open class NavigationCoordinator<Result>: CommonNavigationCoordinator {
    enum State {
        struct Mounted {
            let host: Weak<InsecurityHost>
            let controller: Weak<UIViewController>
            let index: CoordinatorIndex
            let completion: (Result?) -> Void
        }
        
        case unmounted
        case mounted(Mounted)
        case dead(CoordinatorDeathReason)
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
            
            self.state = .dead(deathReason)
            
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
