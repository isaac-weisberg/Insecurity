import UIKit

class NavigationBarButton: UIBarButtonItem {
    var onTap: (() -> Void)?
    
    override init() {
        super.init()
        
        super.target = self
        super.action = #selector(handleTap)
    }
    
    override var target: AnyObject? {
        get {
            return super.target
        }
        set {
            
        }
    }
    
    override var action: Selector? {
        get {
            return super.action
        }
        set {
            
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handleTap() {
        self.onTap?()
    }
}
