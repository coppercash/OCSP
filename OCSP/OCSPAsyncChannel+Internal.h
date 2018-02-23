//
//  OCSPAsyncChannel+Internal.h
//  OCSP
//
//  Created by William on 24/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@interface
OCSPAsyncChannelState : NSObject
{
@public
    NSUInteger
    _dataCount; // written in data count. <= 1 if no exception
    BOOL
    _isClosed;
}
@end

@interface
OCSPAsyncCondition : NSObject
{
    NSMutableArray<dispatch_block_t> *
    _waitings;
    dispatch_queue_t
    _signalQueue;
}
- (instancetype)initWithSignalQueue:(dispatch_queue_t)singalQueue;
- (void)signal;
- (void)waitUntil:(BOOL(^)(void))becomesTrue
             then:(dispatch_block_t)block;
@end
