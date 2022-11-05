import Insecurity
import UIKit

enum LoginPhoneCoordinatorResult {
    case loggedIn
}

extension DispatchTime: ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = DispatchTime.now() + value
    }
}

class LoginPhoneCoordinator: ModalCoordinatorV2<LoginPhoneCoordinatorResult> {
    typealias DI = HasAuthService
    
    override var viewController: UIViewController {
        let controller = LoginPhoneViewController()
        
        controller.onSmsCodeSent = { [self] in
            let loginSMSCodeCoordinator = LoginSMSCodeCoordinator(di: di)
            
            start(loginSMSCodeCoordinator, animated: true) { [self] result in
                print("End LoginSMSCode \(result)")
                switch result {
                case .loggedIn:
                    finish(.loggedIn)
                case nil:
                    break
                }
            }
        }
        
//        DispatchQueue.main.asyncAfter(deadline: 1.0, execute: { [self] in
//            let loginSMSCodeCoordinator = LoginSMSCodeCoordinator(di: di)
//            
//            start(loginSMSCodeCoordinator, animated: true) { [self] result in
//                print("End LoginSMSCode \(result)")
//                switch result {
//                case .loggedIn:
//                    finish(.loggedIn)
//                case nil:
//                    break
//                }
//            }
//            
//            DispatchQueue.main.asyncAfter(deadline: 1.0, execute: { [self] in
//                self.dismissChildren(animated: true)
//            })
//            
//        })
        
        return controller
    }
    
    let di: DI
    
    init(di: DI) {
        self.di = di
    }
}
