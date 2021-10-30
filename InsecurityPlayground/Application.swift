import UIKit

class PlaygroundApplication: UIApplication {
    var theDelegate: PlaygroundAppDelegate! {
        return delegate as? PlaygroundAppDelegate
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        
        theDelegate.shakeDetected()
    }
}
