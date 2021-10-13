import UIKit

open class NavigationChild<Result>: CommonChild<Result> {
    weak var _navigation: NavigationControllerNavigation?
    
    public var navigation: NavigationControllerNavigation! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    public override init() {
        super.init()
    }
}
