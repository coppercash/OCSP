//
//  OCSPAsyncCondition.h
//  OCSP
//
//  Created by William on 08/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OCSPAsyncLock.h"

NS_ASSUME_NONNULL_BEGIN

typedef
void(^OCSPAsyncConditionLeave)(void);
typedef
void(^OCSPAsyncConditionWait)(void);

typedef
void(^OCSPAsyncConditionCheck)(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait);

@protocol
OCSPAsyncLock;
@protocol
OCSPAsyncCondition <NSObject>
- (void)withLock:(id<OCSPAsyncLock>)lock
           check:(OCSPAsyncConditionCheck)check;
- (void)withinLock:(id<OCSPAsyncLock>)lock
            unlock:(OCSPAsyncLockUnlock)unlock
             check:(OCSPAsyncConditionCheck)check;
@end

@interface
OCSPAsyncCondition : NSObject <OCSPAsyncCondition>
- (void)broadcast;
@end

@interface
OCSPAsyncCombinedCondition : NSObject <OCSPAsyncCondition>
- (instancetype)initWithConditions:(NSArray<id<OCSPAsyncCondition>> *)conditions;
+ (instancetype)combined:(id<OCSPAsyncCondition>)lock, ... NS_REQUIRES_NIL_TERMINATION;
@end

NS_ASSUME_NONNULL_END

