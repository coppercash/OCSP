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
id Data;
typedef
void(^OCSPAsyncChannelReceive)(Data data, BOOL ok);
typedef
void(^OCSPAsyncChannelSend)(BOOL ok);
typedef
void(^OCSPAsyncChannelClose)(BOOL ok);
typedef
OCSPAsyncCondition * OCSPAsyncConditionRef;

@implementation
OCSPAsyncReadWriteChannel
{
    OCSPAsyncChannelSlot *
    _slot;
    OCSPAsyncLock *
    _communicating;
    OCSPAsyncConditionRef
    _empty,
    _writing,
    _read,
    _reading,
    _written,
    _closed;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _slot = [[OCSPAsyncChannelSlot alloc] init];
    
#ifdef OCSPDEBUG_LOCK
    _communicating = [[OCSPAsyncLock alloc] initWithLabel:
                      [NSString stringWithFormat:@"(✉️ CMN)\\📭(%p)", _slot]
                      ];
#else
    _communicating = [[OCSPAsyncLock alloc] init];
#endif

#ifdef OCSPDEBUG_COND
    _empty = [[OCSPAsyncCondition alloc] initWithLabel:
              [NSString stringWithFormat:@"(📭 EMPTY)\\📭(%p)", _slot]
              ];
    _writing = [[OCSPAsyncCondition alloc] initWithLabel:
                [NSString stringWithFormat:@"(📝 WRTNG)\\📭(%p)", _slot]
                ];
    _read = [[OCSPAsyncCondition alloc] initWithLabel:
             [NSString stringWithFormat:@"(📖 READN)\\📭(%p)", _slot]
             ];
    _reading = [[OCSPAsyncCondition alloc] initWithLabel:
                [NSString stringWithFormat:@"(📖 RDING)\\📭(%p)", _slot]
                ];
    _written = [[OCSPAsyncCondition alloc] initWithLabel:
                [NSString stringWithFormat:@"(📝 WRTTN)\\📭(%p)", _slot]
                ];
    _closed = [[OCSPAsyncCondition alloc] initWithLabel:
               [NSString stringWithFormat:@"(📪 CLSED)\\📭(%p)", _slot]
               ];
#else
    _empty = [[OCSPAsyncCondition alloc] init];
    _writing = [[OCSPAsyncCondition alloc] init];
    _read = [[OCSPAsyncCondition alloc] init];
    _reading = [[OCSPAsyncCondition alloc] init];
    _written = [[OCSPAsyncCondition alloc] init];
    _closed = [[OCSPAsyncCondition alloc] init];
#endif
    
    return self;
}

- (void)dealloc
{
    [self.class close
     :_slot
     :_communicating
     :_closed
     :^(BOOL _) {}
     ];
}

+ (dispatch_queue_t)defaultCallbackQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

// MARK: - Public

- (void)send:(Data __nullable)data
        with:(OCSPAsyncChannelSend)callback
{
    [self send:data
            on:self.class.defaultCallbackQueue
          with:callback];
}

- (void)send:(Data __nullable)data
          on:(dispatch_queue_t)queue
        with:(OCSPAsyncChannelSend)callback
{
    [self.class send
     :_slot
     :_communicating
     :_empty
     :_writing
     :_read
     :_reading
     :_written
     :_closed
     :data
     :NO
     :^(BOOL ok) {
         dispatch_async(queue, ^{
             callback(ok);
         });
     }
     ];
}

- (void)receive:(OCSPAsyncChannelReceive)callback
{
    [self receiveOn:self.class.defaultCallbackQueue
               with:callback];
}

- (void)receiveOn:(dispatch_queue_t)queue
             with:(OCSPAsyncChannelReceive)callback
{
    [self.class receive
     :_slot
     :_communicating
     :_empty
     :_reading
     :_written
     :_writing
     :_read
     :_closed
     :^(Data data, BOOL ok) {
         dispatch_async(queue, ^{
             callback(data, ok);
         });
     }
     ];
}

- (void)close:(OCSPAsyncChannelClose)callback
{
    [self closeOn:self.class.defaultCallbackQueue
             with:callback];
}

- (void)closeOn:(dispatch_queue_t)queue
           with:(OCSPAsyncChannelClose)callback
{
    [self.class close
     :_slot
     :_communicating
     :_closed
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
:(OCSPAsyncCondition *)empty
:(OCSPAsyncCondition *)reading
:(OCSPAsyncCondition *)written
:(OCSPAsyncCondition *)writing
:(OCSPAsyncCondition *)read
:(OCSPAsyncCondition *)closed

:(OCSPAsyncChannelReceive)callback
{
    __auto_type const
    cond = [OCSPAsyncCombinedCondition combined:
            empty,
            written,
            writing,
            closed,
            nil];
    [cond withLock:communicating
             check:
     ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
         switch (
                 slot.state
                 ) {
             case OCSPAsyncChannelSlotStateClosed
                 : {
                     leave();
                     callback(nil, NO);
                 } break;
             case OCSPAsyncChannelSlotStateEmpty
                 : {
                     [slot read:NULL];
                     [reading broadcast];
                     wait();
                 } break;
             case OCSPAsyncChannelSlotStateWritten
                 : {
                     Data
                     data = nil;
                     [slot read:&data];
                     [empty broadcast];
                     leave();
                     callback(data, YES);
                 } break;
             case OCSPAsyncChannelSlotStateWriting
                 : {
                     Data
                     data = nil;
                     [slot read:&data];
                     [read broadcast];
                     leave();
                     callback(data, YES);
                 } break;
             default:
                 wait();
                 break;
         }
     }];
}

+ (void)send

:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)empty
:(OCSPAsyncCondition *)writing
:(OCSPAsyncCondition *)read
:(OCSPAsyncCondition *)reading
:(OCSPAsyncCondition *)written
:(OCSPAsyncCondition *)closed

