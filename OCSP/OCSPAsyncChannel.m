//
//  OCSPAsyncChannel.m
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel+Internal.h"

@implementation OCSPAsyncChannel

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _modifying = dispatch_queue_create("ocsp.a_chan.modifying", DISPATCH_QUEUE_SERIAL);
    _readOut = [[OCSPAsyncCondition alloc] initWithSignalQueue:_modifying];
    _writtenIn = [[OCSPAsyncCondition alloc] initWithSignalQueue:_modifying];
    _state = [[OCSPAsyncChannelState alloc] init];
    return self;
}

- (void)receiveOn:(void(^)(id, BOOL))callback
{
    callback ?: callback(nil, NO);
    
}

- (void)receiveOn:(dispatch_queue_t)queue
             with:(void(^)(id, BOOL))callback
{
    callback ?: callback(nil, NO);
}

@end
