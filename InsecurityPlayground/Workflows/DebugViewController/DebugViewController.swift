import UIKit

class DebugViewController: UIViewController {
    typealias DI = HasAuthService
    
    let di: DI
    let authStateLabel = UILabel()
    let closeButton = UIButton(type: .system)
    
    var onClose: (() -> Void)?
    
    init(di: DI) {
        self.di = di
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.orange
        
        navigationItem.title = "Debug View"
        
        authStateLabel.numberOfLines = 0
        let authStateText: String
        if let creds = di.authService.getCreds() {
            authStateText = "Authorized; token \(creds.token)"
        } else {
            authStateText = "Unauthorized"
        }
        authStateLabel.text = authStateText
        authStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(authStateLabel)
        NSLayoutConstraint.activate([
            authStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            authStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            authStateLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
        ])
        
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        view.addSubview(closeButton)
        closeButton.addTarget(self, action: #selector(closeTap), for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            closeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }
    
    @objc func closeTap() {
        onClose?()
    }
}
