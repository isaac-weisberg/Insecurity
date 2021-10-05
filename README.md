# Insecurity - the ultimate iOS navigation framework

# Getting Started

We start with having a "Select Currency" screen.
The screen will emit an event when the user selects a currency.
Once the selection is made, we need to close the screen.

We do this by subclassing `ModachildCoordinator`.

```swift
struct CurrencySelection {
    let currencyCode: String
}

class CurrencySelectionCoordinator: ModachildCoordinator<CurrencySelection> {
    init() {
        super.init { _, finish in
            let currencySelectionViewController = CurrencySelectionViewController()

            currencySelectionViewController.onCurrencySelected = { selection in
                finish(selection)
            }

            return currencySelectionViewController
        }
    }
}
```

# Development

1. Clone the repo
2. `bundle config --set path vendor/bundle`
3. `bundle install`, make sure your Xcode can be found at /Applications/Xcode.app, otherwise the ffi native extensions required by CocoaPods won't compile
4. `bundle exec pod install`
5. `open Insecurity.xcworkspace`