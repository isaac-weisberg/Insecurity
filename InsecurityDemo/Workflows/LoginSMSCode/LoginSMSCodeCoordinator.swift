import Insecurity
import UIKit

enum LoginSMSCodeCoordinatorResult {
    case loggedIn
}

class LoginSMSCodeCoordinator: NavigationChild<LoginSMSCodeCoordinatorResult> {
    typealias DI = LoginSMSCodeViewController.DI
    
    override var viewController: UIViewController {
        let controller = LoginSMSCodeViewController(di: di)
        
        controller.onSmsCodeConfirmed = { [self] in
            finish(.loggedIn)
        }
        
        return controller
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
