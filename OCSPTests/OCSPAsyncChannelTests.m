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
    NSArray<XCTestExpectation *> *
    exs = @[
            [self expectationWithDescription:@"send"],
            [self expectationWithDescription:@"recieve"],
            ];
    BOOL __block
    isReceived = NO,
    isSent = NO;
    id __block
    received = nil;
    ARWChan<NSNumber *> *
    ch = [[ARWChan alloc] init];
    [ch send:@42
          on:self.cbq
        with:
     ^(BOOL ok) {
         isSent = ok;
         [exs[0] fulfill];
     }];
    [ch receiveOn:self.cbq
             with:
     ^(NSNumber *data, BOOL ok) {
         isReceived = ok;
         received = data;
         [exs[1] fulfill];
     }];
    [self waitForExpectations:exs
                      timeout:1.0];
    XCTAssertTrue(isReceived);
    XCTAssertTrue(isSent);
    XCTAssertEqualObjects(received, @42);
}
/*
- (void)test_rejectReceivingsAfterClosing
{
    NSArray<XCTestExpectation *> *
    exs = @[
            [self expectationWithDescription:@"send"],
            [self expectationWithDescription:@"recieve"],
            [self expectationWithDescription:@"close"],
            ];
    BOOL __block
    isReceived = NO,
    isSent = NO;
    id __block
    received = nil;
    ARWChan<NSNumber *> *
    ch = [[ARWChan alloc] init];
    [ch closeOn:self.cbq
           with:^(BOOL ok) {
               
           }];
    [ch receiveOn:self.cbq
             with:
     ^(NSNumber *data, BOOL ok) {
         isReceived = ok;
         received = data;
         [exs[1] fulfill];
     }];
    [ch send:@42
          on:self.cbq
        with:
     ^(BOOL ok) {
         isSent = ok;
         [exs[0] fulfill];
     }];
    [self waitForExpectations:exs
                      timeout:1.0];
    XCTAssertTrue(isReceived);
    XCTAssertTrue(isSent);
    XCTAssertEqualObjects(received, @42);
}
 */

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
    [ch receiveOn:self.cbq
             with:
     ^(NSNumber *data, BOOL ok) {
         result = ok;
         value = data;
         [rEx fulfill];
     }];
    [ch close:nil];
    [self waitForExpectations:@[rEx]
                      timeout:1.0];
    XCTAssertFalse(result);
    XCTAssertNil(value);
}

- (void)test_rejectReceivingsOnDeallocating
{
    XCTestExpectation *
    ex = [self expectationWithDescription:@"receive"];
    ARWChan<NSNumber *> *
    ch = [[ARWChan alloc] init];
    BOOL __block
    result = YES;
    NSNumber __block *
    value = @42;
    [ch receiveOn:self.cbq
             with:
     ^(id data, BOOL ok) {
         result = ok;
         value = data;
         [ex fulfill];
     }];
    ch = nil;
    [self waitForExpectations:@[ex]
                      timeout:1.0];
    XCTAssertFalse(result);
    XCTAssertNil(value);
}

@end
