/*
 
 The MIT License Copyright © 2015 Krunoslav Zaher, Shai Mishali All rights reserved.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

//
//  NSObject+Rx.swift
//  RxCocoa
//
//  Created by Krunoslav Zaher on 2/21/15.
//  Copyright © 2015 Krunoslav Zaher. All rights reserved.
//

import Foundation

class DeinitObservable {
    var onDeinit: (() -> Void)?
    
    deinit {
        onDeinit?()
        onDeinit = nil
    }
}

private var deinitObservableContext: UInt8 = 0

extension NSObject {
    ///
    /// Blatantly ripped off from RxSwift 5.0.0 implementation
    ///
    var deinitObservable: DeinitObservable {
        objc_sync_enter(self)
        
        if let deinitObservable = objc_getAssociatedObject(self, &deinitObservableContext) as? DeinitObservable {
            return deinitObservable
        }
        
        let deinitObservable = DeinitObservable()
        
        objc_setAssociatedObject(self, &deinitObservableContext, deinitObservable, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        objc_sync_exit(self)
        
        return deinitObservable
    }
}
