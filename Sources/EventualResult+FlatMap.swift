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
    /// Transforms successful values into a new `EventualResult`
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result will be delivered on. defaults to main
    ///   - transform: Closure to attempt to transform `ValueType` into a new `EventualResult`
    /// - Returns: A new `EventualResult` if sucessful, otherwise a failed `EventualResult` with the reason
    func flatMap<U>(deliverOn queue: DispatchQueue = .main, _ transform: @escaping (ValueType) throws -> EventualResult<U>) -> EventualResult<U> {
        return EventualResult<U> { resolver in
            resolver.onCancel = self.cancel

            self.execute(deliverOn: queue) { result in
                do {
                    let new = try transform(try result.value())
                    resolver.onCancel = new.cancel
                    new.execute(deliverOn: queue) { resolver.resolve(with: $0) }

                } catch {
                    resolver.resolve(with: error)
                }
            }
        }
    }
}
