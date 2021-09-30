import Insecurity

class ProductCoordinator: NavichildCoordinator<Void> {
    typealias DI = CartCoordinator.DI
    
    init(di: DI) {
        super.init { navitroller, finish in
            let viewController = ProductViewController()
            
            viewController.onCartRequested = {
                let contentsCoordinator = CartCoordinator(di: di)
                
                navitroller.startChild(contentsCoordinator, animated: true) { result in
                    print("End Cart \(result)")
                }
            }
            
            return viewController
        }
    }
}
