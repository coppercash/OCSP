//
//  OCSPAsyncReadWriteChannel.m
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel+Internal.h"
#import "OCSPAsyncLock+Internal.h"
#import "OCSPAsyncCondition+Internal.h"
#import "OCSPDebug.h"

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
    uint64
    _waitingCases;
}
- (BOOL)isDetermined { return _isDetermined; }

- (void)determine
{
    _isDetermined = YES;
}

- (void)wait:(OCSPAsyncSelectionCaseID)caseID
{
    _waitingCases |= (1 << caseID);
}

- (BOOL)areAllCasesWaiting:(NSUInteger)caseCount
{
    __auto_type const
    mask = (uint64)~(-1 << caseCount);  // 0…01…1
    return ((_waitingCases & mask) ^ mask) == 0;
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
#ifdef OCSPDEBUG
    _writing = [[OCSPAsyncLock alloc] initWithLabel:
                [NSString stringWithFormat:@"(📝 WRT)\\📭(%p)", _slot]
                ];
    _communicating = [[OCSPAsyncLock alloc] initWithLabel:
                      [NSString stringWithFormat:@"(✉️ CMN)\\📭(%p)", _slot]
                      ];
    _writtenIn = [[OCSPAsyncCondition alloc] initWithLabel:
                  [NSString stringWithFormat:@"(📝 WRTIN)\\📭(%p)", _slot]
                  ];
    _readOut = [[OCSPAsyncCondition alloc] initWithLabel:
                [NSString stringWithFormat:@"(📖 RDOUT)\\📭(%p)", _slot]
                ];
#else
    _writing = [[OCSPAsyncLock alloc] init];
    _communicating = [[OCSPAsyncLock alloc] init];
    _writtenIn = [[OCSPAsyncCondition alloc] init];
    _readOut = [[OCSPAsyncCondition alloc] init];
#endif
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
             OCSPLog(@"\t %@ ❌(selected out)\\📩.",
                     [slot debugIDSel:selection
                               caseID:@(caseID)]
                     );
             leave();
         }
         else if (
                  slot.state == OCSPAsyncChannelSlotStateClosed
                  ) {
             OCSPLog(@"\t %@ 📪(closed)\\📩.",
                     [slot debugIDSel:selection
                               caseID:@(caseID)]
                     );
             leave();
             callback(nil, NO);
         }
         else if (
                  slot.state == OCSPAsyncChannelSlotStateFilled
                  ) {
             OCSPLog(@"\t %@ ✅(done)\\📩.",
                     [slot debugIDSel:selection
                               caseID:@(caseID)]
                     );
             Data const
             data = slot.data;
             [slot empty];
             [selection determine];
             [selected broadcast];
             [readOut broadcast];
             leave();
             callback(data, YES);
         }
         else {
             OCSPLog(@"\t %@ ⏸(wait)\\📩.",
                     [slot debugIDSel:selection
                               caseID:@(caseID)]
                     );
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
                OCSPLog(@"\t %@ 📝(writing)\\📤.",
                        [slot debugIDSel:selection
                                  caseID:@(caseID)]
                        );
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
                     OCSPLog(@"\t %@ ❌(selected out)\\📤.",
                             [slot debugIDSel:selection
                                       caseID:@(caseID)]
                             );
                     [slot empty];
                     leave();
                     unlockWriting();
                 }
                 else if (
                          slot.state == OCSPAsyncChannelSlotStateClosed
                          ) {
                     OCSPLog(@"\t %@ 📪(closed)\\📤.",
                             [slot debugIDSel:selection
                                       caseID:@(caseID)]
                             );
                     [slot empty];
                     leave();
                     unlockWriting();
                     callback(NO);
                 }
                 else if (
                          slot.state == OCSPAsyncChannelSlotStateEmpty
                          ) {
                     OCSPLog(@"\t %@ ✅(done)\\📤.",
                             [slot debugIDSel:selection
                                       caseID:@(caseID)]
                             );
                     [selection determine];
                     [selected broadcast];
                     leave();
                     unlockWriting();
                     callback(YES);
                 }
                 else {
                     OCSPLog(@"\t %@ ⏸(wait)\\📤.",
                             [slot debugIDSel:selection
                                       caseID:@(caseID)]
                             );
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
            unlock();
            callback(NO);
            return;
        }
        OCSPLog(@"\t %@ 📪(closed)",
                [slot debugIDSel:nil
                          caseID:nil]
                );
        [slot close];
        [writtenIn broadcast];
        callback(YES);
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
#ifdef OCSPDEBUG
    _selecting = [[OCSPAsyncLock alloc] initWithLabel:
                  [NSString stringWithFormat:@"(⚔️ SLT)\\⚔️(%p)", _selection]
                  ];
    _selected = [[OCSPAsyncCondition alloc] initWithLabel:
                 [NSString stringWithFormat:@"(⚔️ SLTED)\\⚔️(%p)", _selection]
                 ];
    _waitStarted = [[OCSPAsyncCondition alloc] initWithLabel:
                    [NSString stringWithFormat:@"(⏸ WTSTR)\\⚔️(%p)", _selection]
                    ];
#else
    _selected = [[OCSPAsyncCondition alloc] init];
    _waitStarted = [[OCSPAsyncCondition alloc] init];
    _selecting = [[OCSPAsyncLock alloc] init];
#endif
    return self;
}

- (void)default:(OCSPAsyncSelectionDefaultRun)run
{
    _runDefault = run;
}

+ (void)default_
:(OCSPAsyncSelection *)selection
:(NSUInteger)caseCount
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
             OCSPLog(@"\t ⚔️(%p)\t ❌(selected out)\\🍚.", selection);
             leave();
         }
         else if (
                  [selection areAllCasesWaiting:caseCount]
                  ) {
             OCSPLog(@"\t ⚔️(%p)\t ✅(done)\\🍚.", selection);
             [selection determine];
             [selected broadcast];
             leave();
             callback();
         }
         else {
             OCSPLog(@"\t ⚔️(%p)\t ⏸(wait)\\🍚.", selection);
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
        NSCAssert(builder.caseCount < 64, @"More than 63 cases in one select clause is not supported.");
        [OCSPAsyncSelectionBuilder default_
         :builder.selection
         :builder.caseCount
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
     :(case_.caseCount++)
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
