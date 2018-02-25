//
//  OCSPChannelTests.m
//  OCSPTests
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCSP/OCSP.h>
#import <sched.h>

@interface OCSPChannelTests : XCTestCase
@property (nonatomic, strong) dispatch_queue_t cQ;
@property (nonatomic, assign) dispatch_time_t nano;
@end
@implementation OCSPChannelTests

- (void)setUp
{
    [super setUp];
    _cQ = dispatch_queue_create(NSStringFromSelector(_cmd).UTF8String, DISPATCH_QUEUE_CONCURRENT);
    _nano = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_USEC);
}

- (void)test_receiveValueAfterSending
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    BOOL __block
    sent = NO,
    received = NO;
    NSNumber __block *
    value = nil;
    dispatch_async(self.cQ, ^{
        dispatch_after(self.nano, self.cQ, ^{
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
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    BOOL __block
    sent = NO,
    received = NO;
    NSNumber __block *
    value = nil;
    dispatch_async(self.cQ, ^{
        dispatch_after(self.nano, self.cQ, ^{
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
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    [ch close];
    BOOL
    ok = [ch send:@42];
    XCTAssertFalse(ok);
}

- (void)test_rejectSendingsWaitingForReceivingOnClosing
{
    XCTestExpectation *
    cEx = [self expectationWithDescription:@"close"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    BOOL __block
    ok = YES;
    dispatch_async(self.cQ, ^{
        dispatch_after(self.nano, self.cQ, ^{
            [ch close];
            [cEx fulfill];
        });
        ok = [ch send:@42];
        [sEx fulfill];
    });
    [self waitForExpectations:@[cEx, sEx]
                      timeout:1.0];
    XCTAssertFalse(ok);
}

- (void)test_rejectReceivingsAfterClosing
{
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
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
    cEx = [self expectationWithDescription:@"close"];
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"receive"];
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    BOOL __block
    ok = YES;
    NSNumber __block *
    value = nil;
    dispatch_async(self.cQ, ^{
        dispatch_after(self.nano, self.cQ, ^{
            [ch close];
            [cEx fulfill];
        });
        ok = [ch receive:&value];
        [rEx fulfill];
    });
    [self waitForExpectations:@[cEx, rEx]
                      timeout:1.0];
    XCTAssertFalse(ok);
    XCTAssertNil(value);
}

- (void)test_rejectReceivingsOnDeallocating
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"receive"];
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"release"];
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    BOOL __block
    ok = YES;
    NSNumber __block *
    value = nil;
    __typeof(ch) __weak
    weak = ch;
    dispatch_async(self.cQ, ^{
        __typeof(ch) __weak
        strong = weak;
        dispatch_after(self.nano, self.cQ, ^{
            [strong description];
            [rEx fulfill];
        });
        strong = nil;
        ok = [weak receive:&value];
        [ex fulfill];
    });
    ch = nil;
    [self waitForExpectations:@[rEx, ex]
                      timeout:1.0];
    XCTAssertFalse(ok);
    XCTAssertNil(value);
}

- (void)test_performance
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"receive"];
    RWChan<NSNumber *> *
    ch = [[RWChan alloc] init];
    dispatch_async(self.cQ, ^{
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
