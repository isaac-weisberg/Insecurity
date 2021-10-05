import UIKit

class LoginPhoneViewController: UIViewController {
    var onSmsCodeSent: (() -> Void)?
    
    let sendSMSButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemMintCompat
        
        navigationItem.title = "Login"
        
        sendSMSButton.translatesAutoresizingMaskIntoConstraints = false
        sendSMSButton.setTitle("Send SMS", for: .normal)
        view.addSubview(sendSMSButton)
        sendSMSButton.addTarget(self, action: #selector(onSendSMSButtonTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            sendSMSButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            sendSMSButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onSendSMSButtonTap() {
        onSmsCodeSent?()
    }
}
