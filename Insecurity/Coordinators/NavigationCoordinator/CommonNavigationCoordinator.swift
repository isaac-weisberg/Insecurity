import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonNavigationCoordinatorAny: CommonCoordinatorAny {
    
}

protocol CommonNavigationCoordinator: CommonNavigationCoordinatorAny {
    associatedtype Result
    
    func bindToHost(_ navigation: NavigationControllerNavigation,
                    _ onFinish: @escaping (Result?, FinalizationKind) -> Void) -> UIViewController
}
