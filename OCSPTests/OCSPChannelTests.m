//
//  OCSPChannelTests.m
//  OCSPTests
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OCSP.h"

@interface OCSPChannelTests : XCTestCase
@end
@implementation OCSPChannelTests

- (dispatch_queue_t)cq
{
    return dispatch_queue_create(NSStringFromSelector(_cmd).UTF8String, DISPATCH_QUEUE_CONCURRENT);
}

- (dispatch_time_t)nano
{
    return dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC);
}

- (void)test_receiveValueAfterSending
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    sent = NO,
    received = NO;
    NSNumber __block *
    value = nil;
    dispatch_async(self.cq, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC), self.cq, ^{
            received = [ch receive:&value];
            [rEx fulfill];
        });
        [sEx fulfill];
        sent = [ch send:@42];
    });
    [self waitForExpectations:@[sEx, rEx]
                      timeout:1.0
                 enforceOrder:YES];
    XCTAssertTrue(received);
    XCTAssertTrue(sent);
    XCTAssertEqualObjects(value, @42);
}

- (void)test_receiveValueBeforeSending
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    sent = NO,
    received = NO;
    NSNumber __block *
    value = nil;
    dispatch_async(self.cq, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC), self.cq, ^{
            sent = [ch send:@42];
            [sEx fulfill];
        });
        [rEx fulfill];
        received = [ch receive:&value];
    });
    [self waitForExpectations:@[rEx, sEx]
                      timeout:1.0
                 enforceOrder:YES];
    XCTAssertTrue(received);
    XCTAssertTrue(sent);
    XCTAssertEqualObjects(value, @42);
}

- (void)test_rejectSendingAfterClosing
{
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    [ch close];
    BOOL
    ok = [ch send:@42];
    XCTAssertFalse(ok);
}

- (void)test_rejectSendingWaitingForReceivingOnClosing
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"send"];
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    ok = YES;
    dispatch_async(self.cq, ^{
        ok = [ch send:@42];
        [ex fulfill];
    });
    [ch close];
    [self waitForExpectations:@[ex]
                      timeout:1.0];
    XCTAssertFalse(ok);
}

- (void)test_rejectReceivingAfterClosing
{
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    [ch close];
    NSNumber *
    value = nil;
    BOOL
    ok = [ch receive:&value];
    XCTAssertFalse(ok);
    XCTAssertNil(value);
}

- (void)test_rejectReceivingWaitingForSendingOnClosing
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"receive"];
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    ok = YES;
    NSNumber __block *
    value = nil;
    dispatch_async(self.cq, ^{
        ok = [ch receive:&value];
        [ex fulfill];
    });
    [ch close];
    [self waitForExpectations:@[ex]
                      timeout:1.0];
    XCTAssertFalse(ok);
    XCTAssertNil(value);
}

@end
