import Insecurity
import UIKit

class ScoringCoordinator: ModachildCoordinator<Void> {
    typealias DI = LoginSMSCodeViewController.DI
    
    init(di: DI) {
        super.init { _, finish in
            let phoneViewController = LoginPhoneViewController()
            
            let navigationController = UINavigationController(rootViewController: phoneViewController)
            
            phoneViewController.onSmsCodeSent = { [unowned navigationController, unowned phoneViewController] in
                let smsViewController = LoginSMSCodeViewController(di: di)
                
                smsViewController.onSmsCodeConfirmed = { [unowned navigationController, unowned phoneViewController] in
                    let scoringViewController = ScoringViewController()
                    
                    scoringViewController.onSuccess = {
                        finish(())
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
}
