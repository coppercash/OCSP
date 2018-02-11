//
//  OCSPAsyncChannel.m
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@implementation OCSPAsyncChannel

- (void)receiveWithOn:(dispatch_queue_t)queue
             callback:(void(^)(id, BOOL))callback
{
    if (callback) { callback(nil, NO); }
}

@end

#import "OCSPChannel.h"

@implementation OCSPAsyncBufferedReadWriteChannel {
    dispatch_queue_t
    _readQueue;
    OCSBufferedReadWriteChannel
    *_proto;
}

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
    _proto = [[OCSBufferedReadWriteChannel alloc] initWithCapacity:capacity];
    _readQueue = readQueue;
    return self;
}

- (void)receiveWithOn:(dispatch_queue_t)queue
             callback:(void(^)(id, BOOL))callback;
{
    // weakify proto, so that the channel can be closed properly if released
    //
    __typeof(self) __weak
    __weak_self = self;
    dispatch_async(_readQueue, ^{
        id
        data;
        BOOL
        ok = [__weak_self receive:&data];
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
