import Insecurity
import UIKit

class GalleryCoordinator: NavigationCoordinator<Void> {
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
//            let modalHost = ModalHost(galleryViewController)
//            self.customModalHost = modalHost
//
//            let paymentMethodCoordinator = PaymentMethodCoordinator()
//
//            modalHost.start(paymentMethodCoordinator, animated: true) { result in
//                self.customModalHost = nil
//                // result is PaymentMethodScreenResult
//            }
//        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let genericCoordinator = GenericCoordinator(
                .start(
                    GenericCoordinator(.start(
                            GenericCoordinator(.startNavigation(
                                    GenericCoordinator(.start(
                                            GenericCoordinator(.start(
                                                    GenericCoordinator(.startModal(
                                                            GenericCoordinator(.start(
                                                                GenericCoordinator(.startNavigation(
                                                                    GenericCoordinator(.start(
                                                                        GenericCoordinator(.start(
                                                                            GenericCoordinator(.startNavigation(
                                                                                GenericCoordinator(.start(
                                                                                    GenericCoordinator(.startModal(
                                                                                            GenericCoordinator(.start(
                                                                                                GenericCoordinator(.startNavigation(
                                                                                                    GenericCoordinator(.start(
                                                                                                        GenericCoordinator(.start(
                                                                                                            GenericCoordinator(.startNavigation(
                                                                                                                GenericCoordinator(.start(
                                                                                                                    GenericCoordinator(.nothing)
                                                                                                                ))
                                                                                                            ))
                                                                                                        ))
                                                                                                    ))
                                                                                                ))
                                                                                            ))
                                                                                        ), .nothing)
                                                                                ), .nothing)
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
                print("End GenericCoordinator root \(result)")
            }
        }
        
        return galleryViewController
    }
    
    var customModalHost: ModalHostAny?
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
