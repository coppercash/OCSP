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

@implementation OCSPAsyncReadWriteChannel {
    dispatch_queue_t
    _writerWatch,
    _readerWatch;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) { return nil; }
    _writerWatch = dispatch_queue_create
    (
     "ocsp.ayncchannel.watch.writer",
     DISPATCH_QUEUE_SERIAL
     );
    _readerWatch = dispatch_queue_create
    (
     "ocsp.ayncchannel.watch.reader",
     DISPATCH_QUEUE_SERIAL
     );
    return self;
}

- (void)receiveWithOn:(dispatch_queue_t)queue
             callback:(void(^)(id, BOOL))callback;
{
    dispatch_async(_readerWatch, ^{
        id
        data;
        BOOL
        ok = [self receive:&data];
        if (!(
              callback
              )) { return; }
        dispatch_async
        (
         (queue ?: self.defaultCallbackQueue),
         ^{
             callback(data, ok);
         });
    });
}

- (void)send:(id)data
      withOn:(dispatch_queue_t)queue
    callback:(void(^)(BOOL ok))callback
{
    dispatch_async(_writerWatch, ^{
        BOOL
        ok = [self send:data];
        if (!(
              callback
              )) { return; }
        dispatch_async
        (
         (queue ?: self.defaultCallbackQueue),
         ^{
             callback(ok);
         });
    });
}

- (dispatch_queue_t)defaultCallbackQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

@end
