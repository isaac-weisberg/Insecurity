# Starting coordinator chain from outside world

This part of the docs tells you, how to start a chain of `Insecurity` coordinators from somewhere in the middle of the application. 

For example, if you have an already existing `UIViewController` and want to manage presentation on top of it using `Insecurity`, you will find this article helpful.

Or if you already use some implementation of Coordinator Tree pattern and want to interoperate between it and `Insecurity`, you will also find this article useful.

> ⚠️ **This is a low level API. Most of the time you should ignore `InsecurityHost` and `WindowHost`. You should manually manage only `WindowCoordinator`**

`Insecurity` supports both modal presentation chain (`present`/`dismiss`) and `UINavigationController`.

Whenever you operate the classes with the word "Coordinator" in their name, you are merely managing the building blocks of the navigation. However, all of the real navigation is managed by the objects that we call `Host`s.

There are 2 types of Hosts.

Host Type|Manages|Funtionality
---|---|---
`InsecurityHost`|Modal stack and `UINavigationController`|Starts its children modally on top of a root controller or inside a `UINavigationController`
`WindowHost`|`UIWindow`|Starts its children on the `rootViewController`, discarding the previous

## Starting from an existing `UIViewController`

You can start a chain of presenting coordinators modally from outside using a `InsecutityHost.init(modal:)`.

```swift
class PaymentMethodsCoordinator: ModalCoordinator<PaymentMethodsScreenResult> {
    // Implementation
}

class ExistingViewController: UIViewController {
    var customInsecurityHost: InsecurityHost?
    
    func startPaymentMethodScreen() {
        let insecurityHost = InsecurityHost(modal: self)
        self.customInsecurityHost = insecurityHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        insecurityHost.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customInsecurityHost = nil
            // result is PaymentMethodsScreenResult?
        }
    }
}
```

Don't forget to release the host coordinator after usage.

> ⚠️ **This is a low level API and you have to retain and release InsecurityHost yourself.**

## Starting from an existing UINavigationController

Alternatively, if you have `UINavigationController`, you can create the `InsecurityHost` that will start chilren inside this navigation controller.

> ⚠️ **The navigation controller must have just *1* view controller inside of it. No more, no less. This view controller will not be managed by the `InsecurityHost.`**

You create the `InsecurityHost` using `InsecurityHost.init(navigation:)`:

```swift
class PaymentMethodsCoordinator: NavigationCoordinator<PaymentMethodsScreenResult> {
    // Now it inherits `NavigationCoordinator`
}

class ExistingViewController: UIViewController {
    var customInsecurityHost: InsecurityHost?
    
    func startPaymentMethodScreenNavigation() {
        let navigationController = self.navigationController!
        
        let insecurityHost = InsecurityHost(navigation: navigationController)
        self.customInsecurityHost = insecurityHost

        let paymentMethodCoordinator = PaymentMethodsCoordinator()

        insecurityHost.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customInsecurityHost = nil
            // result is PaymentMethodsScreenResult?
        }
    }
}
```

Here, we get `navigationController` from `self.navigationController`, but you can get it from wherever you want.

## Starting from an existing UIWindow

We have already shown an example of starting using `WindowCoordinator` in the readme. You should derive from this class to start navigation, as it's made for this specific convenience of being able to derive from it.

There is no reason for you to manage a `WindowHost` manually, but if you really would like to, you should just create a `WindowHost`, save it and release it manually when you're done, just like `InsecurityHost`.