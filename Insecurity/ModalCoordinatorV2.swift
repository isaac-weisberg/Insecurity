import Foundation
import UIKit

open class ModalCoordinatorV2<Result> {
    enum State {
        struct Mounted {
            let host: InsecurityHostV2
            let controller: Weak<UIViewController>
        }
        
        case idle
        case mounted(Mounted)
    }
    
    var state: State = .idle
    var completionHandler: ((Result?) -> Void)?
    private var child: ModalCoordinatorV2?
    
    open var viewController: UIViewController {
        fatalError("Override this getter")
    }
    
    public init() {
        
    }
    
//    func mount(on host: InsecurityHostV2,
//               presetingController: UIViewController,
//               animated: Bool) -> UIViewController {
//        switch state {
//        case .idle:
//            break
//        case .mounted:
//            fatalError("Can not reuse a controller that is already in use")
//        }
//
//        let controller = self.viewController
//
//        self.state = .mounted(State.Mounted(host: host,
//                                            controller: Weak(controller)))
//
//        presetingController
//    }
    
    public func start<Result>(_ coordinator: ModalCoordinatorV2<Result>,
                              animated: Bool,
                              _ completion: @escaping (Result?) -> Void) {
        let presentingViewController: UIViewController
        switch self.state {
        case .mounted(let mounted):
            guard let existingViewController = mounted.controller.value else {
                return
            }
            presentingViewController = existingViewController
        case .idle:
            assertionFailure("Can not start on an unmounted coordinator")
            return
        }
        assert(child == nil)
        let controller = coordinator.viewController
        
        coordinator.completionHandler = { result in
            completion(result)
        }
        
        presentingViewController.present(controller, animated: animated)
    }
    
    public func finish(_ result: Result?) {
        completionHandler?(result)
    }
}
