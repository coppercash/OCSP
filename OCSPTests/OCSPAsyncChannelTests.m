//
//  OCSPAsyncChannelTests.m
//  OCSPTests
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCSP/OCSP.h>

@interface OCSPAsyncChannelTests : XCTestCase
@property (nonatomic, strong) dispatch_queue_t cbq;
@end

@implementation OCSPAsyncChannelTests

- (void)setUp
{
    [super setUp];
    _cbq = dispatch_get_main_queue();
}

- (void)test_receiveValueAfterSending
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    XCTestExpectation *
    sEx = [self expectationWithDescription:@"send"];
    ARWChan<NSNumber *> *
    ch = [[ARWChan alloc] init];
    BOOL __block
    sent = NO,
    received = NO;
    NSNumber __block *
    value = nil;
    [ch send:@42
      withOn:self.cbq
    callback:
     ^(BOOL ok) {
        sent = ok;
        [sEx fulfill];
    }];
    [ch receiveWithOn:self.cbq
             callback:
     ^(NSNumber *data, BOOL ok) {
         value = data;
         received = ok;
         [rEx fulfill];
     }];
    [self waitForExpectations:@[sEx, rEx]
                      timeout:1.0];
    XCTAssertTrue(received);
    XCTAssertTrue(sent);
    XCTAssertEqualObjects(value, @42);
}

- (void)test_rejectReceivingsAfterClosing
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    ARWChan<NSNumber *> *
    ch = [[ARWChan alloc] init];
    [ch close];
    BOOL __block
    result = YES;
    NSNumber __block *
    value = @42;
    [ch receiveWithOn:self.cbq
             callback:
     ^(NSNumber *data, BOOL ok) {
         result = ok;
         value = data;
         [rEx fulfill];
     }];
    [self waitForExpectations:@[rEx]
                      timeout:1.0];
    XCTAssertFalse(result);
    XCTAssertNil(value);
}

- (void)test_rejectReceivingsWaitingForSendingOnClosing
{
    XCTestExpectation *
    rEx = [self expectationWithDescription:@"recieve"];
    ARWChan<NSNumber *> *
    ch = [[ARWChan alloc] init];
    BOOL __block
    result = YES;
    NSNumber __block *
    value = @42;
    [ch receiveWithOn:self.cbq
             callback:
     ^(NSNumber *data, BOOL ok) {
         result = ok;
         value = data;
         [rEx fulfill];
     }];
    [ch close];
    [self waitForExpectations:@[rEx]
                      timeout:1.0];
    XCTAssertFalse(result);
    XCTAssertNil(value);
}

@end
