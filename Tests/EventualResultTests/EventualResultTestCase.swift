//
//  EventualResultTestCase.swift
//  EventualResult
//
//  Created by Ian Keen on 2017-02-09.
//  Copyright © 2017 EventualResult. All rights reserved.
//

import XCTest
import EventualResult

class EventualResultTestCase: XCTestCase {
    var reference: Any?

    override func tearDown() {
        super.tearDown()
        reference = nil
    }

    func createEventual<T>(result: Result<T>, delay: Double = 0.0, cancel: (() -> Void)? = nil) -> EventualResult<T> {
        return EventualResult<T> { resolver in
            var item: DispatchWorkItem?
            resolver.onCancel = {
                cancel?()
                item?.cancel()
            }

            if delay > 0.0 {
                item = DispatchWorkItem { resolver.resolve(with: result) }
                DispatchQueue(label: "").asyncAfter(deadline: .now() + delay, execute: item!)

            } else {
                resolver.resolve(with: result)
            }
        }
    }
    func createEventual<T, U>(result: Result<T>, delay: Double = 0.0, cancel: (() -> Void)? = nil, then: (EventualResult<T>) -> EventualResult<U>) -> EventualResult<U> {
        let initial: EventualResult<T> = createEventual(result: result, delay: delay, cancel: cancel)
        let eventual = then(initial)
        return eventual
    }

    func createEventual<T>(result: Result<T>, delay: Double = 0.0, cancel: (() -> Void)? = nil) -> (EventualResult<T>, XCTestExpectation) {
        let exp = expectation(description: "")
        let eventual: EventualResult<T> = createEventual(result: result, delay: delay, cancel: cancel)
        reference = eventual
        return (eventual, exp)
    }
    func createEventual<T, U>(result: Result<T>, delay: Double = 0.0, cancel: (() -> Void)? = nil, then: (EventualResult<T>) -> EventualResult<U>) -> (EventualResult<U>, XCTestExpectation) {
        let exp = expectation(description: "")
        let eventual: EventualResult<U> = createEventual(result: result, delay: delay, cancel: cancel, then: then)
        reference = eventual
        return (eventual, exp)
    }
}
