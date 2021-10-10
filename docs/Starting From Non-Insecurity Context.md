# Starting coordinator chain from outside world

This part of the docs tells you, how to start a chain of `Insecurity` coordinators from somewhere in the middle of the application. 

For example, if you have an already existing `UIViewController` and want to manage presentation on top of it using `Insecurity`, you will find this article helpful.

Or if you already use some implementation of Coordinator Tree pattern and want to interoperate between it and `Insecurity`, you will also find this article useful.

> ⚠️ **This is a low level API. Most of the time you should ignore `ModalCoordinator` and `NavigationCoordinator` and manually manage only `WindowCoordinator`**

`Insecurity` support both modal presentation chain (`present`/`dismiss`) and `UINavigationController`.

However, in the code we've written so far, you can notice that these semantics are not stated explictly. There is no way to tell if this code is supposed to be running unside a modal presentation or `UINavigationController`.

The answer is that this is decided by the host coordinator!
There are 3 classes of host coordinators.

Coordinator Type|Manages|Funtionality
---|---|---
`ModalCoordinator`|`UIViewController`|Starts its children inside a modal presentation chain of the managed controller
`NavigationCoordinator`|`UINavigationController`|Starts its children inside a `UINavigationController`
`WindowCoordinator`|`UIWindow`|Starts its children on the `rootViewController` with overwriting

You can start a chain of presenting coordinators modally from outside using a `ModalCoordinator`.

```swift
class ExistingViewController: UIViewController {
    var customModalCoordinator: ModalCoordinatorAny?
    
    func startPaymentMethodScreen() {
        let modalCoordinator = ModalCoordinator(self)
        self.customModalCoordinator = modalCoordinator

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        modalCoordinator.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customModalCoordinator = nil
            // result is PaymentMethodScreenResult
        }
    }
}
```

Don't forget to release the host coordinator after usage.

> ⚠️ **This is a low level API and you have to retain and release ModalCoordinator yourself.**

Alternatively, if you have `UINavigationController`, you can display children inside it using a similar code:

```swift
class ExistingViewController: UIViewController {
    var customNavigationCoordinator: NavigationCoordinatorAny?
    
    func startPaymentMethodScreenNavigation() {
        let navigationController = self.navigationController!
        
        let navigationCoordinator = NavigationCoordinator(navigationController)
        self.customNavigationCoordinator = navigationCoordinator

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        navigationCoordinator.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customNavigationCoordinator = nil
            // result is PaymentMethodScreenResult
        }
    }
}
```

Here, we get `navigationController` from `self.navigationController`, but you can get it from wherever.

> ⚠️ **The `UINavigationController` that you provide should have a `rootViewController` and it must not be the one that you are trying to start on top!**

> ⚠️ **It also must not have other viewController already pushed to it**