import Insecurity
import UIKit

class GalleryCoordinator: InsecurityChild<Void> {
    typealias DI = ProductCoordinator.DI
    
    override var viewController: UIViewController {
        let galleryViewController = GalleryViewController(nibName: nil, bundle: nil)
        
        galleryViewController.onProductRequested = { [self] in
            let productCoordinator = ProductCoordinator(di: di)
            navigation.start(productCoordinator, animated: true) { result in
                print("End Product \(result)")
            }
        }
        
        galleryViewController.onAltButton = { [self] in
            finish(())
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let modaroller = ModarollerCoordinator(galleryViewController)
            
            let currencySelectionCoordinator = CurrencySelectionCoordinator()
            
            self.customModaroller = modaroller
            
            modaroller.start(currencySelectionCoordinator, animated: true) { result in
                self.customModaroller = nil
                switch result {
                case .normal(let currencySelection):
                    break
                case .dismissed:
                    break
                }
            }
        }
        
        return galleryViewController
    }
    
    var customModaroller: ModarollerCoordinatorAny?
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
