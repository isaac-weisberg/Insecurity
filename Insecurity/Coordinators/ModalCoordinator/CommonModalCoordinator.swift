import UIKit

// This protocol exists purely for AnyObject
// and is not supposed to declare any members
protocol CommonModalCoordinatorAny: CommonCoordinatorAny {
    
}

protocol CommonModalCoordinator: CommonModalCoordinatorAny {
    associatedtype Result
    
    func bindToHost(_ navigation: ModalNavigation,
                    _ onFinish: @escaping (Result?, FinalizationKind) -> Void) -> UIViewController
}
