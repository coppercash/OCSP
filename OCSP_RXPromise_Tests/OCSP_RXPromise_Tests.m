//
//  OCSP_RXPromise_Tests.m
//  OCSP_RXPromise_Tests
//
//  Created by William on 16/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <RXPromise/RXPromise.h>
#import <OCSP_RXPromise/OCSP_RXPromise.h>

@interface OCSP_RXPromise_Tests : XCTestCase

@end

@implementation OCSP_RXPromise_Tests

- (void)test_receive {
    __auto_type const
    chan = [[ARWChan alloc] init];
    __auto_type __block
    value = @0;
    __auto_type const
    r = [self expectationWithDescription:@"r"];
    chan.orx_receive()
    .then(^id(NSNumber *data) {
        value = data;
        [r fulfill];
        return nil;
    }, nil)
    ;
    __auto_type const
    s = [self expectationWithDescription:@"s"];
    [chan send:@42 with:^(BOOL _) {
        [s fulfill];
    }];
    [self waitForExpectations:@[r, s]
                      timeout:1.0];
    XCTAssertEqualObjects(value, @42);
}

- (void)test_send {
    __auto_type const
    chan = [[ARWChan alloc] init];
    __auto_type const
    s = [self expectationWithDescription:@"s"];
    chan.orx_send(@42)
    .then(^id(id _) {
        [s fulfill];
        return nil;
    }, nil)
    ;
    __auto_type __block
    value = @0;
    __auto_type const
    r = [self expectationWithDescription:@"r"];
    [chan receive:^(id data, BOOL ok) {
        value = data;
        [r fulfill];
    }];
    [self waitForExpectations:@[r, s]
                      timeout:1.0];
    XCTAssertEqualObjects(value, @42);
}

- (void)test_select_send {
    __auto_type const
    chan = [[ARWChan alloc] init];
    __auto_type const
    nthr = [[ARWChan alloc] init];
    __auto_type const
    s = [self expectationWithDescription:@"s"];
    ORXSelect(^(ORXSelecting *_) { _
        .receive(chan)
        .send(@42, nthr)
        ;
    })
    .then(^id(ORXSelected *selected) {
        switch (selected.index) {
            case 1:
                [s fulfill];
                return nil;
            default:
                return nil;
        }
    }, nil)
    ;
    __auto_type __block
    value = @0;
    __auto_type const
    r = [self expectationWithDescription:@"r"];
    [nthr receive:^(id data, BOOL ok) {
        value = data;
        [r fulfill];
    }];
    [self waitForExpectations:@[r, s]
                      timeout:1.0];
    XCTAssertEqualObjects(value, @42);
}

- (void)test_select_receive {
    __auto_type const
    chan = [[ARWChan alloc] init];
    __auto_type const
    nthr = [[ARWChan alloc] init];
    __auto_type __block
    value = @0;
    __auto_type const
    r = [self expectationWithDescription:@"r"];
    ORXSelect(^(ORXSelecting *_) { _
        .receive(chan)
        .send(0, nthr)
        ;
    })
    .then(^id(ORXSelected *selected) {
        switch (selected.index) {
            case 0:
                value = selected.data;
                [r fulfill];
                return nil;
            default:
                return nil;
        }
    }, nil)
    ;
    __auto_type const
    s = [self expectationWithDescription:@"s"];
    [chan send:@42 with:^(BOOL _) {
        [s fulfill];
    }];
    [self waitForExpectations:@[r, s]
                      timeout:1.0];
    XCTAssertEqualObjects(value, @42);
}

- (void)test_select_default {
    __auto_type const
    chan = [[ARWChan alloc] init];
    __auto_type const
    nthr = [[ARWChan alloc] init];
    __auto_type const
    r = [self expectationWithDescription:@"r"];
    ORXSelect(^(ORXSelecting *_) { _
        .receive(chan)
        .send(0, nthr)
        .default_()
        ;
    })
    .then(^id(ORXSelected *selected) {
        switch (selected.index) {
            default:
                [r fulfill];
                return nil;
        }
    }, nil)
    ;
    [self waitForExpectations:@[r]
                      timeout:1.0];
}

@end
