import UIKit

open class ModalCoordinator<Result>: CommonModalCoordinator {
    private weak var _navigation: (ModalNavigation & AdaptiveNavigation)?
    
    public var navigation: (ModalNavigation & AdaptiveNavigation)! {
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
    
    func _updateHostReference(_ host: ModalNavigation & AdaptiveNavigation) {
        _navigation = host
    }
    
    public init() {
        
    }
}
