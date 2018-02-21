//
//  OCSPAsyncBufferedReadWriteChannel.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@class
OCSPBufferedReadWriteChannel;
@interface OCSPAsyncBufferedReadWriteChannel<Data : id> : OCSPAsyncChannel
{
    dispatch_queue_t
    _readQueue;
    OCSPBufferedReadWriteChannel
    *_proto;
}
- (instancetype __nonnull)initWithCapacity:(NSInteger)capacity;
- (instancetype __nonnull)initWithCapacity:(NSInteger)capacity
                                 readQueue:(dispatch_queue_t __nonnull)readQueue;
- (BOOL)send:(Data __nullable)value;
- (BOOL)close;
@end
