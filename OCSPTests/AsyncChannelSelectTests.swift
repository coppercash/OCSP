//
//  AsyncChannelSelectTests.swift
//  OCSPTests
//
//  Created by William on 05/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

import XCTest

class AsyncChannelSelectTests: XCTestCase {
    typealias
        Chan = OCSPAsyncReadWriteChannel
    let
        Select = OCSPAsyncSelect
    func
        test_aDoneReceivingCancelsOtherReceivings() {
        let
        c0 = Chan<NSNumber>(),
        c1 = Chan<NSNumber>()
        let
        ex0r = expectation(description: "0r"),
        ex0s = expectation(description: "0s"),
        ex1r = expectation(description: "1r"),
        ex1s = expectation(description: "1s")
        var
        v0 = 0,
        v1 = 0
        
        Select {
            c0.receive(in: $0) { _ in
                v0 = -1
            }
            c1.receive(in: $0) {
                if !$1 { return }
                v1 = $0!.intValue
                ex1r.fulfill()
            }
        }
        c0.receive {
            if !$1 { return }
            v0 = $0!.intValue
            ex0r.fulfill()
        }
        c1.send(421) {
            if !$0 { return }
            ex1s.fulfill()
            c0.send(420) {
                if !$0 { return }
                ex0s.fulfill()
            }
        }
        wait(for: [ex0r, ex0s, ex1r, ex1s], timeout: 1.0)
        XCTAssertEqual(v0, 420)
        XCTAssertEqual(v1, 421)
    }
    func
    test_aDoneSendingCancelsOtherSendings()
    {
        let
        c0 = Chan<NSNumber>(),
        c1 = Chan<NSNumber>()
        let
        ex0r = expectation(description: "0r"),
        ex0s = expectation(description: "0s"),
        ex1r = expectation(description: "1r"),
        ex1s = expectation(description: "1s")
        var
        v0 = 0,
        v1 = 0
        
        Select {
            c0.send(-1, in: $0, with: { _ in
                v0 = -1
            })
            c1.send(421, in: $0, with: {
                if !$0 { return }
                ex1s.fulfill()
            })
        }
        c0.send(420, with: {
            if !$0 { return }
            ex0s.fulfill()
        })
        c1.receive {
            if !$1 { return }
            v1 = Int($0!)
            ex1r.fulfill()
            c0.receive {
                if !$1 { return }
                v0 = Int($0!)
                ex0r.fulfill()
            }
        }
        wait(for: [ex0r, ex0s, ex1r, ex1s], timeout: 1.0)
        XCTAssertEqual(v0, 420)
        XCTAssertEqual(v1, 421)
    }
    func
    test_defaultCancelsAllOtherTries()
    {
        let
        c0 = Chan<NSNumber>(),
        c1 = Chan<NSNumber>()
        let
        ex0r = expectation(description: "0r"),
        ex0s = expectation(description: "0s"),
        ex1r = expectation(description: "1r"),
        ex1s = expectation(description: "1s")
        var
        v0 = 0,
        v1 = 0
        Select {
            c0.receive(in: $0) { _ in
                v0 = -1
            }
            c1.send(421, in: $0, with: { _ in
                v1 = -1
            })
            $0.default {
                c0.send(4200, with: {
                    if !$0 { return }
                    ex0s.fulfill()
                })
                c1.receive {
                    if !$1 { return }
                    v1 = Int($0!)
                    ex1r.fulfill()
                }
                c0.receive {
                    if !$1 { return }
                    v0 = Int($0!)
                    ex0r.fulfill()
                }
                c1.send(4211, with: {
                    if !$0 { return }
                    ex1s.fulfill()
                })
            }
        }
        wait(for: [ex0r, ex0s, ex1r, ex1s], timeout: 1.0)
        XCTAssertEqual(v0, 4200)
        XCTAssertEqual(v1, 4211)
    }
    func
        test_inSelectSendToReceivingsBefore()
    {
        let
        c0 = Chan<NSNumber>()
        let
        ex0s = expectation(description: "0s"),
        ex0r = expectation(description: "0r")
        var
        v0 = 0
        c0.receive {
            if !$1 { return }
            v0 = Int($0!)
            ex0r.fulfill()
        }
        Select {
            c0.send(42, in: $0, with: {
                if !$0 { return }
                ex0s.fulfill()
            })
            $0.default {
                v0 = -1
            }
        }
        wait(for: [ex0r, ex0s], timeout: 1.0)
        XCTAssertEqual(v0, 42)
    }
    func
        test_inSelectReceiveFromSendingsBefore()
    {
        let
        c0 = Chan<NSNumber>()
        let
        ex0s = expectation(description: "0s"),
        ex0r = expectation(description: "0r")
        var
        v0 = 0
        c0.send(42, with: {
            if !$0 { return }
            ex0s.fulfill()
        })
        Select {
            c0.receive(in: $0) {
                if !$1 { return }
                v0 = Int($0!)
                ex0r.fulfill()
            }
            $0.default {
                v0 = -1
            }
        }
        wait(for: [ex0r, ex0s], timeout: 1.0)
        XCTAssertEqual(v0, 42)
    }
    func
        test_closeCancelReceivingSelection()
    {
        let
        c0 = Chan<NSNumber>()
        let
        ex0s = expectation(description: "0s"),
        ex0r = expectation(description: "0r")
        var
        v0 = NSNumber?(0)
        Select {
            c0.receive(in: $0) {
                if $1 { return }
                v0 = $0
                ex0r.fulfill()
            }
        }
        c0.close {
            if !$0 { return }
            ex0s.fulfill()
        }
        wait(for: [ex0r, ex0s], timeout: 1.0)
        XCTAssertNil(v0)
    }
    func
        test_closeCancelSendingSelection()
    {
        let
        c0 = Chan<NSNumber>()
        let
        ex0s = expectation(description: "0s"),
        ex0r = expectation(description: "0r")
        Select {
            c0.send(42, in: $0) {
                if $0 { return }
                ex0s.fulfill()
            }
        }
        c0.close {
            if !$0 { return }
            ex0r.fulfill()
        }
        wait(for: [ex0r, ex0s], timeout: 1.0)
    }
    func
        test_sendWithReceivingsOnSameChannel()
    {
        let
        c0 = Chan<NSNumber>()
        let
        ex0s = expectation(description: "0s"),
        ex0r = expectation(description: "0r")
        var
        v0 = 0;
        Select {
            c0.send(42, in: $0) {
                if !$0 { return }
                ex0s.fulfill()
            }
            c0.receive(in: $0) { _ in
                v0 = -1
            }
        }
        c0.receive {
            if !$1 { return }
            ex0r.fulfill()
            v0 = Int($0!)
        }
        wait(for: [ex0r, ex0s], timeout: 1.0)
        XCTAssertEqual(v0, 42)
    }
    func
        test_receiveWithSendingsOnSameChannel()
    {
        let
        c0 = Chan<NSNumber>()
        let
        ex0s = expectation(description: "0s"),
        ex0r = expectation(description: "0r")
        var
        v0 = 0;
        Select {
            c0.send(-1, in: $0) { _ in
                v0 = -1
            }
            c0.receive(in: $0) {
                if !$1 { return }
                v0 = Int($0!)
                ex0r.fulfill()
            }
        }
        c0.send(42) {
            if !$0 { return }
            ex0s.fulfill()
        }
        wait(for: [ex0r, ex0s], timeout: 1.0)
        XCTAssertEqual(v0, 42)
    }
}
