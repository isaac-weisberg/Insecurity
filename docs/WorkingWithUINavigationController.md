# Working with `UINavigationController`

If you have an existing `ModalCoordinator`:
```swift
class PaymentMethodCoordinator: ModalCoordinator<PaymentMethodScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodViewController()

        return viewController
    }
}
```
you can easily make sure that it get displayed in `UINavigationController`. To do this, you just need to change `ModalCoordinator` to `NavigationCoordinator`.

```swift
class PaymentMethodCoordinator: NavigationCoordinator<PaymentMethodScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodViewController()

        return viewController
    }
}
```

This is literally it, now in every context, this coordinator will always start via a `push` onto a `UINavigationController`. There is only one thing that really changes is what kind of methods are available for you when you use `self.navigation`.

`ModalCoordinator` and `NavigationCoordinator` both have `self.navigation`. For both classes, this object provides a very specialized interface to start new instances of both.

For `ModalCoordinator`:

```swift
public protocol ModalNavigation: AdaptiveNavigation {
    // Starts a new modal screen
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    // Starts a new `UINavigationController`
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

For `NavigationCoordinator`:

```swift
public protocol NavigationControllerNavigation: AdaptiveNavigation {
    // Pushes to the current `UINavigationController`
    func start<NewResult>(_ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    // Starts a new `UINavigationController`
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    // Starts a new modal screen
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

As you can see, whenever you want to start a new `UINavigationController`, `start` method accepts a 4-th parameter - an instance of `UINavigationController`.

This new navigation controller will be presented modally on top of the parent, while the `NavigationCoordinator` that you pass will be started inside of it.

If `PaymentMethodCoordinator`, the parent, is a `ModalCoordinator` and `AddPaymentMethodCoordinator` is a `ModalCoordinator`:

```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
    
    // To start modally
    self.navigation.start(addPaymentMethodCoordinator, animated: true) { _ in }
}
```

However, if `AddPaymentMethodCoordinator` is a `NavigationCoordinator`:

```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
    
    // To start in a new UINavigationController
    self.navigation.start(UINavigationController(), addPaymentMethodCoordinator, animated: true) { _ in }
}
```

And, if we, ourselves, the parent, the `PaymentMethodCoordinator` are a `NavigationCoordinator` as well as the `AddPaymentMethodCoordinator`, we can do this:

```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
    
    // To start in the current UINavigationController
    self.navigation.start(addPaymentMethodCoordinator, animated: true) { _ in }

    // OR
    // To start in a new UINavigationController
    self.navigation.start(UINavigationController(), addPaymentMethodCoordinator, animated: true) { _ in }
}
```
