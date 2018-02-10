//
//  OCSPChannel.m
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"
#import <pthread/pthread.h>

@implementation OCSPChannel
- (BOOL)receive:(id __autoreleasing *)outValue { return NO; }
- (void)receiveIn:(void(^)(id, BOOL))callback { if (callback) { callback(nil, NO); } }
@end

@implementation OCSPReadWriteChannel {
    pthread_mutex_t
    _modifying,
    _writing,
    _reading;
    pthread_cond_t
    _waitingWriters,
    _waitingReaders;
    BOOL
    _isClosed;
    NSUInteger
    _waitingWriterCount,
    _waitingReaderCount;
    id
    _data;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    if (
            pthread_mutex_init(&_writing, NULL) != 0
       ) {
        return nil;
    }

    if (
            pthread_mutex_init(&_reading, NULL) != 0
       ) {
        pthread_mutex_destroy(&_writing);
        return nil;
    }

    if (
            pthread_mutex_init(&_modifying, NULL) != 0
       ) {
        pthread_mutex_destroy(&_writing);
        pthread_mutex_destroy(&_reading);
        return nil;
    }

    if (
            pthread_cond_init(&_waitingReaders, NULL) != 0
       ) {
        pthread_mutex_destroy(&_modifying);
        pthread_mutex_destroy(&_writing);
        pthread_mutex_destroy(&_reading);
        return nil;
    }

    if (
            pthread_cond_init(&_waitingWriters, NULL) != 0
       ) {
        pthread_mutex_destroy(&_modifying);
        pthread_mutex_destroy(&_writing);
        pthread_mutex_destroy(&_reading);
        pthread_cond_destroy(&_waitingReaders);
        return nil;
    }

    _isClosed = 0;
    _waitingReaderCount = 0;
    _waitingWriterCount = 0;
    _data = nil;
    return self;
}

- (BOOL)send:(id)data
{
    pthread_mutex_lock(&_writing);
    pthread_mutex_lock(&_modifying);

    if (
            _isClosed
       ) {
        pthread_mutex_unlock(&_modifying);
        pthread_mutex_unlock(&_writing);
        return NO;
    }

    _data = data;
    _waitingWriterCount++;

    if (
            _waitingReaderCount > 0
       ) {
        // signal waiting readers.
        //
        pthread_cond_signal(&_waitingReaders);
    }

    // block until reader consumed _data.
    //
    pthread_cond_wait(&_waitingWriters, &_modifying);

    pthread_mutex_unlock(&_modifying);
    pthread_mutex_unlock(&_writing);
    return YES;
}

- (BOOL)receive:(__autoreleasing id *)outData
{
    pthread_mutex_lock(&_reading);
    pthread_mutex_lock(&_modifying);
    
    while (
            !_isClosed && !_waitingWriterCount
          ) {
        // block until writer has set _data.
        //
        _waitingReaderCount++;
        pthread_cond_wait(&_waitingReaders, &_modifying);
        _waitingReaderCount--;
    }
    
    if (
            _isClosed
       ) {
        pthread_mutex_unlock(&_modifying);
        pthread_mutex_unlock(&_reading);
        return NO;
    }
    
    if (
            outData
       ) {
        *outData = _data;
    }
    _waitingWriterCount--;
    
    // signal waiting writer.
    // 
    pthread_cond_signal(&_waitingWriters);
    
    pthread_mutex_unlock(&_modifying);
    pthread_mutex_unlock(&_reading);
    return YES;
}

- (BOOL)close
{
    BOOL 
    success = YES;
    pthread_mutex_lock(&_modifying);
    if (
            _isClosed
       ) {
        // channel already closed.
        //
        success = NO;
    }
    else {
        // otherwise close it.
        //
        _isClosed = YES;
        pthread_cond_broadcast(&_waitingReaders);
        pthread_cond_broadcast(&_waitingWriters);
    }
    pthread_mutex_unlock(&_modifying);
    return success;
}

- (void)dealloc
{
    pthread_mutex_destroy(&_writing);
    pthread_mutex_destroy(&_reading);

    pthread_mutex_destroy(&_modifying);
    pthread_cond_destroy(&_waitingReaders);
    pthread_cond_destroy(&_waitingWriters);
}

@end
