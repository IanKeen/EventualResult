import Foundation
import XCTest
import EventualResult

class EventualResultTests: EventualResultTestCase {
    //MARK: - Init
    func testResultInit_Success() {
        let exp = self.expectation(description: "")

        let result = Result<String>("foo")
        let eventual = EventualResult<String>(result)

        eventual.execute { result in
            switch result {
            case .failure: XCTFail()
            case .success(let value): exp.fulfill(when: value == "foo")
            }
        }

        self.waitForExpectations(timeout: 0.5, handler: nil)
    }
    func testResultInit_Fail() {
        let exp = self.expectation(description: "")

        let result = Result<String>(TestError.error)
        let eventual = EventualResult<String>(result)

        eventual.execute { result in
            switch result {
            case .failure: exp.fulfill()
            case .success: XCTFail()
            }
        }

        self.waitForExpectations(timeout: 0.5, handler: nil)
    }
    func testFactoryInit_Success() {
        let (eventual, exp) = createEventual(result: Result<String>.success("foo"), delay: 1.0)

        eventual.execute { result in
            exp.fulfill(when: result, equals: "foo")
        }

        waitForExpectations(timeout: 1.5, handler: nil)
    }
    func testFactoryInit_Fail() {
        let (eventual, exp) = createEventual(result: Result<String>.failure(TestError.error), delay: 1.0)

        eventual.execute { result in
            exp.fulfill(when: result, failed: TestError.error)
        }

        waitForExpectations(timeout: 1.5, handler: nil)
    }

    //MARK: - Map
    func testMap_Simple() {
        let (eventual, exp) = createEventual(result: Result<Int>.success(42)) { e in
            return e.map { String($0) }
        }

        eventual.execute { result in
            exp.fulfill(when: result, equals: "42")
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }
    func testMap_Result() {
        let (eventual, exp) = createEventual(result: Result<Int>.success(42)) { e in
            return e.map { .success(String($0)) }
        }

        eventual.execute { result in
            exp.fulfill(when: result, equals: "42")
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    //MARK: - FlatMap
    func testFlatMap_Success() {
        let (eventual, exp) = createEventual(result: Result<Int>.success(42)) { e in
            return e.flatMap { self.createEventual(result: Result<String>.success(String($0))) }
        }

        eventual.execute { result in
            exp.fulfill(when: result, equals: "42")
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }
    func testFlatMap_Fail() {
        let (eventual, exp) = createEventual(result: Result<Int>.success(42)) { e in
            return e.flatMap { _ throws -> EventualResult<String> in throw TestError.error }
        }

        eventual.execute { result in
            exp.fulfill(when: result, failed: TestError.error)
        }

        waitForExpectations(timeout: 0.5, handler: nil)
    }

    //MARK: - Cancellation
    func testCancel() {
        var cancel: () -> Void = { XCTFail() }
        let (eventual, exp) = createEventual(
            result: Result<Int>.success(42),
            delay: 1.0,
            cancel: { cancel() }
        )
        cancel = exp.fulfill

        eventual.execute { result in
            if !result.isCancelled {
                XCTFail()
            }
        }

        DispatchQueue(label: "").asyncAfter(deadline: .now() + 0.5, execute: eventual.cancel)

        waitForExpectations(timeout: 1.5, handler: nil)
    }
    func testMapSimpleCancel() {
        var cancel: () -> Void = { XCTFail() }
        let (eventual, exp) = createEventual(
            result: Result<Int>.success(42),
            delay: 1.0,
            cancel: { cancel() },
            then: { $0.map { String($0) } }
        )
        cancel = exp.fulfill

        eventual.execute { result in
            if !result.isCancelled {
                XCTFail()
            }
        }

        DispatchQueue(label: "").asyncAfter(deadline: .now() + 0.5, execute: eventual.cancel)

        waitForExpectations(timeout: 1.5, handler: nil)
    }
    func testMapResultCancel() {
        var cancel: () -> Void = { XCTFail() }
        let (eventual, exp) = createEventual(
            result: Result<Int>.success(42),
            delay: 1.0,
            cancel: { cancel() },
            then: { e in e.map { .success(String($0)) } }
        )
        cancel = exp.fulfill

        eventual.execute { result in
            if !result.isCancelled {
                XCTFail()
            }
        }

        DispatchQueue(label: "").asyncAfter(deadline: .now() + 0.5, execute: eventual.cancel)

        waitForExpectations(timeout: 1.5, handler: nil)
    }
    func testFlatMapCancel_First() {
        var cancel: () -> Void = { XCTFail() }
        let (eventual, exp) = createEventual(
            result: Result<Int>.success(42),
            delay: 1.0,
            cancel: { cancel() },
            then: { e in
                return e.flatMap {
                    self.createEventual(
                        result: Result<String>.success(String($0)),
                        delay: 1.0,
                        cancel: { XCTFail() }
                    )
                }
            }
        )
        cancel = exp.fulfill

        eventual.execute { result in
            if !result.isCancelled {
                XCTFail()
            }
        }

        DispatchQueue(label: "").asyncAfter(deadline: .now() + 0.5, execute: eventual.cancel)

        waitForExpectations(timeout: 1.5, handler: nil)
    }
    func testFlatMapCancel_Second() {
        var cancel: () -> Void = { XCTFail() }
        let (eventual, exp) = createEventual(
            result: Result<Int>.success(42),
            delay: 1.0,
            cancel: { XCTFail() },
            then: { e in
                return e.flatMap {
                    self.createEventual(
                        result: Result<String>.success(String($0)),
                        delay: 1.0,
                        cancel: { cancel() }
                    )
                }
            }
        )
        cancel = exp.fulfill

        eventual.execute { result in
            if !result.isCancelled {
                XCTFail()
            }
        }

        DispatchQueue(label: "").asyncAfter(deadline: .now() + 1.5, execute: eventual.cancel)

        waitForExpectations(timeout: 2.5, handler: nil)
    }

}

#if os(Linux)
    extension EventualResultTests {
        static var allTests : [(String, (EventualResultTests) -> () throws -> Void)] {
            return [
                ("testResultInit_Success", testResultInit_Success),
                ("testResultInit_Fail", testResultInit_Fail),
                ("testFactoryInit_Success", testFactoryInit_Success),
                ("testFactoryInit_Fail", testFactoryInit_Fail),

                ("testMap_Simple", testMap_Simple),
                ("testMap_Result", testMap_Result),

                ("testFlatMap_Success", testFlatMap_Success),
                ("testFlatMap_Fail", testFlatMap_Fail),

                ("testCancel", testCancel),
                ("testMapSimpleCancel", testMapSimpleCancel),
                ("testMapResultCancel", testMapResultCancel),
                ("testFlatMapCancel_First", testFlatMapCancel_First),
                ("testFlatMapCancel_Second", testFlatMapCancel_Second),
            ]
        }
    }
#endif
