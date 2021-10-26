import UIKit

class DemoApplication: UIApplication {
    var theDelegate: DemoAppDelegate! {
        return delegate as? DemoAppDelegate
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        theDelegate.shakeDetected()
    }
}
