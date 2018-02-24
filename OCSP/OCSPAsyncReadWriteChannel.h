//
//  OCSPAsyncReadWriteChannel.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@interface OCSPAsyncReadWriteChannel<Data> : OCSPAsyncChannel<Data>
{
    dispatch_queue_t
    _writing,   // exlusive writer at any given time
    _reading;   // exlusive reader at any given time
}
- (void)send:(Data __nullable)data
        with:(void(^__nullable)(BOOL ok))callback;
- (void)send:(Data __nullable)data
          on:(dispatch_queue_t __nonnull)queue
        with:(void(^__nonnull)(BOOL ok))callback;
- (void)close:(void(^__nullable)(BOOL ok))callback;
- (void)closeOn:(dispatch_queue_t __nonnull)queue
           with:(void(^__nonnull)(BOOL ok))callback;
@end
