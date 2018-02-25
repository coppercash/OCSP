//
//  OCSPBufferedReadWriteChannel.m
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPBufferedReadWriteChannel.h"
#import "OCSPChannel+Internal.h"
#import <pthread/pthread.h>

@implementation
OCSPBufferedReadWriteChannel 

- (instancetype)init
{
    return [self initWithCapacity:0];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _capacity = capacity;
    _readerCount = 0;
    _queue = [[NSMutableArray alloc] initWithCapacity:capacity];
    return self;
}

- (void)dealloc
{
    [self close];
}

- (BOOL)send:(id)data
{
    pthread_mutex_lock(&_modifying);
    while (
           _queue.count == _capacity
           ) {
        // block until something is removed.
        //
        _dataCount++;
        pthread_cond_wait(&_readOut, &_modifying);
        _dataCount--;
    }
    
    [_queue addObject:data];
    
    if (
        _readerCount > 0
        ) {
        // signal waiting reader.
        //
        pthread_cond_signal(&_writtenIn);
    }
    
    pthread_mutex_unlock(&_modifying);
    return YES;
}

- (BOOL)receive:(__autoreleasing id *)outData
{
    pthread_mutex_lock(&_modifying);
    while (
           _queue.count == 0
           ) {
        if (
            _isClosed
            ) {
            pthread_mutex_unlock(&_modifying);
            return NO;
        }
        
        // block until something is added.
        //
        _readerCount++;
        pthread_cond_wait(&_writtenIn, &_modifying);
        _readerCount--;
    }
    
    id
    data = _queue.firstObject;
    [_queue removeObjectAtIndex:0];
    if (
        outData
        ) {
        *outData = data;
    }
    
    if (
        _dataCount > 0
        ) {
        // signal waiting writer.
        //
        pthread_cond_signal(&_readOut);
    }
    
    pthread_mutex_unlock(&_modifying);
    return YES;
}

- (BOOL)close
{
    return [super close];
}

@end
