import UIKit

open class ModalChild<Result>: CommonModalChild {
    private weak var _navigation: ModalCoordinatorAny?
    
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
    
    func _updateHostReference(_ host: ModalCoordinator) {
        _navigation = host
    }
    
    public init() {
        
    }
}

class ModalChildWithNavigationCoordinator<Result>: ModalChild<Result> {
    let navigationCoordinatorChild: NavigationCoordinator?
    weak var _storedViewController: UIViewController?
    
    override var viewController: UIViewController {
        return _storedViewController!
    }
    
    init(_ navigationCoordinatorChild: NavigationCoordinator,
         _ _storedViewController: UIViewController?) {
        
        self.navigationCoordinatorChild = navigationCoordinatorChild
        self._storedViewController = _storedViewController
    }
}
