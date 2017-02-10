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

public extension EventualResult {
    /// Transforms successful values from one type to another
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result will be delivered on. defaults to main
    ///   - transform: Closure to attempt to transform `ValueType` to another type
    /// - Returns: A new `EventualResult` with the new value if successful, otherwise a failed `EventualResult` with the reason
    func map<U>(deliverOn queue: DispatchQueue = .main, _ transform: @escaping (ValueType) throws -> U) -> EventualResult<U> {
        return EventualResult<U> { resolver in
            resolver.onCancel = self.cancel

            self.execute(deliverOn: queue) { result in
                do {
                    resolver.resolve(with: try transform(try result.value()))

                } catch {
                    resolver.resolve(with: error)
                }
            }
        }
    }

    /// Transforms successful values from one type to another
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result will be delivered on. defaults to main
    ///   - transform: Closure to attempt to transform `ValueType` to another `Result` type
    /// - Returns: A new `EventualResult` with the new value if successful, otherwise a failed `EventualResult` with the reason
    func map<U>(completeOn queue: DispatchQueue = .main, _ transform: @escaping (ValueType) throws -> Result<U>) -> EventualResult<U> {
        return EventualResult<U> { resolver in
            resolver.onCancel = self.cancel

            self.execute(deliverOn: queue) { result in
                resolver.resolve(with: result.flatMap(transform))
            }
        }
    }
}
