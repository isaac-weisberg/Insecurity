import UIKit

open class ModalChild<Result>: CommonChild<Result> {
    weak var _navigation: ModalCoordinatorAny?
    
    public var navigation: ModalNavigation! {
        assert(_navigation != nil, "Attempted to use `navigation` before the coordinator was started or after it has finished")
        return _navigation
    }
    
    public override init() {
        super.init()
    }
}
