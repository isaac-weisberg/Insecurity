import Insecurity

class GalleryCoordinator: NavichildCoordinator<Void> {
    typealias DI = ProductCoordinator.DI
    
    init(di: DI) {
        super.init { navitroller, finish in
            let galleryViewController = GalleryViewController(nibName: nil, bundle: nil)
            
            galleryViewController.onProductRequested = {
                let productCoordinator = ProductCoordinator(di: di)
                navitroller.startChild(productCoordinator, animated: true) { result in
                    print("End Product \(result)")
                }
            }
            
            galleryViewController.onAltButton = {
                finish(())
            }
            
            return galleryViewController
        }
    }
}
