import Insecurity
import UIKit

class ScoringCoordinator: ModalChild<Void> {
    typealias DI = LoginSMSCodeViewController.DI
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
    
    override var viewController: UIViewController {
        let di = self.di
        let phoneViewController = LoginPhoneViewController()
        
        let navigationController = UINavigationController(rootViewController: phoneViewController)
        
        phoneViewController.onSmsCodeSent = { [unowned navigationController, unowned phoneViewController] in
            let smsViewController = LoginSMSCodeViewController(di: di)
            
            smsViewController.onSmsCodeConfirmed = { [unowned navigationController, unowned phoneViewController] in
                let scoringViewController = ScoringViewController()
                
                scoringViewController.onSuccess = {
                    self.finish(())
                }
                
                scoringViewController.onLoginUnderAnotherUserRequested = { [unowned navigationController, unowned phoneViewController] in
                    navigationController.setViewControllers([phoneViewController], animated: true)
                }
                
                navigationController.setViewControllers([phoneViewController, scoringViewController], animated: true)
            }
            
            navigationController.pushViewController(smsViewController, animated: true)
        }
        
        return navigationController
    }
}
