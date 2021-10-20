import UIKit

struct Deferred<Object> {
    let make: () -> Object
    
    init(_ make: @escaping () -> Object) {
        self.make = make
    }
}
