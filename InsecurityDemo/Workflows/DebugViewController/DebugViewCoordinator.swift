import Insecurity
import UIKit

class DebugViewCoordinator: InsecurityChild<Void> {
    typealias DI = DebugViewController.DI
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
    
    override var viewController: UIViewController {
        let viewController = DebugViewController(di: di)
        
        viewController.onClose = { self.finish(()) }
        
        return viewController
    }
}
