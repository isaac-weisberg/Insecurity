import UIKit

open class ModalCoordinator<Result>: CommonModalCoordinator {
    private weak var _navigation: ModalNavigation?
    
    public var navigation: ModalNavigation! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result?) -> Void)?
    
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
    
    func _updateHostReference(_ host: ModalHost) {
        _navigation = host
    }
    
    public init() {
        
    }
}

protocol ModalCoordinatorWithNavigationHostAny {
    var navigationHostChild: NavigationHost? { get }
}

class ModalCoordinatorWithNavigationHost<Result>: ModalCoordinator<Result>, ModalCoordinatorWithNavigationHostAny {
    let navigationHostChild: NavigationHost?
    weak var _storedViewController: UIViewController?
    
    override var viewController: UIViewController {
        return _storedViewController!
    }
    
    func internalFinish(_ result: Result?) {
        switch result {
        case .some(let result):
            finish(result)
        case .none:
            dismiss()
        }
    }
    
    init(_ navigationHostChild: NavigationHost,
         _ _storedViewController: UIViewController?) {
        
        self.navigationHostChild = navigationHostChild
        self._storedViewController = _storedViewController
    }
}
