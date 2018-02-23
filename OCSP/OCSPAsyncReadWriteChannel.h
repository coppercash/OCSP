//
//  OCSPAsyncReadWriteChannel.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@interface OCSPAsyncReadWriteChannel<Data : id> : OCSPAsyncChannel
{
    dispatch_queue_t
    _writing,   // exlusive writer at any given time
    _reading;   // exlusive reader at any given time
}
- (void)send:(Data)data
        with:(void(^)(BOOL ok))callback;
- (void)send:(Data)data
          on:(dispatch_queue_t)queue
        with:(void(^)(BOOL ok))callback;
- (void)close:(void(^)(BOOL ok))callback;
- (void)closeOn:(dispatch_queue_t)queue
           with:(void(^)(BOOL ok))callback;
@end
