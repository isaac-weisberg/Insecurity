import Insecurity

enum LoginPhoneCoordinatorResult {
    case loggedIn
}

class LoginPhoneCoordinator: NavichildCoordinator<LoginPhoneCoordinatorResult> {
    init() {
        super.init { navitroller, finish in
            let controller = LoginPhoneViewController()
            
            controller.onSmsCodeSent = {
                let loginSMSCodeCoordinator = LoginSMSCodeCoordinator()
                
                navitroller.startChild(loginSMSCodeCoordinator, animated: true) { result in
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
    }
}
