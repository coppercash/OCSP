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

typedef
NSInteger OCSPAsyncSelectionCaseID;
__auto_type const
OCSPAsyncSelectionCaseIDNil = NSNotFound;

@class
OCSPAsyncSelection;
@interface
OCSPAsyncSelectionCase : NSObject
@property (readonly) OCSPAsyncSelection* selection;
@end
@implementation
OCSPAsyncSelectionCase
{
    OCSPAsyncSelection __unsafe_unretained *
    _selection;
}
- (OCSPAsyncSelection *)selection { return _selection; }
@end

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
- (BOOL)isDetermined { return _isDetermined; }

- (void)determine
{
    _isDetermined = YES;
}

- (void)wait:(OCSPAsyncSelectionCaseID)caseID
{
    
}

- (BOOL)isWaiting
{
    
}

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

+ (dispatch_queue_t)defaultCallbackQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

// MARK: - Public

- (void)send:(Data __nullable)data
        with:(void(^)(BOOL ok))callback
{
    [self send:data
            on:self.class.defaultCallbackQueue
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
     :OCSPAsyncSelectionCaseIDNil
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
   [self receiveOn:self.class.defaultCallbackQueue
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
    :OCSPAsyncSelectionCaseIDNil
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
    [self closeOn:self.class.defaultCallbackQueue
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
:(OCSPAsyncSelectionCaseID)caseID
:(OCSPAsyncLock *)selecting
:(OCSPAsyncCondition *)selected
:(OCSPAsyncCondition *)waitStarted
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
             NSLog(@"%p reiceiving losed", slot);
             leave();
         }
         else if (
                  slot.state == OCSPAsyncChannelSlotStateClosed
                  ) {
             NSLog(@"%p reiceiving closed", slot);
             callback(nil, NO);
             leave();
         }
         else if (
                  slot.state == OCSPAsyncChannelSlotStateFilled
                  ) {
             NSLog(@"%p reiceiving done", slot);
             callback(slot.data, YES);
             [slot empty];
             [selection determine];
             [selected broadcast];
             [readOut broadcast];
             leave();
         }
         else {
             NSLog(@"%p reiceiving wait", slot);
             [selection wait:caseID];
             [waitStarted broadcast];
             wait();
         }
     }];
}

+ (void)send:(id)data
:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)writing
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)writtenIn
:(OCSPAsyncCondition *)readOut
:(OCSPAsyncSelection *)selection
:(OCSPAsyncSelectionCaseID)caseID
:(OCSPAsyncLock *)selecting
:(OCSPAsyncCondition *)selected
:(OCSPAsyncCondition *)waitStarted
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
                NSLog(@"%p sending writing", slot);
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
                     NSLog(@"%p sending losed", slot);
                     [slot empty];
                     leave();
                     unlockWriting();
                 }
                 else if (
                          slot.state == OCSPAsyncChannelSlotStateClosed
                          ) {
                     NSLog(@"%p sending closed", slot);
                     [slot empty];
                     callback(NO);
                     leave();
                     unlockWriting();
                 }
                 else if (
                          slot.state == OCSPAsyncChannelSlotStateEmpty
                          ) {
                     NSLog(@"%p sending done", slot);
                     callback(YES);
                     [selection determine];
                     [selected broadcast];
                     leave();
                     unlockWriting();
                 }
                 else {
                     NSLog(@"%p sending wait", slot);
                     [selection wait:caseID];
                     [waitStarted broadcast];
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
        NSLog(@"%p sending closing", slot);
        [slot close];
        callback(YES);
        [writtenIn broadcast];
        unlock();
    }];
}

@end

@interface
OCSPAsyncSelectionBuilder ()
@property (readonly, nonatomic) OCSPAsyncSelection* selection;
@property (readonly, nonatomic) OCSPAsyncCondition* selected;
@property (readonly, nonatomic) OCSPAsyncCondition* waitStarted;
@property (readonly, nonatomic) OCSPAsyncLock* selecting;
@property (readonly, nonatomic) OCSPAsyncSelectionDefaultRun runDefault;
@property (nonatomic) NSInteger caseCount;
@end
@implementation
OCSPAsyncSelectionBuilder

- (instancetype)init
{
    if (!(
          self = [super init]
          )) { return nil; }
    _selection = [[OCSPAsyncSelection alloc] init];
    _selected = [[OCSPAsyncCondition alloc] init];
    _waitStarted = [[OCSPAsyncCondition alloc] init];
    _selecting = [[OCSPAsyncLock alloc] init];
    return self;
}

- (void)default:(OCSPAsyncSelectionDefaultRun)run
{
    _runDefault = run;
}

+ (void)default_
:(OCSPAsyncSelection *)selection
:(OCSPAsyncLock *)selecting
:(OCSPAsyncCondition *)selected
:(OCSPAsyncCondition *)waitStarted
:(OCSPAsyncSelectionDefaultRun)callback
{
    __auto_type const
    cond = [OCSPAsyncCombinedCondition combined:
            selected,
            waitStarted,
            nil];
    [cond withLock:selecting
             check:
     ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
         if (
             selection.isDetermined
             ) {
             callback();
             leave();
         }
         else if (
                  selection.isWaiting
                  ) {
             [selection determine];
             [selected broadcast];
         }
         else {
             wait();
         }
     }];
}

@end

const
void(^OCSPAsyncSelect)(OCSPAsyncSelectionBuildup) = ^(OCSPAsyncSelectionBuildup buildup) {
    __auto_type const
    builder = [[OCSPAsyncSelectionBuilder alloc] init];
    buildup(builder);
    if (builder.runDefault) {
        [OCSPAsyncSelectionBuilder default_
         :builder.selection
         :builder.selecting
         :builder.selected
         :builder.waitStarted
         :builder.runDefault
         ];
    }
};

@implementation
OCSPAsyncReadWriteChannel (Select)

- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
               on:(dispatch_queue_t)queue
             with:(void(^)(Data data, BOOL ok))callback
{
    [self.class receive
     :_slot
     :_communicating
     :_writtenIn
     :_readOut
     :case_.selection
     :(case_.caseCount++)
     :case_.selecting
     :case_.selected
     :case_.waitStarted
     :
     ^(Data data, BOOL ok) {
         dispatch_async(queue, ^{
             callback(data, ok);
         });
     }
     ];
}

- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
             with:(void (^)(id _Nullable, BOOL))callback
{
    [self receiveIn:case_
                 on:self.class.defaultCallbackQueue
               with:callback];
}

- (void)send:(id)data
          in:(OCSPAsyncSelectionBuilder *)case_
          on:(dispatch_queue_t)queue
        with:(void(^)(BOOL ok))callback;
{
    [self.class send
     :data
     :_slot
     :_writing
     :_communicating
     :_writtenIn
     :_readOut
     :case_.selection
     :OCSPAsyncSelectionCaseIDNil
     :case_.selecting
     :case_.selected
     :case_.waitStarted
     :
     ^(BOOL ok) {
         dispatch_async(queue, ^{
             callback(ok);
         });
     }
     ];
}

- (void)send:(id)data
          in:(OCSPAsyncSelectionBuilder *)case_
        with:(void(^)(BOOL ok))callback;
{
    [self send:data
            in:case_
            on:self.class.defaultCallbackQueue
          with:callback];
}

@end
