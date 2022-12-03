import UIKit
import Insecurity

class ViewController: UIViewController {
    static let sharedInstance = ViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Insecurity.loggerMode = .full
        
        view.backgroundColor = UIColor(white: 0.95, alpha: 1)
    }
}