:(Data)data
:(BOOL)isDataWritten
:(OCSPAsyncChannelSend)callback
{
    __auto_type const
    cond = [OCSPAsyncCombinedCondition combined:
            empty,
            read,
            reading,
            closed,
            nil];
    [cond withLock:communicating
             check:
     ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
         switch (
                 slot.state
                 ) {
             case OCSPAsyncChannelSlotStateClosed
                 : {
                     leave();
                     callback(NO);
                 } break;
             case OCSPAsyncChannelSlotStateEmpty
                 : {
                     [slot write:data];
                     [writing broadcast];
                     [self send
                      :slot
                      :communicating
                      :empty
                      :writing
                      :read
                      :reading
                      :written
                      :closed
                      :data
                      :YES
                      :callback
                      ];
                     leave();
                 } break;
             case OCSPAsyncChannelSlotStateRead
                 : {
                     if (
                         isDataWritten
                         ) {
                         [slot write:nil];
                         [empty broadcast];
                         leave();
                         callback(YES);
                     }
                     else {
                         wait();
                     }
                 } break;
             case OCSPAsyncChannelSlotStateReading
                 : {
                     NSAssert(isDataWritten == NO, @"Multiple sendings entered the critical section.");
                     [slot write:data];
                     [written broadcast];
                     leave();
                     callback(YES);
                 } break;
             default:
                 wait();
                 break;
         }
     }];
}

+ (void)close
:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)closed
:(OCSPAsyncChannelClose)callback
{
    [communicating lock:^(OCSPAsyncLockUnlock unlock) {
        if (
            slot.state == OCSPAsyncChannelSlotStateClosed
            ) {
            unlock();
            callback(NO);
            return;
        }
        [slot close];
        [closed broadcast];
        callback(YES);
        unlock();
    }];
}

@end

#import "OCSPAsyncSelect+Internal.h"

@implementation
OCSPAsyncReadWriteChannel (Select)

+ (void)receive
:(OCSPAsyncSelectionBuilder *)builder
:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)writing
:(OCSPAsyncCondition *)read
:(OCSPAsyncCondition *)closed
:(OCSPAsyncChannelReceive)callback
{
    [builder.locks addObject:communicating];
    [builder.conditions addObject:writing];
    [builder.conditions addObject:closed];
    [builder.tries addObject:
     [
      ^(
        OCSPAsyncSelectDetermine determine,
        OCSPAsyncSelectHesitate hesitate
        ){
          switch (slot.state) {
              case
                  OCSPAsyncChannelSlotStateClosed
                  : {
                      determine();
                      callback(nil, NO);
                  } break;
              case
                  OCSPAsyncChannelSlotStateWriting
                  : {
                      Data
                      data = nil;
                      [slot read:&data];
                      [read broadcast];
                      determine();
                      callback(data, YES);
                  } break;
              default:
                  hesitate();
                  break;
          }
      }
      copy]
     ];
}

- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
               on:(dispatch_queue_t)queue
             with:(void(^)(Data, BOOL))callback
{
    
    [self.class receive
     :case_
     :_slot
     :_communicating
     :_writing
     :_read
     :_closed
     :^(Data data, BOOL ok) {
         dispatch_async(queue, ^{
             callback(data, ok);
         });
     }
     ];
}

- (void)receiveIn:(OCSPAsyncSelectionBuilder *)case_
             with:(void (^)(Data, BOOL))callback
{
    [self receiveIn:case_
                 on:self.class.defaultCallbackQueue
               with:callback];
}

+ (void)send
:(OCSPAsyncSelectionBuilder *)builder
:(OCSPAsyncChannelSlot *)slot
:(OCSPAsyncLock *)communicating
:(OCSPAsyncCondition *)reading
:(OCSPAsyncCondition *)written
:(OCSPAsyncCondition *)closed
:(Data)data
:(OCSPAsyncChannelSend)callback
{
    [builder.locks addObject:communicating];
    [builder.conditions addObject:reading];
    [builder.conditions addObject:closed];
    [builder.tries addObject:
     [
      ^(
        OCSPAsyncSelectDetermine determine,
        OCSPAsyncSelectHesitate hesitate
        ){
          switch (slot.state) {
              case
                  OCSPAsyncChannelSlotStateClosed
                  : {
                      determine();
                      callback(NO);
                  } break;
              case
                  OCSPAsyncChannelSlotStateReading
                  : {
                      [slot write:data];
                      [written broadcast];
                      determine();
                      callback(YES);
                  } break;
              default:
                  hesitate();
                  break;
          }
      }
      copy]
     ];
}

- (void)send:(id)data
          in:(OCSPAsyncSelectionBuilder *)case_
          on:(dispatch_queue_t)queue
        with:(void(^)(BOOL ok))callback;
{
    [self.class send
     :case_
     :_slot
     :_communicating
     :_reading
     :_written
     :_closed
     :data
     :^(BOOL ok) {
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
