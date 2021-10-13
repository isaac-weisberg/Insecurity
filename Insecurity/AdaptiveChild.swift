import UIKit

open class AdaptiveChild<Result>: CommonNavigationChild, CommonModalChild {
    private weak var _navigation: AdaptiveNavigation?
    
    public var navigation: AdaptiveNavigation! {
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
    
    
    func _updateHostReference(_ host: NavigationCoordinator) {
        _navigation = host
    }
    
    func _updateHostReference(_ host: ModalCoordinator) {
        _navigation = host
    }
    
    public init() {
        
    }
}
