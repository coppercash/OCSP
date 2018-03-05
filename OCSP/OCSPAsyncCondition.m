//
//  OCSPAsyncCondition.m
//  OCSP
//
//  Created by William on 08/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncCondition.h"

@implementation
OCSPAsyncCondition
{
    NSMutableArray<dispatch_block_t> *
    _waitings;
    dispatch_queue_t
    _seqQ;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) { return self; }
    _waitings = [[NSMutableArray alloc] init];
    _seqQ = dispatch_queue_create("ocsp.async.condition", DISPATCH_QUEUE_SERIAL);
    return self;
}

- (void)broadcast
{
    [self.class wake:_waitings
                    :_seqQ
                    :^{}];
}

- (void)withLock:(id<OCSPAsyncLock>)lock
           check:(OCSPAsyncConditionCheck)check
{
    __auto_type const
    cls = self.class;
    __auto_type const
    waitings = _waitings;
    __auto_type const
    seqQ = _seqQ;
    [lock lock:^(OCSPAsyncLockUnlock unlock) {
        check
        (
         unlock,
         ^{
             [cls wait:waitings
                      :lock
                      :check
                      :seqQ
                      :unlock];
         }
         );
    }];
}

- (void)withinLock:(id<OCSPAsyncLock>)lock
            unlock:(OCSPAsyncLockUnlock)unlock
             check:(OCSPAsyncConditionCheck)check
{
    __auto_type const
    cls = self.class;
    __auto_type const
    waitings = _waitings;
    __auto_type const
    seqQ = _seqQ;
    check
    (
     unlock,
     ^{
         [cls wait:waitings
                  :lock
                  :check
                  :seqQ
                  :unlock];
     }
     );
}

- (void)_withLock:(id<OCSPAsyncLock>)lock
         callback:(dispatch_block_t)callback
  waitForChecking:(OCSPAsyncConditionCheck)check
{
    [self.class wait:_waitings
                    :lock
                    :check
                    :_seqQ
                    :callback];
}

- (void)_withinLock:(id<OCSPAsyncLock>)lock
    waitForChecking:(OCSPAsyncConditionCheck)check
{
    
}

+ (void)wait
:(NSMutableArray<dispatch_block_t> __weak *)waitings
:(id<OCSPAsyncLock>)lock
:(OCSPAsyncConditionCheck)check
:(dispatch_queue_t)seqQ
:(dispatch_block_t)callback
{
    dispatch_async(seqQ, ^{
        [waitings addObject:[^{
            [lock lock:^(OCSPAsyncLockUnlock unlock) {
                check
                (
                 ^{ unlock(); },
                 ^{
                     [self wait:waitings
                               :lock
                               :check
                               :seqQ
                               :unlock];
                 }
                 );
            }];
        } copy]];
        callback();
    });
}

+ (void)wake
:(NSMutableArray<dispatch_block_t> *)waitings
:(dispatch_queue_t)seqQ
:(dispatch_block_t)callback
{
    dispatch_async(seqQ, ^{
        for (dispatch_block_t
             w in waitings
             ) {
            w();
        }
        [waitings removeAllObjects];
        callback();
    });
}

@end

@interface
OCSPAsyncConditionWaitGroup : NSObject
@property (readonly) BOOL isLeft;
- (void)leave;
@end
@interface
OCSPAsyncConditionWaitGroup ()
@property (readwrite, nonatomic) BOOL isLeft;
@end
@implementation
OCSPAsyncConditionWaitGroup

- (void)leave
{
    _isLeft = YES;
}

@end

@implementation
OCSPAsyncCombinedCondition
{
    NSArray<id<OCSPAsyncCondition>>
    *_conditions;
}

- (instancetype)initWithConditions:(NSArray<id<OCSPAsyncCondition>> *)conditions
{
    if (!(
          self = [super init]
          )) { return nil; }
    _conditions = conditions;
    return self;
}

+ (instancetype)combined:(id<OCSPAsyncCondition>)lock, ...
{
    __auto_type const
    buffer = [[NSMutableArray alloc] init];
    if (
        lock
        ) {
        [buffer addObject:lock];
        va_list
        args;
        va_start(args, lock);
        while ((
                lock = va_arg(args, id<OCSPAsyncCondition>)
                )) {
            [buffer addObject:lock];
        }
        va_end(args);
    }
    return [[self alloc] initWithConditions:buffer.copy];
}

- (void)withLock:(id<OCSPAsyncLock>)lock
           check:(OCSPAsyncConditionCheck)check
{
    __auto_type const
    cls = self.class;
    __auto_type const
    conditions = _conditions;
    [lock lock:^(OCSPAsyncLockUnlock unlock) {
        check
        (
         unlock,
         ^{
             __auto_type const
             group = [[OCSPAsyncConditionWaitGroup alloc] init];
             [cls wait
              :group
              :conditions
              :0
              :lock
              :check
              :unlock
              ];
         }
         );
    }];
}

- (void)withinLock:(id<OCSPAsyncLock>)lock
            unlock:(OCSPAsyncLockUnlock)unlock
             check:(OCSPAsyncConditionCheck)check
{
    __auto_type const
    cls = self.class;
    __auto_type const
    conditions = _conditions;
    check
    (
     unlock,
     ^{
         __auto_type const
         group = [[OCSPAsyncConditionWaitGroup alloc] init];
         [cls wait
          :group
          :conditions
          :0
          :lock
          :check
          :unlock
          ];
     }
     );
}

+ (void)wait
:(OCSPAsyncConditionWaitGroup *)group
:(NSArray<OCSPAsyncCondition *> *)conditions
:(NSInteger)index
:(id<OCSPAsyncLock>)lock
:(OCSPAsyncConditionCheck)check
:(dispatch_block_t)callback
{
    if (!(
          index < conditions.count
          )) {
        callback();
        return;
    }
    [conditions[index] _withLock:lock
                        callback:
     ^{
         [self wait
          :group
          :conditions
          :(index + 1)
          :lock
          :check
          :callback
          ];
     }
                 waitForChecking:
     ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
         if (
             group.isLeft
             ) {
             leave();
             return;
         }
         check
         (
          ^{
              [group leave];
              leave();
          },
          wait
          );
     }
     ];
}

@end
