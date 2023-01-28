import UIKit

open class AdaptiveCoordinator<Result>: CommonNavigationCoordinator, CommonModalCoordinator {
    func mountOnHostNavigation(_ host: InsecurityHost, _ index: CoordinatorIndex, completion: @escaping (Result?) -> Void) -> UIViewController {
        fatalError()
    }
    
    func mountOnHostModal(_ host: InsecurityHost, _ index: CoordinatorIndex, completion: @escaping (Result?) -> Void) -> UIViewController {
        fatalError()
    }
    
    
    open var viewController: UIViewController {
        fatalError("This coordinator didn't define a viewController")
    }
    
    public func finish(_ result: Result) {
        
    }
    
    public func dismiss() {
        
    }
    
    public init() {
        
    }
}
