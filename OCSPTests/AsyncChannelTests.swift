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
        test_rejectSendingWaitingForReceivingOnClosing
        () {
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
}
