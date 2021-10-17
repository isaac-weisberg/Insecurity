import UIKit

open class NavigationCoordinator<Result>: CommonNavigationCoordinator {
    private var _navigation: NavigationControllerNavigation?
    
    public var navigation: NavigationControllerNavigation! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((CoordinatorResult<Result>) -> Void)?
    
    public func finish(_ result: Result) {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`finish` called before the coordinator was started")
            return
        }
        
        _finishImplementation(.normal(result))
    }
    
    public func dismiss() {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`dismiss` called before the coordinator was started")
            return
        }
        
        _finishImplementation(.dismissed)
    }
    
    func _updateHostReference(_ host: NavigationHost) {
        _navigation = host
    }
    
    public init() {
        
    }
}
