Pod::Spec.new do |spec|
  spec.name         = "Insecurity"
  spec.version      = "0.9"
  spec.summary      = "Ultimate iOS Swift Navigation Framework"

  spec.description  = <<-DESC
  This implementation of Coordinator pattern provides:

  - Automatic present/dismiss calls for modal controller presentation
  - Automatic pushViewController/popViewController calls for UINavigationController presentation
  - Automatic dismissal/popping of multiple view controllers if all of them finish simultaneously
  - Automatic detection of modal iOS 13 form sheet dismissal in modal presentation
  - Automatic detection of interactivePopGestureRecognizer dismissal in UINavigationController
  - Propagation of results to the parent
  - Ability to organize custom coordinators that allow for magical modification of UINavigationController stack or modal presentation stack
  - Automatic management of a UIWindow

  You can use it alongside any of your existing navigation solutions.
  DESC

  spec.homepage     = "https://github.com/isaac-weisberg/Insecurity"
  spec.license      = { :type => "MIT", :file => "LICENSE.txt" }
  
  spec.author             = { "Isaac Weisberg" => "net.caroline.weisberg@gmail.com" }
  spec.social_media_url   = "http://caroline-weisberg.net/"

  spec.platform     = :ios, "12.0"
  spec.source       = { :git => "https://github.com/isaac-weisberg/Insecurity.git", :tag => "#{spec.version}" }

  spec.source_files  = "Insecurity/**/*.swift"
end
