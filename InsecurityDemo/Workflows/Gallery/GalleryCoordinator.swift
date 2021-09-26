import Insecurity

class GalleryCoordinator: NavichildCoordinator<Void> {
    init() {
        super.init { navitroller, finish in
            let galleryViewController = GalleryViewController(nibName: nil, bundle: nil)
            
            galleryViewController.onProductRequested = {
                let productCoordinator = ProductCoordinator()
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
