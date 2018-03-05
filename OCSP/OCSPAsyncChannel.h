//
//  OCSPAsyncChannel.h
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

NS_ASSUME_NONNULL_BEGIN

@interface
OCSPAsyncChannel<__covariant Data : id> : NSObject
- (void)receive:(void(^)(Data __nullable data, BOOL ok))callback;
- (void)receiveOn:(dispatch_queue_t)queue
             with:(void(^)(Data __nullable data, BOOL ok))callback;
@end

NS_ASSUME_NONNULL_END
