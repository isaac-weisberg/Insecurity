import Insecurity
import UIKit

class GalleryCoordinator: NavigationChild<Void> {
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
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            let modalCoordinator = ModalCoordinator(galleryViewController)
//            self.customModalCoordinator = modalCoordinator
//
//            let paymentMethodCoordinator = PaymentMethodCoordinator()
//
//            modalCoordinator.start(paymentMethodCoordinator, animated: true) { result in
//                self.customModalCoordinator = nil
//                // result is PaymentMethodScreenResult
//            }
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let genericCoordinator = GenericChild(
                .start(
                    GenericChild(.start(
                            GenericChild(.startNavigation(
                                    GenericChild(.start(
                                            GenericChild(.start(
                                                    GenericChild(.startModal(
                                                            GenericChild(.start(
                                                                GenericChild(.startNavigation(
                                                                    GenericChild(.start(
                                                                        GenericChild(.start(
                                                                            GenericChild(.startNavigation(
                                                                                GenericChild(.start(
                                                                                    GenericChild(.finish)
                                                                                ))
                                                                            ))
                                                                        ))
                                                                    ))
                                                                ))
                                                            ), .nothing)
                                                        ))
                                                ))
                                    ))
                                ))
                        ))
                ))

            self.navigation.start(genericCoordinator, animated: true) { result in
                print("End GenericChild root \(result)")
            }
        }
        
        return galleryViewController
    }
    
    var customModalCoordinator: ModalCoordinatorAny?
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
