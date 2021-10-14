import UIKit

open class ModalCoordinator<Result>: CommonModalCoordinator {
    private weak var _navigation: ModalHostAny?
    
    public var navigation: ModalNavigation! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result) -> Void)?
    
    public func finish(_ result: Result) {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("`finish` called before the coordinator was started")
            return
        }
        
        _finishImplementation(result)
    }
    
    func _updateHostReference(_ host: ModalHost) {
        _navigation = host
    }
    
    public init() {
        
    }
}

class ModalCoordinatorWithNavigationHost<Result>: ModalCoordinator<Result> {
    let navigationHostChild: NavigationHost?
    weak var _storedViewController: UIViewController?
    
    override var viewController: UIViewController {
        return _storedViewController!
    }
    
    init(_ navigationHostChild: NavigationHost,
         _ _storedViewController: UIViewController?) {
        
        self.navigationHostChild = navigationHostChild
        self._storedViewController = _storedViewController
    }
}
