# Starting coordinator chain from outside world

This part of the docs tells you, how to start a chain of `Insecurity` coordinators from somewhere in the middle of the application. 

For example, if you have an already existing `UIViewController` and want to manage presentation on top of it using `Insecurity`, you will find this article helpful.

Or if you already use some implementation of Coordinator Tree pattern and want to interoperate between it and `Insecurity`, you will also find this article useful.

> ⚠️ **This is a low level API. Most of the time you should ignore `ModalHost`, `NavigationHost`, `WindowHost` and manually manage only `WindowCoordinator`**

`Insecurity` supports both modal presentation chain (`present`/`dismiss`) and `UINavigationController`.

Whenever you operate the classes with the word "Coordinator" in their name, you are merely managing the building blocks of the navigation. However, all of the real navigation is managed by the objects which are organized into a tree. 

These objects are usually hidden from you.  
These objects are called **Hosts** and they all implement different navigation aspects.

There are 3 types of Hosts.

Host Type|Manages|Funtionality
---|---|---
`ModalHost`|`UIViewController`|Starts its children inside a modal presentation chain of the managed controller
`NavigationHost`|`UINavigationController`|Starts its children inside a `UINavigationController`
`WindowHost`|`UIWindow`|Starts its children on the `rootViewController`, discarding the previous

## Starting from an existing `UIViewController`

You can start a chain of presenting coordinators modally from outside using a `ModalHost`.

```swift
class ExistingViewController: UIViewController {
    var customModalHost: ModalHost?
    
    func startPaymentMethodScreen() {
        let modalHost = ModalHost(self)
        self.customModalHost = modalHost

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        modalHost.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customModalHost = nil
            // result is PaymentMethodScreenResult?
        }
    }
}
```

Don't forget to release the host coordinator after usage.

> ⚠️ **This is a low level API and you have to retain and release ModalHost yourself.**

## Starting from an existing UINavigationController

Alternatively, if you have `UINavigationController`, you can display children inside it using a similar code:

```swift
class ExistingViewController: UIViewController {
    var customNavigationHost: NavigationHost?
    
    func startPaymentMethodScreenNavigation() {
        let navigationController = self.navigationController!
        
        let navigationHost = NavigationHost(navigationController)
        self.customNavigationHost = navigationHost

        let paymentMethodCoordinator = PaymentMethodCoordinator()

        navigationHost.start(paymentMethodCoordinator, animated: true) { [weak self] result in
            self?.customNavigationHost = nil
            // result is PaymentMethodScreenResult?
        }
    }
}
```

Here, we get `navigationController` from `self.navigationController`, but you can get it from wherever you want.

> ⚠️ **The `UINavigationController` that you provide should have a `rootViewController` and it must not be the one that you are trying to start on top!**

> ⚠️ **It also must not have other viewController already pushed to it**

## Starting from an existing UIWindow

We have already shown an example of starting using `WindowCoordinator` in the readme. You should derive from this class to start navigation, as it's made for this specific convenience of being able to derive from it.

There is no reason for you to manage a `WindowHost` manually, but if you really would like to, you should use an example of manual `ModalHost` management and then replace `ModalHost` with `WindowHost` and figure it out from there.