import UIKit

class ScoringViewController: UIViewController {
    var onSuccess: (() -> Void)?
    var onLoginUnderAnotherUserRequested: (() -> Void)?
    
    
    let titleLabel = UILabel()
    let sendFormButton = UIButton(type: .system)
    let loginUnderAnotherUserButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemMintCompat
        
        navigationItem.title = "Scoring Form"
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 20, weight: .medium)
        titleLabel.text = "Welcome back, Steven! Please, fill out this scoring form"
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])
        
        sendFormButton.translatesAutoresizingMaskIntoConstraints = false
        sendFormButton.setTitle("Send scoring form", for: .normal)
        view.addSubview(sendFormButton)
        sendFormButton.addTarget(self, action: #selector(onSendFormTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            sendFormButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            sendFormButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        
        loginUnderAnotherUserButton.setTitle("I am not Steven", for: .normal)
        loginUnderAnotherUserButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loginUnderAnotherUserButton)
        loginUnderAnotherUserButton.addTarget(self, action: #selector(onLoginUnderAnotherUserTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            loginUnderAnotherUserButton.bottomAnchor.constraint(equalTo: sendFormButton.topAnchor, constant: -8),
            loginUnderAnotherUserButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func onSendFormTap() {
        onSuccess?()
    }
    
    @objc func onLoginUnderAnotherUserTap() {
        onLoginUnderAnotherUserRequested?()
    }
}
