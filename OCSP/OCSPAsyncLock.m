//
//  OCSPAsyncLock.m
//  OCSP
//
//  Created by William on 08/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncLock.h"
#import "OCSPDebug.h"

@implementation
OCSPAsyncLock
{
    dispatch_queue_t
    _workQ;
#ifdef OCSPDEBUG_LOCK
    NSString *
    _label;
#endif
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _workQ = dispatch_queue_create("ocsp.aync.lock", DISPATCH_QUEUE_SERIAL);
    return self;
}

#ifdef OCSPDEBUG_LOCK
- (instancetype)initWithLabel:(NSString *)label
{
    if (!(
          self = [self init]
          )) { return nil; }
    _label = label;
    return self;
}
#endif

- (void)lock:(OCSPAsyncLockRun)lock
{
    __auto_type const
    workQ = _workQ;
#ifdef OCSPDEBUG_LOCK
    __auto_type const
    label = _label;
#endif
    dispatch_async(workQ, ^{
        dispatch_suspend(workQ);
#ifdef OCSPDEBUG_LOCK
        OCSPLog(@"\t \t \t 🔐%@\t 🔒(locking).", label);
#endif
        lock(^{
#ifdef OCSPDEBUG_LOCK
            OCSPLog(@"\t \t \t 🔐%@\t 🔓(unlocking).", label);
#endif
            dispatch_resume(workQ);
        });
    });
}

@end

@implementation
OCSPAsyncCombinedLock
{
    NSArray<id<OCSPAsyncLock>>
    *_locks;
}

- (instancetype)initWithLocks:(NSArray<id<OCSPAsyncLock>> *)locks
{
    if (!(
          self = [super init]
          )) { return nil; }
    _locks = locks;
    return self;
}

+ (instancetype)combined:(id<OCSPAsyncLock>)lock, ...
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
                lock = va_arg(args, id<OCSPAsyncLock>)
                )) {
            [buffer addObject:lock];
        }
        va_end(args);
    }
    return [[self alloc] initWithLocks:buffer.copy];
}

- (void)lock:(OCSPAsyncLockRun)run
{
    [self.class locks:_locks
                     :0
                     :run
                     :^{}];
}

+ (void)locks:(NSArray<id<OCSPAsyncLock>> *)locks
             :(NSInteger)index
             :(OCSPAsyncLockRun)run
             :(OCSPAsyncLockUnlock)unlockPrevious
{
    if (!(
          index < locks.count
          )) {
        run(unlockPrevious);
        return;
    }
    [locks[index] lock:^(OCSPAsyncLockUnlock unlock) {
        [self locks:locks
                   :(index + 1)
                   :run
                   :
         ^{
             unlock();
             unlockPrevious();
         }];
    }];
}

@end
