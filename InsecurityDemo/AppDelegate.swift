import UIKit
import Insecurity

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let navigationController = UINavigationController()
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        
        window.rootViewController = navigationController
        
        let coordinator = NavitrollerCoordinator(navigationController)
        let galleryCoordinator = GalleryCoordinator()
        
        coordinator.startChild(galleryCoordinator, animated: false) { never in
            
        }
        
        window.makeKeyAndVisible()
        
        return true
    }
}

class GalleryViewController: UIViewController {
    var onProductRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onProductRequested?()
        }
    }
}

class GalleryCoordinator: NavichildCoordinator<Never> {
    init() {
        super.init { navitroller, _ in
            let galleryViewController = GalleryViewController(nibName: nil, bundle: nil)
            
            galleryViewController.onProductRequested = {
                let productCoordinator = ProductCoordinator()
                navitroller.startChild(productCoordinator, animated: true) { result in
                    print("End Product \(result)")
                }
            }
            return galleryViewController
        }
    }
}

class ProductViewController: UIViewController {
    var onContentsRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onContentsRequested?()
        }
    }
}

class ProductCoordinator: NavichildCoordinator<Void> {
    init() {
        super.init { navitroller, finish in
            let viewController = ProductViewController()
            
            viewController.onContentsRequested = {
                let contentsCoordinator = CartCoordinator()
                
                navitroller.startChild(contentsCoordinator, animated: true) { result in
                    print("End Cart \(result)")
//                    switch result {
//                    case .dismissed:
//                        finish(())
//                    case .normal:
//                        finish(())
//                    }
                }
            }
            
            return viewController
        }
    }
}

class CartViewController: UIViewController {
    var onPayRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onPayRequested?()
        }
    }
}


class CartCoordinator: NavichildCoordinator<Void> {
    init() {
        super.init { navitroller, finish in
            let cartViewController = CartViewController()
            cartViewController.onPayRequested = {
                let paymentCoordinator = PaymentCoordinator()
                
                navitroller.startChild(paymentCoordinator, animated: true) { result in
                    print("End Payment")
                    finish(())
                }
            }
            return cartViewController
        }
    }
}

class PaymentViewController: UIViewController {
    var onFinish: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onFinish?()
        }
    }
}

class PaymentCoordinator: NavichildCoordinator<Void> {
    init() {
        super.init { _, finish in
            let paymentViewController = PaymentViewController()
            paymentViewController.onFinish = {
                finish(())
            }
            return paymentViewController
        }
    }
}
