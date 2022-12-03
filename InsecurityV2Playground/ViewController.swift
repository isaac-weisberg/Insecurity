import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [self] in
            let di = DIContainer()
            let loginPhoneCoordinator = LoginPhoneCoordinator(di: di)
            
            loginPhoneCoordinator.mount(on: self, animated: true) { result in
                print("Login Phone End \(result)")
            }
        })
    }
}
