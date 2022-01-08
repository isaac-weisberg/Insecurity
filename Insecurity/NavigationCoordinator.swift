import UIKit

open class NavigationCoordinator<Result>: CommonNavigationCoordinator {
    private var _navigation: (NavigationControllerNavigation & AdaptiveNavigation)?
    
    public var navigation: (NavigationControllerNavigation & AdaptiveNavigation)! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result?) -> Void)?
    var _abortChildrenImplementation: (((() -> Void)?) -> Void)?
    
    public func finish(_ result: Result) {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`finish` called before the coordinator was started")
            return
        }
        
        _finishImplementation(result)
    }
    
    public func dismiss() {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`dismiss` called before the coordinator was started")
            return
        }
        
        _finishImplementation(nil)
    }
    
    func _updateHostReference(_ host: NavigationControllerNavigation & AdaptiveNavigation) {
        _navigation = host
    }
    
    public init() {
        
    }
    
    public func abortChildren(_ completion: (() -> Void)?) {
        guard let _abortChildrenImplementation = _abortChildrenImplementation else {
            assertionFailure("`abortChildren` called before the coordinator was started")
            return
        }
            
        _abortChildrenImplementation {
            completion?()
        }
    }
}
