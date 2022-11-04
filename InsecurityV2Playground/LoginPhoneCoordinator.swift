import Insecurity
import UIKit

enum LoginPhoneCoordinatorResult {
    case loggedIn
}

class LoginPhoneCoordinator: ModalCoordinatorV2<LoginPhoneCoordinatorResult> {
    typealias DI = HasAuthService
    
    override var viewController: UIViewController {
        let controller = LoginPhoneViewController()
        
        controller.onSmsCodeSent = { [self] in
            let loginSMSCodeCoordinator = LoginSMSCodeCoordinator(di: di)
            
            start(loginSMSCodeCoordinator, animated: true) { result in
                print("End LoginSMSCode \(result)")
                switch result {
                case .loggedIn:
                    finish(.loggedIn)
                case nil:
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
