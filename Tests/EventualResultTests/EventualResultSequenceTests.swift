import Foundation
import XCTest
import EventualResult

class EventualResultSequenceTests: EventualResultTestCase {

    //MARK: - First
    func testFirst_Success() {
        let exp = expectation(description: "")

        let first: EventualResult<String> = createEventual(result: .success("foo"), delay: 0.75)
        let second: EventualResult<String> = createEventual(result: .success("bar"), delay: 0.5)

        let eventual = EventualResult.first(operations: [first, second])
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result, equals: "bar")
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testFirst_Fail() {
        let exp = expectation(description: "")

        let first: EventualResult<String> = createEventual(result: .success("foo"), delay: 0.75)
        let second: EventualResult<String> = createEventual(result: .failure(TestError.error), delay: 0.5)

        let eventual = EventualResult.first(operations: [first, second])
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result, failed: TestError.error)
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
    func testFirst_CancelRightAway() {
        let exp = self.expectation(description: "")

        var cancelCount = 0
        func cancelled() {
            cancelCount = cancelCount + 1
        }

        let first: EventualResult<String> = createEventual(result: .success("foo"), delay: 0.5, cancel: cancelled)
        let second: EventualResult<String> = createEventual(result: .success("bar"), delay: 0.5, cancel: cancelled)

        let eventual = EventualResult.first(operations: [first, second])
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result.isCancelled && cancelCount == 2)
        }
        eventual.cancel()

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    //MARK: - All
    func testAll_Success() {
        let exp = expectation(description: "")

        let first: EventualResult<String> = createEventual(result: .success("foo"), delay: 1.5)
        let second: EventualResult<String> = createEventual(result: .success("bar"), delay: 0.5)

        var results: [String] = []
        func addResult(value: String) -> String {
            results.append(value)
            return value
        }

        let eventual = EventualResult<String>.all(operations: [
            first.map(addResult),
            second.map(addResult),
            ]
        )
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result, equals: { $0.sorted() == results.sorted() })
        }

        waitForExpectations(timeout: 2.75, handler: nil)
    }
    func testAll_Fail() {
        let exp = expectation(description: "")

        let first: EventualResult<String> = createEventual(result: .failure(TestError.error), delay: 1.5)
        let second: EventualResult<String> = createEventual(result: .success("bar"), delay: 0.5)

        let eventual = EventualResult.all(operations: [first, second])
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result, failed: TestError.error)
        }

        waitForExpectations(timeout: 2.75, handler: nil)
    }
    func testAll_CancelRightAway() {
        let exp = self.expectation(description: "")

        var cancelCount = 0
        func cancelled() {
            cancelCount = cancelCount + 1
        }

        let first: EventualResult<String> = createEventual(result: .success("foo"), delay: 1.5, cancel: cancelled)
        let second: EventualResult<String> = createEventual(result: .success("bar"), delay: 0.5, cancel: cancelled)

        let eventual = EventualResult.all(operations: [first, second])
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result.isCancelled && cancelCount == 2)
        }
        eventual.cancel()

        waitForExpectations(timeout: 2.75, handler: nil)
    }
    func testAll_CancelAfterFirst() {
        let exp = self.expectation(description: "")

        var cancelCount = 0
        func cancelled() {
            cancelCount = cancelCount + 1
        }

        let first: EventualResult<String> = createEventual(result: .success("foo"), delay: 1.5, cancel: cancelled)
        let second: EventualResult<String> = createEventual(result: .success("bar"), delay: 0.5, cancel: cancelled)

        let eventual = EventualResult.all(operations: [first, second])
        reference = eventual

        eventual.execute { result in
            exp.fulfill(when: result.isCancelled && cancelCount == 1)
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0, execute: eventual.cancel)
        waitForExpectations(timeout: 2.75, handler: nil)
    }
}

#if os(Linux)
    extension EventualResultSequenceTests {
        static var allTests : [(String, (EventualResultSequenceTests) -> () throws -> Void)] {
            return [
                ("testFirst_Success", testFirst_Success),
                ("testFirst_Fail", testFirst_Fail),
                ("testFirst_CancelRightAway", testFirst_CancelRightAway),

                ("testAll_Success", testAll_Success),
                ("testAll_Fail", testAll_Fail),
                ("testAll_CancelRightAway", testAll_CancelRightAway),
                ("testAll_CancelAfterFirst", testAll_CancelAfterFirst),
            ]
        }
    }
#endif
