# Insecurity - the ultimate iOS navigation framework

This implementation of Coordinator pattern provides:
- Automatic `present`/`dismiss` calls for modal controller presentation
- Automatic `pushViewController`/`popViewController` calls for `UINavigationController` presentation
- Automatic dismissal/popping of **multiple** view controllers if all of them finish simultaneously
- Automatic detection of modal iOS 13 form sheet dismissal in modal presentation
- Automatic detection of `interactivePopGestureRecognizer` dismissal in `UINavigationController`
- Propagation of results to the parent
- Ability to organize custom coordinators that allow for magical modification of `UINavigationController` stack or modal presentation stack
- Context-independent navigation
- Automatic management of a `UIWindow`

You can use it alongside any of your existing navigation solutions.

# Installation

Currently, only CocoaPods is supported.
Minimum iOS version: 12.0
Minimum Xcode version: 12.0
This framework has no dependencies.

```ruby
pod 'Insecurity'
```

# Getting Started

We start with a "Select Payment Method" screen.  
The screen will emit an event when the user presses Done button.  
Once it happens, we need to close the screen.

We do this by subclassing `ModalCoordinator`.

```swift
struct PaymentMethodScreenResult {
    let paymentMethodChanged: Bool
}

class PaymentMethodCoordinator: ModalCoordinator<PaymentMethodScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodViewController()
        
        viewController.onDone = { result in
            self.finish(result)
        }
        
        return viewController
    }
}
```

## Showing a new screen

Now, when the user presses "Add Payment Method" button, we need to open a next screen.  
This screen will be "Create a new payment method".  
Once it's finished, we need to notify the "Select Payment Method" screen of its creation.  

Here is a coordinator for Add Payment Method screen.

```swift
struct PaymentMethod {
    let cardNumber: String
}

class AddPaymentMethodCoordinator: ModalCoordinator<PaymentMethod> {
    override var viewController: UIViewController {
        let addPaymentMethodViewController = AddPaymentMethodViewController()
        
        addPaymentMethodViewController.onPaymentMethodAdded = { paymentMethod in
            self.finish(paymentMethod)
        }
        
        return addPaymentMethodViewController
    }
}
```

And here is how we start it from `PaymentMethodCoordinator`:

```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
    
    self.navigation.start(addPaymentMethodCoordinator, animated: true) { result in
        // `result` is the PaymentMethod
    }
}
```

**Important part:** in iOS 13 user can also dismiss the screen by swiping it down using a gesture.  
`Insecurity` framework handles this situation automatically.  

The `result` you receive in the code will be:
- `.dismissed` if the screen is dismissed by gesture
- `.normal(PaymentMethod)` if the coordinator calls `finish`

Here is the final code:

```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
    
    self.navigation.start(addPaymentMethodCoordinator, animated: true) { [weak viewController] result in
        switch result {
        case .normal(let paymentMethod):
            // User has added a new payment method
            viewController?.handleNewPaymentMethodAdded(paymentMethod)
        case .dismissed:
            // User dismissed the screen, nothing to do
            break
        }
    }
}
```

> ⚠️ **Note the `weak viewController`. Be careful not to create any retain cycles.**

## Starting a WindowCoordinator

In order to start working with `Insecurity` in your app, you should use a coordinator that manages your `UIWindow`.  
It's called `WindowCoordinator`.  
Then, you call `navigation.start` methods on it in order to start your instances of `ModalCoordinator.`

```swift
class AppCoordinator: WindowCoordinator {
    func start() {
        let paymentMethodCoordinator = PaymentMethodCoordinator()
        
        self.navigation.start(paymentMethodCoordinator, duration: 0.5, options: .transitionCrossDissolve) { result in
            // Payment method coordinator result
        }
    }
}
```
The `duration` and `options` parameters regulate that animation of `UIWindow.rootViewController` change.

And here is how you start your instance of `AppCoordinator`:

```swift
@main class ApplicationDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let appCoordinator = AppCoordinator(window)
        self.appCoordinator = appCoordinator
        
        appCoordinator.start()
        
        window.makeKeyAndVisible()
        
        return true
    }
}
```

# Important rules:

- ⚠️ Never-ever retain the `UIViewController` that you return from `viewController`
- ⚠️ One `ModalCoordinator` manages strictly one `UIViewController`. New view controller = new `ModalCoordinator`

# Advanced topics

- Working with a `UINavigationController`
- Finishing several screens at a time
- Using context-independent navigation with `AdaptiveCoordinator`
- Starting on the top of the presentation context
- Writing a custom coordinator that allows for magical navigation
- Deeplinking
- Starting coordinator chain without `WindowCoordinator`

# Philosophy

A process of showing a screen is an inherently functional operation. A classical Coordinator Tree implementation centers around a tree of objects. Parent coordinator retains the child coordinator, and so on and so forth. This tree can be freely traversed, usually for deeplinking propagation. However, the OOP-based model of Coordinator Tree doesn't advise anything on the event propagation, nor is it concerned with the quirks of using the navigation facilities of UIKit. And with this, comes an immense variety in visions of how the navigation is supposed to be performed.

This project however models the Coordinator Tree not in an object-oriented way, but a function-oriented way. A process of presenting a screen can be represented as an asynchronous function that accepts input data and emits output data asynchronously. Making a `UIWindow` key and visible is a function that returns `Never` in the single-window applications. A process of presenting a `UIViewController` modally is a function that returns the result of whatever the controller has settled upon. Same goes with pushing a view controller onto a `UINavigationController`. And these coordinators allow you to strictly define the results of their lifecycles.

Additionally, this framework forces you to build navigation in a magic-free way. A chain of modal view controllers can be resolved and dismissed simultaneously in a transparent way, that will involve your conscious decision. And if you really need to perform some magic, you can always leave the realm of automatically handled navigation and implement custom behavior in a compatible way.

Also, this framework uses the best it can take from functional programming without explicitly relying on FRP. The public interface is still Object-Oriented and the internal components are written in an efficient imperative style programming with careful state management, thoughtful memory management and lowest footprint possible mentality.

So, all in all, no `RxSwift` this time around. Though it's very compatible with `RxSwift`, a `Single` wrapper is very easy to write.

# Development

You will need Xcode 13 for the development.

1. Clone the repo
1. `bundle config --set path vendor/bundle`
1. `bundle install`, make sure your Xcode can be found at `/Applications/Xcode.app`, otherwise the "ffi" package native extensions required by CocoaPods won't compile
1. `bundle exec pod install`
1. `open Insecurity.xcworkspace`