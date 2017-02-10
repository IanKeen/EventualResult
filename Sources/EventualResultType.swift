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
public protocol EventualResultType {
    associatedtype Value

    typealias ExecutionClosure = (Result<Value>) -> Void

    func execute(deliverOn queue: DispatchQueue, _ result: @escaping ExecutionClosure)

    func cancel()

    func map<U>(deliverOn queue: DispatchQueue, _ transform: @escaping (Value) throws -> U) -> EventualResult<U>
    func map<U>(completeOn queue: DispatchQueue, _ transform: @escaping (Value) throws -> Result<U>) -> EventualResult<U>

    func flatMap<U>(deliverOn queue: DispatchQueue, _ transform: @escaping (Value) throws -> EventualResult<U>) -> EventualResult<U>
}

extension EventualResult: EventualResultType {
    public typealias Value = ValueType
}
