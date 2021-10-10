import UIKit

class GenericViewController: UIViewController {
    var onEvent: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.random
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(0.10) { [weak self] in
            self?.onEvent?()
        }
    }
}
