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

public final class EventualResultResolver<ValueType> {
    typealias ResolutionClosure = (Result<ValueType>) -> Void

    // MARK: - Internal Properties
    internal let resolution = SynchronizedBox<Result<ValueType>>()

    // MARK: - Public Properties
    public var onCancel: (() -> Void)?

    // MARK: - Lifecycle
    init(resolved: @escaping ResolutionClosure) {
        resolution.valueUpdated = { result in
            guard let result = result else { return }
            resolved(result)
        }
    }

    // MARK: - Public Functions
    public func resolve(with value: ValueType) {
        resolve(with: .init(value))
    }
    public func resolve(with error: Error) {
        resolve(with: .init(error))
    }
    public func resolve(with result: Result<ValueType>) {
        guard resolution.value == nil else { return }

        onCancel = nil
        resolution.value = result
    }
    public func cancel() {
        onCancel?()
        resolve(with: EventualResultError.cancelled)
    }
}
