//
//  OCSPAsyncReadWriteChannel.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface
OCSPAsyncReadWriteChannel<__covariant Data> : OCSPAsyncChannel<Data>
{
}
- (void)send:(Data __nullable)data
        with:(void(^)(BOOL ok))callback;
- (void)send:(Data __nullable)data
          on:(dispatch_queue_t)queue
        with:(void(^)(BOOL ok))callback;
- (void)close:(void(^)(BOOL ok))callback;
- (void)closeOn:(dispatch_queue_t)queue
           with:(void(^)(BOOL ok))callback;
@end

@interface OCSPAsyncSelectionBuilder : NSObject
@end

typedef
void(^OCSPAsyncSelectBuildup)(OCSPAsyncSelectionBuilder *case_);
FOUNDATION_EXPORT const
void(^OCSPAsyncSelect)(OCSPAsyncSelectBuildup);

@interface
OCSPAsyncReadWriteChannel<Data> (Select)
- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
             with:(void(^__nullable)(Data __nullable data, BOOL ok))callback;
@end

NS_ASSUME_NONNULL_END
