//
//  OCSPChannel.m
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"
#import <pthread/pthread.h>

typedef NS_OPTIONS(NSInteger, OCSPChannelFlag) {
    OCSPChannelFlagBase = 0x1,
    OCSPChannelFlagModifying = OCSPChannelFlagBase << 1,
    OCSPChannelFlagWaitingReaders = OCSPChannelFlagModifying << 1,
    OCSPChannelFlagWaitingWriters = OCSPChannelFlagWaitingReaders << 1,
};

@implementation OCSPChannel {
    @protected
    pthread_mutex_t
    _modifying;
    pthread_cond_t
    _waitingWriters,
    _waitingReaders;
    NSUInteger
    _waitingWriterCount,
    _waitingReaderCount;
    BOOL
    _isClosed;
    NSInteger
    _flags;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _flags = 0;
    if (
        pthread_mutex_init(&_modifying, NULL) != 0
        ) { return nil; }
    _flags |= OCSPChannelFlagModifying;
    if (
        pthread_cond_init(&_waitingReaders, NULL) != 0
        ) { return nil; }
    _flags |= OCSPChannelFlagWaitingReaders;
    if (
        pthread_cond_init(&_waitingWriters, NULL) != 0
        ) { return nil; }
    _flags |= OCSPChannelFlagWaitingWriters;
    
    _isClosed = NO;
    _waitingReaderCount = 0;
    _waitingWriterCount = 0;
    return self;
}

- (void)dealloc
{
    if (
        _flags & OCSPChannelFlagWaitingWriters
        ) {
        pthread_cond_destroy(&_waitingWriters);
    }
    if (
        _flags & OCSPChannelFlagWaitingReaders
        ) {
        pthread_cond_destroy(&_waitingReaders);
    }
    if (
        _flags & OCSPChannelFlagModifying
        ) {
        pthread_mutex_destroy(&_modifying);
    }
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

- (BOOL)receive:(id __autoreleasing *)outValue { return NO; }

@end

typedef NS_OPTIONS(NSInteger, OCSPReadWriteChannelFlag) {
    OCSPReadWriteChannelFlagBase = OCSPChannelFlagWaitingWriters,
    OCSPReadWriteChannelFlagReading = OCSPReadWriteChannelFlagBase << 1,
    OCSPReadWriteChannelFlagWriting = OCSPReadWriteChannelFlagReading << 1,
};

@implementation OCSPReadWriteChannel {
    pthread_mutex_t
    _writing,
    _reading;
    id
    _data;
}

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    if (
        pthread_mutex_init(&_reading, NULL) != 0
        ) {
        return nil;
    }
    _flags |= OCSPReadWriteChannelFlagReading;
    if (
        pthread_mutex_init(&_writing, NULL) != 0
        ) {
        return nil;
    }
    _flags |= OCSPReadWriteChannelFlagWriting;
    _data = nil;
    return self;
}

- (void)dealloc
{
    [self close];
    
    if (
        _flags & OCSPReadWriteChannelFlagWriting
        ) {
        pthread_mutex_destroy(&_writing);
    }
    if (
        _flags & OCSPReadWriteChannelFlagReading
        ) {
        pthread_mutex_destroy(&_reading);
    }
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
    return [super close];
}

@end

@implementation OCSPBufferedReadWriteChannel {
    NSMutableArray *
    _queue;
    NSUInteger
    _capacity;
}

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
        _waitingWriterCount++;
        pthread_cond_wait(&_waitingWriters, &_modifying);
        _waitingWriterCount--;
    }
    
    [_queue addObject:data];

    if (
        _waitingReaderCount > 0
        ) {
        // signal waiting reader.
        //
        pthread_cond_signal(&_waitingReaders);
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
        _waitingReaderCount++;
        pthread_cond_wait(&_waitingReaders, &_modifying);
        _waitingReaderCount--;
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
        _waitingWriterCount > 0
        ) {
        // signal waiting writer.
        //
        pthread_cond_signal(&_waitingWriters);
    }
    
    pthread_mutex_unlock(&_modifying);
    return YES;
}

- (BOOL)close
{
    return [super close];
}

@end
