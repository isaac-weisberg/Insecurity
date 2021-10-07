import UIKit

protocol NavichildCoordinatorAny: AnyObject {
    
}

open class NavichildCoordinator<Result>: NavichildCoordinatorAny {
    weak var _navitroller: NavitrollerCoordinatorAny?
    
    public var navitroller: NavitrollerCoordinatorAny! {
        assert(_navitroller != nil, "Attempted to use navitroller before the coordinator was started or after it has finished")
        return _navitroller
    }
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    var _finishImplementation: ((Result) -> Void)?
    
    public func finish(_ result: Result) {
        guard let _finishImplementation = _finishImplementation else {
            assertionFailure("Finish called before the coordinator was started")
            return
        }
        
        _finishImplementation(result)
    }
    
    public init() {
        
    }
}

class NavichildMagicCoordinator<Result>: NavichildCoordinator<Result> {
    let child: InsecurityChild<Result>
    
    override var _navitroller: NavitrollerCoordinatorAny? {
        get {
            guard let navitroller = child.navigation as? NavitrollerCoordinatorAny else {
                assertionFailure("Insecurity child was operating in the semantics of Navitroller before, but now it doesn't")
                return nil
            }
            return navitroller
        }
        set {
            child._navigation = newValue
        }
    }
    
    override var _finishImplementation: ((Result) -> Void)? {
        get {
            return child._finishImplementation
        }
        set {
            child._finishImplementation = newValue
        }
    }
    
    override var viewController: UIViewController {
        child.viewController
    }
    
    init(_ child: InsecurityChild<Result>) {
        self.child = child
    }
}
