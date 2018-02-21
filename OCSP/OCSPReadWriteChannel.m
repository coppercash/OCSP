//
//  OCSPReadWriteChannel.m
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPReadWriteChannel.h"
#import "OCSPChannel+Internal.h"
#import <pthread/pthread.h>

typedef NS_OPTIONS(NSInteger, OCSPReadWriteChannelFlag) {
    OCSPReadWriteChannelFlagBase = OCSPChannelFlagWaitingWriters,
    OCSPReadWriteChannelFlagReading = OCSPReadWriteChannelFlagBase << 1,
    OCSPReadWriteChannelFlagWriting = OCSPReadWriteChannelFlagReading << 1,
};

@implementation OCSPReadWriteChannel

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
           !_isClosed && (_waitingWriterCount == 0)
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
