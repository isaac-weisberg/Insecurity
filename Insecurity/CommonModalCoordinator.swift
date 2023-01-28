import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonModalCoordinatorAny: CommonCoordinatorAny {
    
}

protocol CommonModalCoordinator: CommonModalCoordinatorAny {
    associatedtype Result
    
    func mountOnHostModal(_ host: InsecurityHost,
                          _ index: CoordinatorIndex,
                          completion: @escaping (Result?) -> Void) -> UIViewController
}
