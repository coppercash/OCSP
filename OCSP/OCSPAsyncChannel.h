//
//  OCSPAsyncChannel.h
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

@class
OCSPAsyncCondition,
OCSPAsyncChannelState;
@interface
OCSPAsyncChannel<Data : id> : NSObject
{
@protected
    dispatch_queue_t
    _modifying; // exlusive modifier (reader or writer) at any given time
    OCSPAsyncCondition *
    _readOut;   // signal on data read out (or channel closed)
    OCSPAsyncCondition *
    _writtenIn; // signal on data writren in (or channel closed)
    OCSPAsyncChannelState __kindof *
    _state;
}
- (void)receiveOn:(void(^__nullable)(Data __nullable data, BOOL ok))callback;
- (void)receiveOn:(dispatch_queue_t __nonnull)queue
             with:(void(^__nullable)(Data __nullable data, BOOL ok))callback;
@end


