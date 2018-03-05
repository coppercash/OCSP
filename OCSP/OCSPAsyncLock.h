//
//  OCSPAsyncLock.h
//  OCSP
//
//  Created by William on 08/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef
void(^OCSPAsyncLockUnlock)(void);
typedef
void(^OCSPAsyncLockRun)(OCSPAsyncLockUnlock unlock);

@protocol
OCSPAsyncLock <NSObject>
- (void)lock:(OCSPAsyncLockRun)run;
@end

@interface
OCSPAsyncLock : NSObject <OCSPAsyncLock>
@end

@interface
OCSPAsyncCombinedLock : NSObject <OCSPAsyncLock>
- (instancetype)initWithLocks:(NSArray<id<OCSPAsyncLock>> *)locks;
+ (instancetype)combined:(id<OCSPAsyncLock>)lock, ... NS_REQUIRES_NIL_TERMINATION;
@end

NS_ASSUME_NONNULL_END
