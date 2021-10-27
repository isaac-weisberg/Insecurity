import Insecurity
import UIKit

class KVOCoordinator: ModalCoordinator<Void> {
    override var viewController: UIViewController {
        let vc = KVOVC()
        
        // ALPHA EXPERIMENT
//        DispatchQueue.main.asyncAfter(10) {
//            _ = vc
//        }
        
        return vc
    }
}
