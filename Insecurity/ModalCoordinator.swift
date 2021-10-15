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
    
    func internalFinish(_ result: CoordinatorResult<Result>) {
        switch result {
        case .normal(let result):
            finish(result)
        case .dismissed:
            dismiss()
        }
    }
    
    init(_ navigationHostChild: NavigationHost,
         _ _storedViewController: UIViewController?) {
        
        self.navigationHostChild = navigationHostChild
        self._storedViewController = _storedViewController
    }
}
