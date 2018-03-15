//
//  OCSPAsyncChannel.h
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface
OCSPAsyncChannel<__covariant Data : id> : NSObject
- (void)receive:(void(^)(Data __nullable data, BOOL ok))callback;
- (void)receiveOn:(dispatch_queue_t)queue
             with:(void(^)(Data __nullable data, BOOL ok))callback;
@end

@class
OCSPAsyncSelectionBuilder;
@interface
OCSPAsyncChannel<__covariant Data : id> (Select)
- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
             with:(void(^)(Data __nullable data, BOOL ok))callback;
- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
               on:(dispatch_queue_t)queue
             with:(void(^)(Data __nullable data, BOOL ok))callback;
@end

NS_ASSUME_NONNULL_END
