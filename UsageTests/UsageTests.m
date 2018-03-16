//
//  UsageTests.m
//  UsageTests
//
//  Created by William on 16/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCSP/OCSP.h>
#import <OCSP_RXPromise/OCSP_RXPromise.h>
#import <RXPromise/RXPromise.h>

@interface UsageTests : XCTestCase

@end

@implementation UsageTests

- (void)test_basic
{
    __auto_type const
    chan = [[ARWChan<NSNumber *> alloc] init];
    
    [chan send:@42
          with:
     ^(BOOL ok) {
         NSLog(@"The answer has been received!");
     }];
    
    [chan receive:
     ^(NSNumber * _Nullable data, BOOL ok) {
         NSLog(@"Got the ultimate answer %@", data);
    }];
}

- (void)test_select
{
    __auto_type const
    receiving = [[ARWChan<NSNumber *> alloc] init];
    __auto_type const
    sending = [[ARWChan<NSNumber *> alloc] init];
    
    ASelect(^(ASelecting *case_) {
        [receiving receiveIn:case_
                        with:
         ^(NSNumber * _Nullable data, BOOL ok) {
             NSLog(@"Continue with the received value.");
         }];
        [sending send:@42
                   in:case_
                 with:
         ^(BOOL ok) {
             NSLog(@"Continue with the sent value.");
         }];
        [case_ default:^{
            NSLog(@"Continue anyway.");
        }];
    });
}

- (void)test_rx
{
    __auto_type const
    chan = [[ARWChan<NSNumber *> alloc] init];
    [chan orx_send:@42]
    .then(^id(id _) {
        NSLog(@"The answer has been received!");
        return nil;
    }, nil);
    
    [chan orx_receive]
    .then(^id(NSNumber *answer) {
        NSLog(@"Got the ultimate answer %@", answer);
        return nil;
    }, nil);
}

- (void)test_rx_select
{
    __auto_type const
    receiving = [[ARWChan<NSNumber *> alloc] init];
    __auto_type const
    sending = [[ARWChan<NSNumber *> alloc] init];
    
    ORXSelect(^(ORXSelecting *_) { _
        .receive(receiving)
        .send(@42, sending)
        .default_()
        ;
    })
    .then(^id(ORXSelected *_) {
        switch (_.index) {
            case 0:
                NSLog(@"Continue with the received value.");
                return nil;
            case 1:
                NSLog(@"Continue with the sent value.");
                return nil;
            default:
                NSLog(@"Continue anyway.");
                return nil;
        }
    }, nil);
}

@end
