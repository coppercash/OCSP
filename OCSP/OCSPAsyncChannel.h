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

@interface OCSPAsyncReadWriteChannel<Data : id> : OCSPReadWriteChannel
- (void)receiveWithOn:(dispatch_queue_t __nonnull)queue
             callback:(void(^__nullable)(Data __nullable data, BOOL ok))callback;
- (void)send:(Data __nullable)data
      withOn:(dispatch_queue_t __nonnull)queue
    callback:(void(^__nullable)(BOOL ok))callback;
@end
