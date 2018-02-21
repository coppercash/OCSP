//
//  OCSPAsyncBufferedReadWriteChannel.m
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncBufferedReadWriteChannel.h"
#import "OCSPBufferedReadWriteChannel.h"

@implementation OCSPAsyncBufferedReadWriteChannel 

- (instancetype)init
{
    return [self initWithCapacity:0
                        readQueue:
            dispatch_queue_create
            (
             "ocsp.ayncchannel.read",
             DISPATCH_QUEUE_SERIAL
             )];
}

- (void)dealloc
{
    // `close` to notify the waiting readers on `_readQueue` to continue execution,
    // before the `super.dealloc` released the `_readQueue`
    //
    [self close];
}

- (instancetype)initWithCapacity:(NSInteger)capacity
{
    return [self initWithCapacity:capacity
                        readQueue:
            dispatch_queue_create
            (
             "ocsp.ayncchannel.read",
             DISPATCH_QUEUE_SERIAL
             )];
}

- (instancetype)initWithCapacity:(NSInteger)capacity
                       readQueue:(dispatch_queue_t)readQueue
{
    if (!(
          self = [super init]
          )) { return nil; }
    _proto = [[OCSPBufferedReadWriteChannel alloc] initWithCapacity:capacity];
    _readQueue = readQueue;
    return self;
}

- (void)receiveWithOn:(dispatch_queue_t)queue
             callback:(void(^)(id, BOOL))callback;
{
    // weakify _proto, so that the channel can be closed properly if released
    // weakifying self doesn't work.
    // coz' it will be `objc_loadWeakRetained`, and never be released coz' the execution will be stuck on `receive:`
    //
    __typeof(_proto) __weak
    __weak_proto__ = _proto;
    dispatch_async(_readQueue, ^{
        id
        data;
        BOOL
        ok = [__weak_proto__ receive:&data];
        if (!(
              callback
              )) { return; }
        dispatch_async
        (
         (queue ?: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)),
         ^{
             callback(data, ok);
         });
    });
}

- (BOOL)send:(id)value
{
    return [_proto send:value];
}

- (BOOL)receive:(__autoreleasing id *)outData
{
    return [_proto receive:outData];
}

- (BOOL)close
{
    return [_proto close];
}

@end

