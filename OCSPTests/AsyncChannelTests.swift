//
//  OCSPAsyncChannelTests.swift
//  OCSPTests
//
//  Created by William on 25/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

import XCTest

class AsyncChannelTests: XCTestCase {
    typealias
        Chan = OCSPAsyncReadWriteChannel
    typealias
        Builder = AsyncChannelTestCaseBuilder
    func
        test_receiveValueAfterSending
        () {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .send(42, true)
            .receive(42, true)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_sendValueAfterReceiving
        () {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .receive(42, true)
            .send(42, true)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_rejectReceivingsAfterClosing
        () {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .close(true)
            .receive(nil, false)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_rejectReceivingsWaitingForSendingOnClosing
        () {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .receive(nil, false)
            .close(true)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_rejectSendingAfterClosing
        () {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .close(true)
            .send(42, false)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_rejectSendingWaitingForReceivingOnClosing() {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .send(42, false)
            .close(true)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_makeSendingsWait()
    {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .send(0, true)
            .send(1, true)
            .send(2, true)
            .receive(0, true)
            .receive(1, true)
            .send(3, true)
            .receive(2, true)
            .receive(3, true)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_makeReceivingsWait() {
        let
        chan = Chan<NSNumber>()
        var
        c = Builder()
            .receive(0, true)
            .receive(1, true)
            .receive(2, true)
            .send(0, true)
            .send(1, true)
            .receive(3, true)
            .send(2, true)
            .send(3, true)
            .build(chan, self)
        XCTAssertEqual(c.run(), c.answer)
    }
    func
        test_rejectReceivingsOnDeallocating
        () {
        var
        chan :Chan<NSNumber> = Chan()
        var
        c = Builder()
            .receive(nil, false)
            .build(chan, self)
        c.start()
        chan = Chan()
        c.wait()
        XCTAssertEqual(c.result, c.answer)
    }
    func
        test_workInParallelEnvironment()
    {
        let
        chan = Chan<NSNumber>(),
        cbQ = DispatchQueue(label: #function)
        var
        exps = [XCTestExpectation](),
        result = 0
        for
            i in 0..<100
        {
            let
            sExp = expectation(description: "\(i)")
            exps.append(sExp)
            DispatchQueue.global().async {
                chan.send(i as NSNumber, on: cbQ) {
                    guard
                        $0
                        else { return }
                    sExp.fulfill()
                }
            }
            let
            rExp = expectation(description: "\(i)")
            exps.append(rExp)
            DispatchQueue.global().async {
                chan.receive(on: cbQ) {
                    guard
                        $1
                        else { return }
                    result += Int($0!)
                    rExp.fulfill()
                }
            }
        }
        wait(for: exps, timeout: 1.0)
        XCTAssertEqual(result, (0..<100).reduce(0) { $0 + $1 })
    }
}
