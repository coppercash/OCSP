//
//  OCSPTests.m
//  OCSPTests
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCSP.h"

@interface OCSPTests : XCTestCase

@end

@implementation OCSPTests

- (void)test_sendThenReceive
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    dispatch_queue_t
    qu = dispatch_queue_create(NSStringFromSelector(_cmd).UTF8String, DISPATCH_QUEUE_CONCURRENT);
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    ok = NO;
    NSNumber __block *
    value = nil;
    dispatch_async(qu, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC), qu, ^{
            ok = [ch receive:&value];
            [rEx fulfill];
        });
        [sEx fulfill];
        [ch send:@42];
    });
    [self waitForExpectations:@[sEx, rEx]
                      timeout:1.0
                 enforceOrder:YES];
    XCTAssertTrue(ok);
    XCTAssertEqualObjects(value, @42);
}

- (void)test_receiveThenSend
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    dispatch_queue_t
    qu = dispatch_queue_create(NSStringFromSelector(_cmd).UTF8String, DISPATCH_QUEUE_CONCURRENT);
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    ok = NO;
    NSNumber __block *
    value = nil;
    dispatch_async(qu, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC), qu, ^{
            [ch send:@42];
            [sEx fulfill];
        });
        [rEx fulfill];
        ok = [ch receive:&value];
    });
    [self waitForExpectations:@[rEx, sEx]
                      timeout:1.0
                 enforceOrder:YES];
    XCTAssertTrue(ok);
    XCTAssertEqualObjects(value, @42);
}

@end
