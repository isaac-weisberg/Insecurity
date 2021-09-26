import Insecurity

class ProductCoordinator: NavichildCoordinator<Void> {
    init() {
        super.init { navitroller, finish in
            let viewController = ProductViewController()
            
            viewController.onCartRequested = {
                let contentsCoordinator = CartCoordinator()
                
                navitroller.startChild(contentsCoordinator, animated: true) { result in
                    print("End Cart \(result)")
                }
            }
            
            return viewController
        }
    }
}
