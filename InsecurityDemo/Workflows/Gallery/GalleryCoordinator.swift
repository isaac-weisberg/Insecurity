import Insecurity
import UIKit

class GalleryCoordinator: NavichildCoordinator<Void> {
    typealias DI = ProductCoordinator.DI
    
    override var viewController: UIViewController {
        let galleryViewController = GalleryViewController(nibName: nil, bundle: nil)
        
        galleryViewController.onProductRequested = { [self] in
            let productCoordinator = ProductCoordinator(di: di)
            navitroller.startChild(productCoordinator, animated: true) { result in
                print("End Product \(result)")
            }
        }
        
        galleryViewController.onAltButton = { [self] in
            finish(())
        }
        
        return galleryViewController
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
