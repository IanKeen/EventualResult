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
    /// Create a single `EventualResult<ValueType>` from a `Sequence` of `EventualResult<ValueType>`s
    /// The first `EventualResult` to complete will become the result (regardless of success or failure)
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result will be delivered on. defaults to main
    ///   - operations: The `Sequence` of `EventualResult<ValueType>`s to execute
    /// - Returns: A new `EventualResult` that returns the result of the first `EventualResult` to complete
    static func first<S: Sequence>(
        deliverOn queue: DispatchQueue = .main,
        operations: S
        ) -> EventualResult<ValueType>
        where S.Iterator.Element: EventualResultType, S.Iterator.Element.Value == ValueType
    {
        return operations.first(deliverOn: queue)
    }
}

extension Sequence where Iterator.Element: EventualResultType {
    /// Create a single `EventualResult<ValueType>` from this `Sequence` of `EventualResult<ValueType>`s
    /// The first `EventualResult` to complete will become the result (regardless of success or failure)
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result will be delivered on. defaults to main
    /// - Returns: A new `EventualResult` that returns the result of the first `EventualResult` to complete
    func first(deliverOn queue: DispatchQueue = .main) -> EventualResult<Iterator.Element.Value> {
        return EventualResult<Iterator.Element.Value> { resolver in

            func cancelAll() {
                self.forEach { $0.cancel() }
            }
            resolver.onCancel = cancelAll

            let lockQueue = DispatchQueue(label: "queue.first")
            var value: Result<Iterator.Element.Value>?

            func complete(with result: Result<Iterator.Element.Value>) {
                guard value == nil else { return }

                value = result

                cancelAll()

                queue.async {
                    resolver.resolve(with: result)
                }
            }

            for operation in self {
                operation.execute(deliverOn: lockQueue, complete)
            }
        }
    }
}
