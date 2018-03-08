//
//  AsyncChannelTestCase.swift
//  OCSPTests
//
//  Created by William on 25/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

import XCTest

class
    ArrayRef<Element>
{
    typealias
    Array = [Element]
    var
    array :Array = []
    subscript(idx :Array.Index) ->Element {
        get {
            return array[idx]
        }
        set {
            array[idx] = newValue
        }
    }
    func
        append(_ newElement :Element) {
        array.append(newElement)
    }
    init(repeating element :Element, count :Int) {
        self.array = Array(repeating: element, count: count)
    }
    init() {
        self.array = []
    }
}

struct
    AsyncChannelTestCase<Data>
    where
    Data : Equatable
{
    typealias
        Action = TestCaseAction<Data>
    typealias
        Result = [Action]
    let
    answer :Result
    var
    buffer :ArrayRef<Action?>,
    expectations :ArrayRef<XCTestExpectation>
    typealias
        Test = (ArrayRef<Action?>, ArrayRef<XCTestExpectation>) ->Void
    var
    test : Test!
    typealias
        Expect = ([XCTestExpectation]) ->Void
    var
    expect : Expect!
    init(
        _ answer :Result,
        _ test : @escaping Test,
        _ expect : @escaping Expect
        ) {
        self.answer = answer
        self.test = test
        self.expect = expect
        self.buffer = ArrayRef<Action?>(repeating: nil, count: answer.count)
        self.expectations = ArrayRef()
    }
    var
    result :Result {
        var
        result = [Action]()
        for
            act in buffer.array
        {
            guard let
                act = act
                else { continue }
            result.append(act)
        }
        return result
    }
    mutating func
        start()
    {
        test(buffer, expectations)
        test = nil
    }
    mutating func
        wait()
    {
        expect(expectations.array)
        expect = nil
    }
    mutating func
        run() ->Result
    {
        start()
        wait()
        return result
    }
}

struct
    TestCaseAction<Data> : Equatable, CustomStringConvertible
    where
    Data : Equatable
{
    enum
        ActionType
    {
        case
        send, receive, close
    }
    let
    type :ActionType,
    data :Data?,
    ok :Bool
    init
        (_ type :ActionType, _ ok :Bool, _ data :Data?)
    {
        self.type = type
        self.ok = ok
        self.data = data
    }
    typealias
        Action = TestCaseAction<Data>
    static func
        send(_ ok: Bool, _ data :Data?) ->Action
    {
        return self.init(.send, ok, data)
    }
    static func
        receive(_ ok: Bool, _ data :Data?) ->Action
    {
        return self.init(.receive, ok, data)
    }
    static func
        close(_ ok: Bool) ->Action
    {
        return self.init(.close, ok, nil)
    }
    var
    description :String {
        let
        act :String
        switch type {
        case .send:
            act = "Send"
        case .receive:
            act = "Receive"
        case .close:
            act = "Close"
        }
        return "\(act)(\(ok ? "ok" : "rejected"), \(String(describing: data)))"
    }
    static func
        ==
        (
        lhs: TestCaseAction<Data>,
        rhs: TestCaseAction<Data>
        ) -> Bool {
        return lhs.type == rhs.type &&
            lhs.ok == rhs.ok &&
            lhs.data == rhs.data
    }
}

class
    AsyncChannelTestCaseBuilder<Data>
    where
    Data : AnyObject & Equatable
{
    typealias
        ChainNode = AsyncChannelTestCaseBuilder<Data>
    typealias
        Chan = OCSPAsyncReadWriteChannel<Data>
    typealias
        Act = TestCaseAction<Data>
    typealias
        TestCase = AsyncChannelTestCase<Data>
    typealias
        Test = (
        Chan,
        @escaping (Int, Act) -> Void,
        @escaping (Act) -> XCTestExpectation
        ) -> Void
    init() {}
    let
    callbackQ = DispatchQueue(label: "ocsp.aync_chan.test"),
    sendQ = DispatchQueue(label: "ocsp.aync_chan.test.send"),
    receiveQ = DispatchQueue(label: "ocsp.aync_chan.test.receive")
    var
    answer = [Act](),
    test :Test = { (_) in }
    func
        send(_ data :Data?, _ ok :Bool) ->ChainNode
    {
        let
        last = test,
        idx = answer.count,
        cbQ = callbackQ,
        q = sendQ,
        act = Act.send(ok, data)
        answer.append(act)
        test = { (chan, emit, expect) in
            last(chan, emit, expect);
            let
            exp = expect(act)
            q.async {
                q.suspend()
                chan.send(data, on: cbQ) {
                    emit(idx, Act.send($0, data))
                    q.resume()
                    exp.fulfill()
                }
            }
        }
        return self
    }
    func
        receive(_ data :Data?, _ ok :Bool) ->ChainNode
    {
        let
        last = test,
        idx = answer.count,
        cbQ = callbackQ,
        q = receiveQ,
        act = Act.receive(ok, data)
        answer.append(act)
        test = { (chan, emit, expect) in
            last(chan, emit, expect);
            let
            exp = expect(act)
            q.async {
                q.suspend()
                chan.receive(on: cbQ) {
                    emit(idx, Act.receive($1, $0))
                    q.resume()
                    exp.fulfill()
                }
            }
        }
        return self
    }
    func
        close(_ ok :Bool) ->ChainNode
    {
        let
        last = test,
        idx = answer.count,
        cbQ = callbackQ,
        act = Act.close(ok)
        answer.append(act)
        test = { (chan, emit, expect) in
            last(chan, emit, expect);
            let
            exp = expect(act)
            chan.close(on: cbQ) {
                emit(idx, Act.close($0))
                exp.fulfill()
            }
        }
        return self
    }
    func
        build(
        _ chan :Chan,
        _ context :XCTestCase
        ) ->TestCase
    {
        let
        test = self.test,
        answer = self.answer
        return TestCase(
            answer,
            {
                [unowned chan, unowned context]
                (
                buffer :ArrayRef<TestCase.Action?>,
                expectations :ArrayRef<XCTestExpectation>
                ) in
                test(
                    chan,
                    {
                        buffer[$0] = $1
                },
                    {
                        let
                        exp = context.expectation(description: "Expecting \($0)")
                        expectations.append(exp)
                        return exp
                }
                )
            },
            {
                [unowned context]
                (expectations :[XCTestExpectation]) in
                context.wait(for: expectations, timeout: 1.0)
            }
        )
    }
}
