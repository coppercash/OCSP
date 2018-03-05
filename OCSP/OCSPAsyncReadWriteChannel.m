//
//  OCSPAsyncReadWriteChannel.m
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel+Internal.h"
#import "OCSPAsyncLock.h"
#import "OCSPAsyncCondition.h"

@interface
OCSPAsyncSelection : NSObject
@property (readonly) BOOL isDetermined;
- (void)determine;
@end
@implementation
OCSPAsyncSelection
{
    BOOL
    _isDetermined;
}

- (void)determine
{
    _isDetermined = YES;
}

- (BOOL)isDetermined { return _isDetermined; }

@end

typedef
id Data;
@implementation
OCSPAsyncReadWriteChannel
{
    OCSPAsyncChannelSlot *
    _slot;
    OCSPAsyncLock *
    _writing;
    OCSPAsyncLock *
    _communicating;
    OCSPAsyncCondition *
    _writtenIn;
    OCSPAsyncCondition *
    _readOut;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _slot = [[OCSPAsyncChannelSlot alloc] init];
    _writing = [[OCSPAsyncLock alloc] init];
    _communicating = [[OCSPAsyncLock alloc] init];
    _writtenIn = [[OCSPAsyncCondition alloc] init];
    _readOut = [[OCSPAsyncCondition alloc] init];
    return self;
}

- (void)dealloc
{
    [self.class close
     :_slot
     :_communicating
     :_writtenIn
     :^(BOOL _) {}
     ];
}

// MARK: - Public

- (void)send:(Data __nullable)data
        with:(void(^)(BOOL ok))callback
{
    [self send:data
            on:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
          with:callback];
}

- (void)send:(Data __nullable)data
          on:(dispatch_queue_t)queue
        with:(void(^)(BOOL ok))callback
{
    [self.class send
     :data
     :_slot
     :_writing
     :_communicating
     :_writtenIn
     :_readOut
     :nil
     :nil
     :nil
     :
     ^(BOOL ok) {
         dispatch_async(queue, ^{
             callback(ok);
         });
     }
     ];
}

- (void)receive:(void(^)(Data __nullable data, BOOL ok))callback
{
   [self receiveOn:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
              with:callback];
}

- (void)receiveOn:(dispatch_queue_t)queue
             with:(void(^)(Data __nullable data, BOOL ok))callback
{
   [self.class receive
    :_slot
    :_communicating
    :_writtenIn
    :_readOut
    :nil
    :nil
    :nil
    :
    ^(Data data, BOOL ok) {
        dispatch_async(queue, ^{
            callback(data, ok);
        });
    }
    ];
}

- (void)close:(void(^)(BOOL ok))callback
{
    [self closeOn:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
             with:callback];
}

- (void)closeOn:(dispatch_queue_t)queue
           with:(void(^)(BOOL ok))callback
{
    [self.class close
     :_slot
     :_communicating
     :_writtenIn
     :
     ^(BOOL ok) {
         dispatch_async(queue, ^{
             callback(ok);
         });
     }
     ];
}

// MARK: - Private

+ (void)receive
:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)writtenIn
:(OCSPAsyncCondition *)readOut
:(OCSPAsyncSelection *)selection
:(OCSPAsyncLock *)selecting
:(OCSPAsyncCondition *)selected
:(void(^)(id, BOOL))callback
{
    __auto_type const
    cond = [OCSPAsyncCombinedCondition combined:
            writtenIn,
            selected,
            nil];
    __auto_type const
    lock = [OCSPAsyncCombinedLock combined:
            communicating,
            selecting,
            nil];
    [cond withLock:lock
             check:
     ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
         if (
             selection.isDetermined
             ) {
             leave();
         }
         else if (
                  slot.state == OCSPAsyncChannelSlotStateClosed
                  ) {
             callback(nil, NO);
             leave();
         }
         else if (
                  slot.state == OCSPAsyncChannelSlotStateFilled
                  ) {
             callback(slot.data, YES);
             [slot empty];
             [selection determine];
             [selected broadcast];
             [readOut broadcast];
             leave();
         }
         else {
             wait();
         }
     }];
}

+ (void)send
:(id)data
:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)writing
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)writtenIn
:(OCSPAsyncCondition *)readOut
:(OCSPAsyncSelection *)selection
:(OCSPAsyncLock *)selecting
:(OCSPAsyncCondition *)selected
:(void(^)(BOOL))callback
{
    [writing lock:^(OCSPAsyncLockUnlock unlockWriting) {
        __auto_type const
        cond = [OCSPAsyncCombinedCondition combined:
                writtenIn,
                readOut,
                selected,
                nil];
        __auto_type const
        lock = [OCSPAsyncCombinedLock combined:
                communicating,
                selecting,
                nil];
        [lock lock:^(OCSPAsyncLockUnlock unlock) {
            NSAssert
            (
             slot.state != OCSPAsyncChannelSlotStateFilled,
             @"Shouldn't write to a filled channel."
             );
            if (
                slot.state == OCSPAsyncChannelSlotStateEmpty
                ) {
                [slot fillWithData:data];
                [writtenIn broadcast];
            }
            [cond withinLock:lock
                      unlock:unlock
                       check:
             ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
                 if (
                     selection.isDetermined
                     ) {
                     leave();
                     unlockWriting();
                 }
                 else if (
                          slot.state == OCSPAsyncChannelSlotStateClosed
                          ) {
                     callback(NO);
                     [selection determine];
                     [selected broadcast];
                     leave();
                     unlockWriting();
                 }
                 else if (
                          slot.state == OCSPAsyncChannelSlotStateEmpty
                          ) {
                     callback(YES);
                     leave();
                     unlockWriting();
                 }
                 else {
                     wait();
                 }
             }];
        }];
    }];
}

+ (void)close:(OCSPAsyncChannelSlot *)slot
             :(OCSPAsyncLock *)communicating
             :(OCSPAsyncCondition *)writtenIn
             :(void(^)(BOOL))callback
{
    [communicating lock:^(OCSPAsyncLockUnlock unlock) {
        if (
            slot.state == OCSPAsyncChannelSlotStateClosed
            ) {
            callback(NO);
            unlock();
            return;
        }
        [slot close];
        callback(YES);
        [writtenIn broadcast];
        unlock();
    }];
}

@end

@interface
OCSPAsyncSelectionBuilder ()
@property (readonly) OCSPAsyncSelection* selection;
@property (readonly) OCSPAsyncCondition* selected;
@property (readonly) OCSPAsyncLock* selecting;
@end
@implementation
OCSPAsyncSelectionBuilder
@end

const
void(^OCSPAsyncSelect)(OCSPAsyncSelectBuildup) = ^(OCSPAsyncSelectBuildup buildup) {
    OCSPAsyncSelectionBuilder *
    builder = [[OCSPAsyncSelectionBuilder alloc] init];
    buildup(builder);
};

@implementation
OCSPAsyncReadWriteChannel (Select)

- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
             with:(void (^)(id _Nullable, BOOL))callback
{
    [self.class receive:_slot
                       :_communicating
                       :_writtenIn
                       :_readOut
                       :case_.selection
                       :case_.selecting
                       :case_.selected
                       :callback];
}

@end
