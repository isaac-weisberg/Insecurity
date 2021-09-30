import Insecurity

enum LoginSMSCodeCoordinatorResult {
    case loggedIn
}

class LoginSMSCodeCoordinator: NavichildCoordinator<LoginSMSCodeCoordinatorResult> {
    typealias DI = LoginSMSCodeViewController.DI
    
    init(di: DI) {
        super.init { _, finish in
            let controller = LoginSMSCodeViewController(di: di)
            
            controller.onSmsCodeConfirmed = {
                finish(.loggedIn)
            }
            
            return controller
        }
    }
}
