import XCTest
@testable import EventualResultTests

XCTMain([
    testCase(EventualResultTests.allTests),
    testCase(EventualResultSequenceTests.allTests),
    testCase(ResultTests.allTests),
])
