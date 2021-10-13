import UIKit

open class InsecurityChild<Result>: CommonChild<Result> {
    weak var _navigation: InsecurityNavigation?
    
    public var navigation: InsecurityNavigation! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    public override init() {
        super.init()
    }
}

class InsecurityChildWithNavigationCoordinator<Result>: InsecurityChild<Result> {
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
