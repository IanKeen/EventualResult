import XCTest
import EventualResult

extension Result {
    func assertSuccess() {
        XCTAssertTrue(self.isSuccess)
        XCTAssertFalse(self.isFailure)
    }
    func assertFailure() {
        XCTAssertTrue(self.isFailure)
        XCTAssertFalse(self.isSuccess)
    }
    func assertFailure<T: Error>(_ error: T) where T: Equatable {
        assertFailure()

        do {
            _ = try self.value()
        } catch let e as T {
            XCTAssertEqual(error, e)
        } catch {
            XCTFail()
        }
    }
}

extension Result where ValueType: Equatable {
    func assertSuccess(_ value: ValueType) {
        assertSuccess()

        switch self {
        case .failure: XCTFail()
        case .success(let v):
            XCTAssertEqual(v, value)
        }
    }
}
