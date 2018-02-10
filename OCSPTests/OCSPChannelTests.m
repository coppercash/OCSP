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
@property (nonatomic, strong) dispatch_queue_t cq;
@property (nonatomic, assign) dispatch_time_t nano;
@end
@implementation OCSPChannelTests

- (void)setUp
{
    [super setUp];
    _cq = dispatch_queue_create(NSStringFromSelector(_cmd).UTF8String, DISPATCH_QUEUE_CONCURRENT);
    _nano = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC);
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
        dispatch_after(self.nano, self.cq, ^{
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
        dispatch_after(self.nano, self.cq, ^{
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

- (void)test_rejectSendingsAfterClosing
{
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    [ch close];
    BOOL
    ok = [ch send:@42];
    XCTAssertFalse(ok);
}

- (void)test_rejectSendingsWaitingForReceivingOnClosing
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

- (void)test_rejectReceivingsAfterClosing
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

- (void)test_rejectReceivingsWaitingForSendingOnClosing
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

- (void)test_rejectReceivingsOnDeallocating
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"receive"];
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    BOOL __block
    ok = YES;
    NSNumber __block *
    value = nil;
    OCSPReadWriteChannel<NSNumber *> __weak *
    p = ch;
    dispatch_async(self.cq, ^{
        ok = [p receive:&value];
        [ex fulfill];
    });
    ch = nil;
    [self waitForExpectations:@[ex]
                      timeout:1.0];
    XCTAssertFalse(ok);
    XCTAssertNil(value);
}

- (void)test_performance
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"receive"];
    OCSPReadWriteChannel<NSNumber *> *
    ch = [[OCSPReadWriteChannel alloc] init];
    dispatch_async(self.cq, ^{
        while (
               [ch receive:NULL]
               ) { }
        [ex fulfill];
    });
    [self measureBlock:^{
        for (
             NSInteger
             i = 0;
             i < 1000;
             i += 1
             ) {
            [ch send:@1];
        }
    }];
    [ch close];
    [self waitForExpectations:@[ex]
                      timeout:10.0];
}

@end
