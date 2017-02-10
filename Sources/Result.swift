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

/// Generic type representing the outcome of an operation
///
/// - success: A successful outcome with the associated value
/// - fail: An unsucessful output with the associated error
public enum Result<ValueType> {
    case success(ValueType)
    case failure(Error)
}

//MARK: - Creation
public extension Result {
    /// Create a successful result
    ///
    /// - Parameter value: Successful value
    init(_ value: ValueType) {
        self = .success(value)
    }

    /// Create a failed result
    ///
    /// - Parameter error: Failure error
    init(_ error: Error) {
        self = .failure(error)
    }

    /// Creates a result from a closure that may succeed or fail
    ///
    /// - Parameter closure: Closure used to attempt to obtain result value
    init(_ closure: () throws -> ValueType) {
        do { self = .success(try closure()) }
        catch let error { self = .failure(error) }
    }
}

//MARK: - Values
public extension Result {
    /// Attempt to obtain the `ValueType` from this `Result`
    ///
    /// - Returns: The `ValueType` is this `Result` was successful
    /// - Throws: The `Error` if this `Result` failed
    func value() throws -> ValueType {
        switch self {
        case .failure(let error): throw error
        case .success(let value): return value
        }
    }
}

//MARK: - State
public extension Result {
    /// Returns `true` if the `Result` was successful, otherwise `false`
    var isSuccess: Bool {
        switch self {
        case .failure: return false
        case .success: return true
        }
    }

    /// Returns `true` if the `Result` failed, otherwise `true`
    var isFailure: Bool {
        switch self {
        case .failure: return true
        case .success: return false
        }
    }
}

//MARK: - Transformation
public extension Result {
    /// Transforms a successful value from `ValueType` to another type
    ///
    /// - Parameter transform: Closure to attempt to transform `ValueType` to another type
    /// - Returns: A new `Result` with the updated type if successful, otherwise a failed `Result` with the reason
    func map<T>(_ transform: (ValueType) throws -> T) -> Result<T> {
        return Result<T>({ try transform(try self.value()) })
    }

    /// Transforms a sucessful value from `ValueType` into a new `Result`
    ///
    /// - Parameter transform: Closure to attempt to transform `ValueType` into a new `Result`
    /// - Returns: A new `Result` if sucessful, otherwise a failed `Result` with the reason
    func flatMap<T>(_ transform: (ValueType) throws -> Result<T>) -> Result<T> {
        do {
            return try transform(try self.value())
        } catch let error {
            return .failure(error)
        }
    }
}
