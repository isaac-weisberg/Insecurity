import Foundation

class DeinitObservable {
    var onDeinit: (() -> Void)?
    
    deinit {
        self.onDeinit?()
    }
}

private var deinitObservableContext: UInt8 = 0

extension NSObject {
    ///
    /// Blatantly ripped off from RxSwift 5.0.0 implementation
    ///
    private var deinitObservable: DeinitObservable {
        objc_sync_enter(self)
    
        if let deinitObservable = objc_getAssociatedObject(self, &deinitObservableContext) as? DeinitObservable {
            return deinitObservable
        }

        let deinitObservable = DeinitObservable()

        objc_setAssociatedObject(self, &deinitObservableContext, deinitObservable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_sync_exit(self)
        
        return deinitObservable
    }
    
    var onDeinit: (() -> Void)? {
        get {
            deinitObservable.onDeinit
        }
        set {
            deinitObservable.onDeinit = newValue
        }
    }
}
