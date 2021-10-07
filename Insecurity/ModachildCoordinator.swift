import UIKit

protocol ModachildCoordinatorAny: AnyObject {
    
}

open class ModachildCoordinator<Result>: ModachildCoordinatorAny {
    weak var _modaroller: ModarollerCoordinatorAny?
    
    public var modaroller: ModarollerCoordinatorAny! {
        assert(_modaroller != nil, "Attempted to use modaroller before the coordinator was started or after it has finished")
        return _modaroller
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

class ModachildMagicCoordinator<Result>: ModachildCoordinator<Result> {
    let child: InsecurityChild<Result>
    
    override var modaroller: ModarollerCoordinatorAny? {
        guard let modaroller = child._navigation as? ModarollerCoordinatorAny else {
            assertionFailure("Insecurity child was operating in the semantics of Modaroller before, but now it doesn't")
            return nil
        }
        return modaroller
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
        return child.viewController
    }
    
    init(_ child: InsecurityChild<Result>) {
        self.child = child
        super.init()
        self._finishImplementation = child._finishImplementation
    }
}

class ModachildWithNavitroller<Result>: ModachildCoordinator<Result> {
    let navitrollerChild: NavitrollerCoordinator?
    weak var _storedViewController: UIViewController?
    
    override var viewController: UIViewController {
        return _storedViewController!
    }
    
    init(_ navitrollerChild: NavitrollerCoordinator,
         _ _storedViewController: UIViewController?) {
        
        self.navitrollerChild = navitrollerChild
        self._storedViewController = _storedViewController
    }
}
