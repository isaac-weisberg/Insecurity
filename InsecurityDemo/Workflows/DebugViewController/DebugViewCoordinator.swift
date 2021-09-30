import Insecurity

class DebugViewCoordinator: ModachildCoordinator<Void> {
    typealias DI = DebugViewController.DI
    
    init(di: DI) {
        super.init { _, finish in
            let viewController = DebugViewController(di: di)
            
            viewController.onClose = { finish (()) }
            
            return viewController
        }
    }
}
