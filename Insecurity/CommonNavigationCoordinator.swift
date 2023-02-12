import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonNavigationCoordinatorAny: CommonCoordinatorAny {
    
}

protocol CommonNavigationCoordinator: CommonNavigationCoordinatorAny {
    associatedtype Result
    
    func mountOnHostNavigation(_ host: InsecurityHost,
                               _ index: CoordinatorIndex,
                               completion: @escaping (Result?) -> Void) -> UIViewController
    
    func dismountFromHost()
}
