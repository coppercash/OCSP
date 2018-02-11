//
//  OCSPAsyncChannel.h
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

@interface OCSPAsyncChannel<Data : id> : OCSPChannel
- (void)receiveWithOn:(dispatch_queue_t __nonnull)queue
             callback:(void(^__nullable)(Data __nullable data, BOOL ok))callback;
@end

@interface OCSPAsyncBufferedReadWriteChannel<Data : id> : OCSPAsyncChannel
- (instancetype __nonnull)initWithCapacity:(NSInteger)capacity;
- (instancetype __nonnull)initWithCapacity:(NSInteger)capacity
                                 readQueue:(dispatch_queue_t __nonnull)readQueue;
- (BOOL)send:(Data __nullable)value;
- (BOOL)close;
@end
