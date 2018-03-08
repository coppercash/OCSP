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
        test_receivings() {
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
                c0.receive {
                    if !$1 { return }
                    v0 = $0!.intValue
                    ex0r.fulfill()
                    c1.receive { _ in
                        v1 = -1
                    }
                }
            }
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
    test_sendings()
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
            c0.send(420, in: $0, with: { _ in
                
            })
            c1.send(421, in: $0, with: {
                if !$0 { return }
                ex1s.fulfill()
                c0.receive {
                    if !$1 { return }
                    v0 = Int($0!)
                    ex0r.fulfill()
                }
            })
        }
        c1.receive {
            if !$1 { return }
            v1 = Int($0!)
            ex1r.fulfill()
            c0.send(420, with: {
                if !$0 { return }
                ex0s.fulfill()
            })
        }
        wait(for: [ex0r, ex0s, ex1r, ex1s], timeout: 1.0)
        XCTAssertEqual(v0, 420)
        XCTAssertEqual(v1, 421)
    }
    func
    test_default()
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
            c1.send(420, in: $0, with: { _ in
                v1 = -1
            })
            $0.default {
                c0.send(420, with: {
                    if !$0 { return }
                    ex0s.fulfill()
                })
                c0.receive {
                    if !$1 { return }
                    v0 = Int($0!)
                    ex0r.fulfill()
                }
                c1.send(421, with: {
                    if !$0 { return }
                    ex1s.fulfill()
                })
                c1.receive {
                    if !$1 { return }
                    v1 = Int($0!)
                    ex1r.fulfill()
                }
            }
        }
        wait(for: [ex0r, ex0s, ex1r, ex1s], timeout: 1.0)
        XCTAssertEqual(v0, 420)
        XCTAssertEqual(v1, 421)
    }
    
    // close & write & read & default
    // default
}