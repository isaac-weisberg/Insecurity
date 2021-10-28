import Insecurity
import UIKit

class KVOCoordinator: NavigationCoordinator<Void> {
    override var viewController: UIViewController {
        let vc = KVOVC()
        
        // ALPHA EXPERIMENT
//        DispatchQueue.main.asyncAfter(10) {
//            _ = vc
//        }
        
        return vc
    }
}
