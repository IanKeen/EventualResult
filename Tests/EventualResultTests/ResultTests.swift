import XCTest
import EventualResult

class ResultTests: XCTestCase {
    //MARK: - Init
    func testResult_InitValue() {
        let result = Result<Int>(42)
        result.assertSuccess(42)
    }
    func testResult_InitError() {
        let result = Result<Int>(TestError.error)
        result.assertFailure(TestError.error)
    }
    func testResult_InitClosure_Value() {
        let result = Result<Int>({ 42 })
        result.assertSuccess(42)
    }
    func testResult_InitClosure_Error() {
        let result = Result<Int>({ throw TestError.error })
        result.assertFailure(TestError.error)
    }

    //MARK: - Map
    func testResult_Map_Value() {
        let result = Result<Int>(42).map { String($0 * 2) }
        result.assertSuccess("84")
    }
    func testResult_Map_Throws() {
        let result = Result<Int>(42)
        result.assertSuccess(42)

        let map = result.map { _ in throw TestError.error }
        map.assertFailure(TestError.error)
    }
    func testResult_Map_AlreadyFailed() {
        let result = Result<Int>({ throw TestError.error })
        result.assertFailure(TestError.error)

        let map = result.map { $0 + 1 }
        map.assertFailure(TestError.error)
    }

    //MARK: - FlatMap
    func testResult_FlatMap_Value() {
        let result = Result<Int>(42)
        result.assertSuccess(42)

        let flatMap = result.flatMap { .success(String($0 * 2)) }
        flatMap.assertSuccess("84")
    }
    func testResult_FlatMap_Throws() {
        let result = Result<Int>(42)
        result.assertSuccess(42)

        let flatMap = result.flatMap { _ -> Result<String> in throw TestError.error }
        flatMap.assertFailure(TestError.error)
    }
    func testResult_FlatMap_AlreadyFailed() {
        let result = Result<Int>({ throw TestError.error })
        result.assertFailure(TestError.error)

        let flatMap = result.flatMap { .success(String($0 * 2)) }
        flatMap.assertFailure(TestError.error)
    }
}

#if os(Linux)
    extension ResultTests {
        static var allTests : [(String, (ResultTests) -> () throws -> Void)] {
            return [
                ("testResult_InitValue", testResult_InitValue),
                ("testResult_InitError", testResult_InitError),
                ("testResult_InitClosure_Value", testResult_InitClosure_Value),
                ("testResult_InitClosure_Error", testResult_InitClosure_Error),

                ("testResult_Map_Value", testResult_Map_Value),
                ("testResult_Map_Throws", testResult_Map_Throws),
                ("testResult_Map_AlreadyFailed", testResult_Map_AlreadyFailed),

                ("testResult_FlatMap_Value", testResult_FlatMap_Value),
                ("testResult_FlatMap_Throws", testResult_FlatMap_Throws),
                ("testResult_FlatMap_AlreadyFailed", testResult_FlatMap_AlreadyFailed),
            ]
        }
    }
#endif

