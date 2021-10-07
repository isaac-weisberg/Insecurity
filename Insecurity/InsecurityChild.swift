import UIKit

protocol InsecurityChildAny {
    var navigation: InsecurityNavigation! { get }
}

open class InsecurityChild<Result>: InsecurityChildAny {
    weak var _navigation: InsecurityNavigation?
    
    public var navigation: InsecurityNavigation! {
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
    
    public init() {
        
    }
}
