import Insecurity
import UIKit

enum LoginPhoneCoordinatorResult {
    case loggedIn
}

class LoginPhoneCoordinator: NavichildCoordinator<LoginPhoneCoordinatorResult> {
    typealias DI = HasAuthService
    
    override var viewController: UIViewController {
        let controller = LoginPhoneViewController()
        
        controller.onSmsCodeSent = { [self] in
            let loginSMSCodeCoordinator = LoginSMSCodeCoordinator(di: di)
            
            navitroller.start(loginSMSCodeCoordinator, animated: true) { result in
                print("End LoginSMSCode \(result)")
                switch result {
                case .normal(let smsCodeResult):
                    switch smsCodeResult {
                    case .loggedIn:
                        finish(.loggedIn)
                    }
                case .dismissed:
                    break
                }
            }
        }
        
        return controller
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
