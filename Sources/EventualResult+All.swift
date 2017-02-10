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

/// Defines how a `Collection` of `EventualResult`s should be executed
///
/// - serially: One after the other. in order
/// - concurrently: All at the same time, order not guaranteed
public enum ExecutionMethod {
    case serially, concurrently
}

public extension EventualResult {
    /// Create a single `EventualResult<[ValueType]>` from a `Collection` of `EventualResult<ValueType>`s
    /// _All_ must succeed for the new `EventualResult` to succeed otherwise the first failure (if any) will become the result
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result and progress will be delivered on. defaults to main
    ///   - operations: The `Collection` of `EventualResult<ValueType>`s to execute
    ///   - execute: How to execute the `Collection` of operations
    ///   - progress: Provides a value from 0.0 to 1.0 representing the completion percentage of the operations
    /// - Returns: A new `EventualResult` that, upon success, will return an array of `ValueType`s otherwise it will return the first failure
    static func all<C: Collection>(
        deliverOn queue: DispatchQueue = .main,
        operations: C,
        execute: ExecutionMethod = .concurrently,
        progress: ((Float) -> Void)? = nil
        ) -> EventualResult<[ValueType]>
        where C.Iterator.Element: EventualResultType, C.Iterator.Element.Value == ValueType, C.SubSequence: Sequence, C.SubSequence.Iterator.Element == C.Iterator.Element
    {
        return operations.all(deliverOn: queue, execute: execute, progress: progress)
    }
}

extension Collection where Iterator.Element: EventualResultType, SubSequence: Sequence, SubSequence.Iterator.Element == Iterator.Element {
    /// Create a single `EventualResult<[ValueType]>` from this `Collection` of `EventualResult<ValueType>`s
    /// _All_ must succeed for the new `EventualResult` to succeed otherwise the first failure (if any) will become the result
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result and progress will be delivered on. defaults to main
    ///   - execute: How to execute the `Collection` of operations
    ///   - progress: Provides a value from 0.0 to 1.0 representing the completion percentage of the operations
    /// - Returns: A new `EventualResult` that, upon success, will return an array of `ValueType`s otherwise it will return the first failure
    func all(
        deliverOn queue: DispatchQueue = .main,
        execute: ExecutionMethod = .concurrently,
        progress: ((Float) -> Void)? = nil
        ) -> EventualResult<[Iterator.Element.Value]>
    {
        var started: Float = self.reduce(0) { $0.0 + 1 }
        var ended: Float = 0

        func itemEnd() {
            ended = ended + 1
            queue.async {
                progress?(ended / started)
            }
        }
        func completed() {
            queue.async { progress?(1) }
        }

        switch execute {
        case .concurrently:
            return self.allConcurrently(
                deliverOn: queue, itemEnd: itemEnd, completed: completed
            )
        case .serially:
            self.forEach { _ in started = started + 1 }
            return self.allSerially(
                deliverOn: queue, itemEnd: itemEnd, completed: completed
            )
        }
    }
}

// MARK: - Private Implementations
private extension Collection where Iterator.Element: EventualResultType, SubSequence: Sequence, SubSequence.Iterator.Element == Iterator.Element {
    func allSerially(
        deliverOn queue: DispatchQueue = .main,
        itemEnd: @escaping () -> Void,
        completed: @escaping () -> Void
        ) -> EventualResult<[Iterator.Element.Value]>
    {
        guard let head = self.first else { return EventualResult([]) }

        return head.flatMap(deliverOn: queue) { value in
            itemEnd()

            let tail = Array(self.dropFirst())
            if tail.isEmpty {
                completed()
                return EventualResult([value])

            } else {
                return tail
                    .allSerially(deliverOn: queue, itemEnd: itemEnd, completed: completed)
                    .map { [value] + $0 }
            }
        }
    }

    func allConcurrently(
        deliverOn queue: DispatchQueue = .main,
        itemEnd: @escaping () -> Void,
        completed: @escaping () -> Void
        ) -> EventualResult<[Iterator.Element.Value]>
    {
        guard !self.isEmpty else { return EventualResult([]) }

        return EventualResult { resolver in

            var values: [Iterator.Element.Value?] = self.map { _ in .none }

            func cancelAll() {
                self.forEach { $0.cancel() }
            }
            resolver.onCancel = cancelAll

            let lockQueue = DispatchQueue(label: "queue.all")

            for (index, operation) in self.enumerated() {
                operation.execute(deliverOn: lockQueue) { result in
                    itemEnd()

                    switch result {
                    case .failure(let error):
                        cancelAll()
                        completed()

                        queue.async {
                            resolver.resolve(with: error)
                        }

                    case .success(let value):
                        values[index] = value

                        let complete = values.first(where: { $0 == nil }) == nil
                        guard complete else { return }

                        completed()
                        
                        queue.async {
                            resolver.resolve(with: Result(values.flatMap { $0 }))
                        }
                    }
                }
            }
        }
    }
}
