import UIKit

class GalleryViewController: UIViewController {
    var onProductRequested: (() -> Void)?
    var onAltButton: (() -> Void)?
    
    let button = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .cyan
        
        navigationItem.title = "Catalog"
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("See product details", for: .normal)
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        button.addTarget(self, action: #selector(onTap), for: .touchUpInside)
    }
    
    @objc func onTap() {
        onProductRequested?()
    }
}
