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

/// Represents a _lazy_ `Result<ValueType>` that will be eventually contain a value in the future
/// No code is executed until `.execute` is called
public final class EventualResult<ValueType> {
    public typealias OperationClosure = (EventualResultResolver<ValueType>) throws -> Void
    public typealias ExecutionClosure = (Result<ValueType>) -> Void

    // MARK: - Private Properties
    private let operation: OperationClosure
    private let resolver = SynchronizedBox<EventualResultResolver<ValueType>>()

    // MARK: - Lifecycle
    public init(_ operation: @escaping OperationClosure) {
        self.operation = operation
    }
    public convenience init(_ result: Result<ValueType>) {
        self.init { $0.resolve(with: result) }
    }
    public convenience init(_ value: ValueType) {
        self.init(Result<ValueType>(value))
    }
    public convenience init(_ error: Error) {
        self.init(Result<ValueType>(error))
    }
    deinit { self.cancel() }

    // MARK: - Public
    /// Execute the operation and wait for the `Result<ValueType>`
    ///
    /// - Parameters:
    ///   - queue: `DispatchQueue` the result will be delivered on. defaults to main
    ///   - result: Callback providing a `Result<ValueType>` representing the result
    public func execute(deliverOn queue: DispatchQueue = .main, _ result: @escaping ExecutionClosure) {
        let complete = { value in
            queue.async { result(value) }
        }

        if let resolver = self.resolver.value {
            if let resolution = resolver.resolution.value {
                return complete(resolution)

            } else {
                print("WARNING: Attempted to execute an already running, yet unresolved, EventualResult. Ignored.")
                return
            }
        }

        let resolver = EventualResultResolver<ValueType> { resolution in
            complete(resolution)
        }
        self.resolver.value = resolver

        do { try operation(resolver) }
        catch { complete(Result<ValueType>(error)) }

    }

    /// Cancels the `EventualResult`s underlying operation when possible
    public func cancel() {
        guard let resolver = resolver.value else { return }
        
        resolver.cancel()
    }
}
