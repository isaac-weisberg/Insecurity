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

# Starting an `AdaptiveCoordinator`

`ModalCoordinator` and `NavigationCoordinator` both have `self.navigation`. For both classes, this object provides a very specialized interface to start new instances of both `ModalCoordinator` and `NavigationCoordinator`.

Additionally, `self.navigation` always conforms to `AdaptiveNavigation` protocol. This interface enables you to start `AdaptiveCoordinator`s.

Here is the `start` method available on `AdaptiveNavigation`:

```swift
public struct AdaptiveContext {
    public static var any: AdaptiveContext

    public static var modal: AdaptiveContext

    public static func navigation(new navigationController: UINavigationController) -> AdaptiveContext

    public static func navigation(fallback navigationController: @autoclosure @escaping () -> UINavigationController) -> AdaptiveContext
}

public protocol AdaptiveNavigation {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          in context: AdaptiveContext,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

Notice the context parameter. This parameter allows to control the way the child will be presented on screen.

## `AdaptiveContext.any`

Starting with this context means that the child will be presented just like its parent:
Parent is presented|Child will be presented
---|---
Via `present`|Via `present`
Via `push`|Via `push`

## `AdaptiveContext.modal`

This overrides the current context and enforces modal presentation:
Parent is presented|Child will be presented
---|---
Via `present`|Via `present`
Via `push`|Via `present`

## `AdaptiveContext.navigation(new:)`

This overrides the current context and starts a new `UINavigationController`

Parent is presented|Child will be presented
---|---
Via `present`|as a root of the given `UINavigationController`. The navigation controller will be presented modally on top of modally presented parent.
Via `push`|as a root of the given `UINavigationController`. The navigation controller will be presented modally on top of the existing `UINavigationController`.

## `AdaptiveContext.navigation(fallback:)`

This kind of context allows you to `push` if there is already a `UINavigationController` and to start a new `UINavigationController` if the parent didn't provide any.

This method accepts an `@autoclosure` which is not always evaluated.

Current Presentation Context|Outcome
---|---
Already a `UINavigationController`|It pushes the `child` unto the existing `UINavigationController`. `fallback`-autoclosure parameter never gets evaluated.
Modal presentation|It creates the `UINavigationController` from the `@autoclosure` that you pass as `fallback` parameter. Then, it starts child as the `rootViewController` of the `UINavigationController`.

# Starting proper coordinators from `AdaptiveCoordinator`

`self.navigation` also provides 2 methods that allow you to return to the realm of `ModalCoordinator` and `NavigationCoordinator`.

```swift
public protocol AdaptiveNavigation {
    func start<NewResult>(_ child: ModalCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
    
    func start<NewResult>(_ navigationController: UINavigationController,
                          _ child: NavigationCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void)
}
```

Of course, these instances of `ModalCoordinator` and `NavigationCoordinator` will see their proper navigation interfaces in `self.navigation` - the `ModalNavigation` and `NavigationControllerNavigation`.

# Convenience method to `start` in current context faster

If you call `start` without `in context: AdaptiveContext`, it's equivalent to `in: .any`.

```swift
public extension AdaptiveNavigation {
    func start<NewResult>(_ child: AdaptiveCoordinator<NewResult>,
                          animated: Bool,
                          _ completion: @escaping (CoordinatorResult<NewResult>) -> Void) {
        start(child, in: .any, animated: animated) { result in
            completion(result)
        }
    }
}
```
