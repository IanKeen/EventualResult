import XCTest
import EventualResult

enum TestError: Error, Equatable {
    case error

    static func ==(lhs: TestError, rhs: TestError) -> Bool {
        return true
    }
}
