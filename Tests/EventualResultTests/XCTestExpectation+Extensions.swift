import XCTest
import EventualResult

extension XCTestExpectation {
    func fulfill(when predicate: @autoclosure () -> Bool) {
        if predicate() {
            self.fulfill()
        } else {
            XCTFail("Provided predicate was false")
        }
    }
    func fulfill<T>(when result: Result<T>, equals: (T) -> Bool) {
        let value = result.map(equals)

        switch value {
        case .failure:
            XCTFail("Was not expecting an error")

        case .success(let value):
            if value { self.fulfill() }
            else { XCTFail("Provided value was false") }
        }
    }


    func fulfill<T>(when result: Result<T>, equals expected: T) where T: Equatable {
        switch result {
        case .failure:
            XCTFail("Was not expecting an error")

        case .success(let value):
            if value == expected { self.fulfill() }
            else { XCTFail("Expected: \(expected), got: \(value)") }
        }
    }

    func fulfill<T, U: Error>(when result: Result<T>, failed error: U) {
        switch result {
        case .success:
            XCTFail(" Was not expecting success")

        case .failure(let e):
            if error.localizedDescription == e.localizedDescription { self.fulfill() }
            else { XCTFail("Expected: \(error), got: \(e)") }
        }
    }

}
