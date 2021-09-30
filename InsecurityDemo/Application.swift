import UIKit

class Application: UIApplication {
    var theDelegate: AppDelegate! {
        return delegate as? AppDelegate
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        theDelegate.shakeDetected()
    }
}
