//
//  OCSPAsyncReadWriteChannel.m
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel+Internal.h"

typedef
void(^OCSPAsyncContinue)(void);
typedef
void(^OCSPConitnuationPassingBlock)(OCSPAsyncContinue);

@implementation
OCSPAsyncReadWriteChannel

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _writing = dispatch_queue_create("ocsp.arw_chan.writing", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(_writing, _modifying);
    _reading = dispatch_queue_create("ocsp.arw_chan.writing", DISPATCH_QUEUE_SERIAL);
    dispatch_set_target_queue(_reading, _modifying);
    _state = [[OCSPAsyncReadWriteChannelState alloc] init];
    return self;
}

- (void)dealloc
{
    [self close:nil];
}

- (dispatch_queue_t)defaultCallbackQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

- (void)lock:(dispatch_queue_t)queue
        then:(void(^)(OCSPAsyncContinue unlock))block
{
    dispatch_async(queue, ^{
        dispatch_suspend(queue);
        block(^{
            dispatch_resume(queue);
        });
    });
}

- (void)send:(id)data
        with:(void (^)(BOOL))callback
{
   [self send:data
           on:self.defaultCallbackQueue
         with:callback];
}

- (void)send:(id)data
          on:(dispatch_queue_t)writer
        with:(void(^)(BOOL))callback
{
    OCSPAsyncReadWriteChannelState *
    state = _state;
    OCSPAsyncCondition *
    writtenIn = _writtenIn;
    OCSPAsyncCondition *
    readOut = _readOut;
    [self lock:_writing
          then:
     ^(OCSPAsyncContinue unlock) {
         state->_data = data;
         state->_dataCount++;
         [writtenIn signal];
         [readOut waitUntil:
          ^BOOL{
              return state->_isClosed || (state->_dataCount == 0);
          }
                       then:
          ^{
              if (
                  state->_isClosed
                  ) {
                  !callback ?: callback(NO);
                  unlock();
                  return;
              }
              !callback ?: callback(YES);
              unlock();
          }];
     }];
}

- (void)receiveOn:(void (^)(id, BOOL))callback
{
   [self receiveOn:self.defaultCallbackQueue
              with:callback];
}

- (void)receiveOn:(dispatch_queue_t)queue
             with:(void(^)(id, BOOL))callback
{
    OCSPAsyncReadWriteChannelState *
    state = _state;
    OCSPAsyncCondition *
    writtenIn = _writtenIn;
    OCSPAsyncCondition *
    readOut = _readOut;
    [self lock:_reading
          then:
     ^(OCSPAsyncContinue unlock) {
         [writtenIn waitUntil:
          ^BOOL{
              return state->_isClosed || (state->_dataCount > 0);
          }
                         then:
          ^{
              if (
                  state->_isClosed
                  ) {
                  !callback ?: callback(nil, NO);
                  unlock();
                  return;
              }
              !callback ?: callback(state->_data, YES);
              state->_dataCount--;
              [readOut signal];
              unlock();
          }];
     }];
}

- (void)closeOn:(dispatch_queue_t)queue
           with:(void(^)(BOOL ok))callback
{
    OCSPAsyncReadWriteChannelState *
    state = _state;
    OCSPAsyncCondition *
    writtenIn = _writtenIn;
    OCSPAsyncCondition *
    readOut = _readOut;
    [self lock:_modifying
          then:
     ^(OCSPAsyncContinue unlock) {
         if (
             state->_isClosed
             ) {
             !callback ?: callback(NO);
             unlock();
             return;
         }
         state->_isClosed = YES;
         [writtenIn signal];
         [readOut signal];
         unlock();
     }];
}

- (void)close:(void(^)(BOOL ok))callback
{
   [self closeOn:self.defaultCallbackQueue
            with:callback];
}

@end
