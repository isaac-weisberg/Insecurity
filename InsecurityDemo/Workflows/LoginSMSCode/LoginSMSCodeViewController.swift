import UIKit

class LoginSMSCodeViewController: UIViewController {
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
        onSmsCodeConfirmed?()
    }
}
