import UIKit

class GenericViewController: UIViewController {
    var onEvent: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.random
        
        DispatchQueue.main.asyncAfter(0.10) { [weak self] in
            self?.onEvent?()
        }
    }
}
