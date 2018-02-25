//
//  OCSPAsyncChannel+Internal.m
//  OCSP
//
//  Created by William on 24/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel+Internal.h"

@implementation
OCSPAsyncChannelState

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _isClosed = NO;
    _dataCount = 0;
    return self;
}

@end

@implementation
OCSPAsyncCondition

- (instancetype)initWithSignalQueue:(dispatch_queue_t)singalQueue;
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _signalQueue = singalQueue;
    _waitings = [[NSMutableArray alloc] init];
    return self;
}

- (void)signal
{
    for (
         dispatch_block_t block in _waitings
         ) {
        dispatch_async(_signalQueue, block);
    }
    [_waitings removeAllObjects];
}

- (void)waitUntil:(BOOL(^)(void))becomesTrue
             then:(dispatch_block_t)block
{
    if (
        becomesTrue()
        ) {
        block();
        return;
    }
    [_waitings addObject:[block copy]];
}

@end
