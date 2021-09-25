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
    
    func start() {
        
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
                let contentsCoordinator = ContentsCoordinator()
                
                navitroller.startChild(contentsCoordinator, animated: true) { result in
                    print("End Contents \(result)")
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


class ContentsViewController: UIViewController {
    var onFinishRequested: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemYellow
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.onFinishRequested?()
        }
    }
}


class ContentsCoordinator: NavichildCoordinator<Void> {
    init() {
        super.init { _, finish in
            let contentsViewController = ContentsViewController()
            contentsViewController.onFinishRequested = {
                finish(())
            }
            return contentsViewController
        }
    }
}
