import UIKit

class LoginSMSCodeViewController: UIViewController {
    typealias DI = HasAuthService
    
    let di: DI
    
    init(di: DI) {
        self.di = di
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var onSmsCodeConfirmed: (() -> Void)?
    
    let sendSMSCodeButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemRed
        
        navigationItem.title = "Code"
        
        sendSMSCodeButton.translatesAutoresizingMaskIntoConstraints = false
        sendSMSCodeButton.setTitle("Confirm SMS code", for: .normal)
        view.addSubview(sendSMSCodeButton)
        sendSMSCodeButton.addTarget(self, action: #selector(onConfirmSMSCodeButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            sendSMSCodeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            sendSMSCodeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onConfirmSMSCodeButtonTap() {
        // Imagine we logged in and saved them credits
        di.authService.saveCreds(Creds(token: "pqierbgu-qbrfr13yncr8020y37cyn0q"))
        onSmsCodeConfirmed?()
    }
}
