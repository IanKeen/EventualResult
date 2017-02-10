/**
 *  EventualResult
 *
 *  Copyright (c) 2017 Ian Keen. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation

/// A box that provides synchronized/thread safe access to a value
public final class SynchronizedBox<T> {
    public typealias UpdatedClosure = ((T?) -> Void)

    // MARK: - Private Properties
    private let queue = DispatchQueue(label: "SynchronizedBox.queue")
    private var _value: T? = nil

    // MARK: - Lifecycle
    public init() { }
    public init(value: T) {
        self.value = value
    }

    // MARK: - Public Properties
    /// Closure that is called when the value is updated
    public var valueUpdated: UpdatedClosure?

    public var value: T? {
        get {
            var result: T? = nil
            queue.sync {
                result = _value
            }
            return result
        }
        set {
            queue.sync {
                _value = newValue
                valueUpdated?(_value)
            }
        }
    }
}
