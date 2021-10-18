# Changing navigation method

So far, we have learned how to present `UIViewControllers` modally by starting `ModalChild` and `NavigationChild` instances.  These classes allow you to define the context in which the view controller will be presented. It's guaranteed to be presented in the exact way that you expect.

However, there is a way to create a coordinator that adapts to the presentation context of the parent coordinator. You use `AdaptiveCoordinator` to achieve this goal:

```swift
class PaymentMethodCoordinator: AdaptiveCoordinator<PaymentMethodScreenResult> {
    override var viewController: UIViewController {
        let viewController = PaymentMethodViewController()
        
        return viewController
    }
}
```

# Being started from other coordinators

`ModalCoordinator` and `NavigationCoordinator` both have `self.navigation`. For both classes, this object provides a very specialized interface to start new instances of both.

For `ModalCoordinator`:

```swift
public protocol ModalNavigation: AdaptiveNavigation {
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

For `NavigationCoordinator`:

```swift
public protocol NavigationControllerNavigation: AdaptiveNavigation {
    func start<NewResult>(_ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

However, you can notice that both of these `...Navigation` protocols inherit `AdaptiveNavigation`. This `AdaptiveNavigation` is what enables you to enter and leave adaptive navigation context.

Here is the main method available on `AdaptiveNavigation`:

```swift
public enum AdaptiveContext {
    case current
    case modal
    case navigation(UINavigationController)
}

public protocol AdaptiveNavigation {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          in context: AdaptiveContext,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

# Starting child coordinators

Whenever `PaymentMethodViewController` calls its `onNewPaymentMethodRequested`, we handle this by calling `self.navgation.start(_:animated:_:)`.

As you can see, this presents us with zero information about how exactly the controller of the child coordinator will be displayed. This is by design.

The semantics of `InsecurityChild` omit the details of how exactly a new child will be started. This is done so that you could easily reuse screens and flows in a different context with the goal of removing a burden of modifying or duplicating files in bulk in case if you change your mind.

Let's take a look at the signature of `self.navigation`.

```swift
public protocol InsecurityNavigation: AnyObject {
    func start<NewResult>(_ child: InsecurityChild<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```
The way this particular implementation of the `start` method works is that:
- if the current presentation context is `UINavigationController`, the view controller of the child will be *pushed* onto the navigation stack
- if the current presentation context is Modal Presentation Chain, the view controller of the child will be shown via `present`

However, there are other methods available on `InsecurityNavigation` that allow you to change the presentation context.

```swift
func start<NewResult>(_ navigationController: UINavigationController,
                      _ child: InsecurityChild<NewResult>,
                      animated: Bool,
                      _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
```

This implementation of `start` differs from the previous one by having a new first parameter that accepts a `UINavigationController`.

When you call it, the following happens:
- `navigationController` will be presented modally on top of the current presentation context
- `child` is started as the `rootViewController` of the `navigationController`
- all calls to regular `start` in the subsequent children, including `child`, will lead to `push`es onto the `navigationController`
- if any of the children decides to switch presentation context once more, then all of their children's `start` calls will relate to this new presentation context

And, there is a third method:

```swift
func startModal<NewResult>(_ child: InsecurityChild<NewResult>,
                           animated: Bool,
                           _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
```
This implementation of start, which is called `startModal` also changes the presentation context to start the child modally on top of the current context.

It's called `startModal` to avoid ambiguation.

When you call this implementation, the following happens:
- `viewController` of the `child` is presented modally on top of current context
- all calls to regular `start` in the subsequent children, including `child`, will lead to `present` calls onto the modal navigation stack

## Usage example

Start a new `UINavigationController`:
```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()
    
    let navigationController = UINavigationController()

    self.navigation.start(navigationController, addPaymentMethodCoordinator, animated: true) { result in
        
    }
}
```

Start a new child modally regardless of whether if we are in modal context or not:
```swift
viewController.onNewPaymentMethodRequested = {
    let addPaymentMethodCoordinator = AddPaymentMethodCoordinator()

    self.navigation.startModal(addPaymentMethodCoordinator, animated: true) { result in
        
    }
}
```

> ⚠️ **Never retain any of the viewControllers that you pass to Insecurity**

## Summary
Method of `InsecurityChild.navigation`|Effect
---|---
`start` in the context of `UINavigationController`|Pushes `child.viewController` onto the `UINavigationController`
`start` in the context of Modal Presentation|Presents `child.viewController` using `present`
`start` with `UINavigationController` parameter|Starts a new modal context with `UINavigationController` and pushes `child.viewController` onto the `UINavigationController`
`startModal`|Starts a new modal context with `child.viewController`