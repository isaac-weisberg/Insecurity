import Insecurity

enum LoginSMSCodeCoordinatorResult {
    case loggedIn
}

class LoginSMSCodeCoordinator: NavichildCoordinator<LoginSMSCodeCoordinatorResult> {
    init() {
        super.init { _, finish in
            let controller = LoginSMSCodeViewController()
            
            controller.onSmsCodeConfirmed = {
                finish(.loggedIn)
            }
            
            return controller
        }
    }
}
