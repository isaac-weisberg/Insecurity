import UIKit

class AutoscaleImageView: UIImageView {
    var aspectRatioConstraint: NSLayoutConstraint?
    
    override var image: UIImage? {
        didSet {
            if let image = image {
                let size = image.size

                let ratio = size.width / size.height

                if ratio != aspectRatioConstraint?.multiplier {
                    aspectRatioConstraint?.isActive = false
                    let aspectRatioConstraint = widthAnchor.constraint(equalTo: heightAnchor, multiplier: ratio)
                    self.aspectRatioConstraint = aspectRatioConstraint

                    aspectRatioConstraint.isActive = true
                }
            } else {
                aspectRatioConstraint?.isActive = false
            }
        }
    }
}
