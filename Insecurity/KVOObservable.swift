import Foundation
import UIKit

class InsecurityKVOContext {

}

private protocol SubscriptionAny: AnyObject {
    var ctx: InsecurityKVOContext { get set }
    
    var keypath: String { get }
    
    var handler: (Any?, Any?) -> Void { get }
}

struct Nope: Error {}

func cast<Target>(_ any: Any?, to: Target.Type = Target.self) throws -> Target? {
    if any == nil || any is NSNull {
        return nil
    } else {
        if let value = any as? Target {
            return value
        } else {
            throw Nope()
        }
    }
}

private class Subscription<Value>: SubscriptionAny {
    var ctx = InsecurityKVOContext()
    let keypath: String
    let handler: (Any?, Any?) -> Void
    
    init(_ keypath: String,
         _ handler: @escaping (Value?, Value?) -> Void) {
        self.keypath = keypath
        self.handler = { old, new in
            var thrown = false
            let oldee: Value?
            do {
                oldee = try cast(old)
            } catch {
                assertionFailure("KVO value didn't convert into expected type")
                oldee = nil
                thrown = true
            }
            let newee: Value?
            do {
                newee = try cast(new)
            } catch {
                assertionFailure("KVO value didn't convert into expected type")
                newee = nil
                thrown = true
            }
            if !thrown {
                handler(oldee, newee)
            }
        }
    }
}

class KVOObservable: NSObject {
    weak var host: NSObject?
    private var subscriptions: [SubscriptionAny] = []
    
    init(_ host: NSObject?) {
        self.host = host
    }
    
    func removeObserver(_ ctx: InsecurityKVOContext) {
        if let host = host {
            if let subscription = subscriptions.first(where: { subscription in
                subscription.ctx === ctx
            }) {
                host.removeObserver(self, forKeyPath: subscription.keypath, context: &subscription.ctx)
                
                self.subscriptions = self.subscriptions.filter { subscription in
                    subscription.ctx !== ctx
                }
            }
        }
    }
    
    func addHandler<Value>(_ type: Value.Type,
                           _ keyPath: String,
                           _ handler: @escaping (Value?, Value?) -> Void) -> InsecurityKVOContext {
        let subscription = Subscription<Value>(keyPath, handler)
        if let host = host {
            host.addObserver(self, forKeyPath: keyPath, options: [.new, .old], context: &subscription.ctx)
            
            self.subscriptions.append(subscription)
        }
        return subscription.ctx
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let subscription = subscriptions.first(where: { subscription in
            context?.assumingMemoryBound(to: InsecurityKVOContext.self).pointee === subscription.ctx
                && keyPath == subscription.keypath
        }) {
            if let change = change {
                let oldValue = change[.oldKey]
                let newValue = change[.newKey]
                
                subscription.handler(oldValue, newValue)
            }
        }
    }
    
    deinit {
        if let host = host {
            // Of course not, because self is retained by the `host`
            subscriptions.forEach { subscription in
                host.removeObserver(self, forKeyPath: subscription.keypath, context: &subscription.ctx)
            }
            subscriptions = []
        }
    }
}


private var insecurityKvoObservableContext: UInt8 = 0

extension NSObject {
    var insecurityKvo: KVOObservable {
        objc_sync_enter(self)
        
        if let kvoObservable = objc_getAssociatedObject(self, &insecurityKvoObservableContext) as? KVOObservable {
            return kvoObservable
        }
        
        let kvoObservable = KVOObservable(self)
        
        objc_setAssociatedObject(self, &insecurityKvoObservableContext, kvoObservable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_sync_exit(self)
        
        return kvoObservable
    }
}
