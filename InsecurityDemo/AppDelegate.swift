import UIKit
import Insecurity

@main class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
//
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
//    ) -> Bool {
//
//        let window = UIWindow(frame: UIScreen.main.bounds)
//        self.window = window
//
//
//        let navigationController = UINavigationController()
//        navigationController.interactivePopGestureRecognizer?.isEnabled = true
//
//        window.rootViewController = navigationController
//
//        let coordinator = NavitrollerCoordinator(navigationController)
//        let galleryCoordinator = GalleryCoordinator()
//
//        coordinator.startChild(galleryCoordinator, animated: false) { result in
//            print("End Gallery \(result)")
//        }
//
//        window.makeKeyAndVisible()
//
//        return true
//    }
    
    
    var modalCoordinator: ModarollerCoordinator?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let rootViewController = UIViewController()
        rootViewController.view.backgroundColor = .white

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()

        let coordinator = ModarollerCoordinator(rootViewController)
        modalCoordinator = coordinator
        let galleryCoordinator = GalleryModalCoordinator()

        coordinator.startChild(galleryCoordinator, animated: false) { result in
            print("End Gallery \(result)")
            self.modalCoordinator = nil
        }

        return true
    }
}

class GalleryViewController: UIViewController {
    var onProductRequested: (() -> Void)?
    var onKillMyself: (() -> Void)?
    
    let button = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Dieeeee", for: .normal)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onProductRequested?()
        }
    }
    
    @objc func onTap() {
        onKillMyself?()
    }
}

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
            
            galleryViewController.onKillMyself = {
                finish(())
            }
            
            return galleryViewController
        }
    }
}

class GalleryModalCoordinator: ModachildCoordinator<Void> {
    init() {
        super.init { modaroller, finish in
            let galleryViewController = GalleryViewController(nibName: nil, bundle: nil)
            
            galleryViewController.onProductRequested = {
                let productCoordinator = ProductModalCoordinator()
                modaroller.startChild(productCoordinator, animated: true) { result in
                    print("End Product \(result)")
                }
            }
            
            galleryViewController.onKillMyself = {
                finish(())
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

class ProductModalCoordinator: ModachildCoordinator<Void> {
    init() {
        super.init { modaroller, finish in
            let viewController = ProductViewController()
            
            viewController.onContentsRequested = {
                let cartCoordinator = CartModalCoordinator()
                
                modaroller.startChild(cartCoordinator, animated: true) { result in
                    print("End Cart \(result)")
                    switch result {
                    case .dismissed:
                        finish(())
                    case .normal:
                        finish(())
                    }
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
                    print("End Payment \(result)")
                    finish(())
                }
            }
            return cartViewController
        }
    }
}

class CartModalCoordinator: ModachildCoordinator<Void> {
    init() {
        super.init { modaroller, finish in
            let cartViewController = CartViewController()
            cartViewController.onPayRequested = {
                let paymentCoordinator = PaymentModalCoordinator()
                
                modaroller.startChild(paymentCoordinator, animated: true) { result in
                    print("End Payment \(result)")
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

class PaymentModalCoordinator: ModachildCoordinator<Void> {
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
