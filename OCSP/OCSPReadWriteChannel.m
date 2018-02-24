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
    // Exlusive [writer, modifier] at any given time.
    //
    pthread_mutex_lock(&_writing);
    pthread_mutex_lock(&_modifying);
    
    _data = data;
    _dataCount++;
    
    // Signal data written in to waiting readers.
    //
    pthread_cond_signal(&_writtenIn);

    // Wait for
    // data read out by readers
    // or channel closed.
    //
    while (!(
             _isClosed || (_dataCount == 0)
             )) {
        pthread_cond_wait(&_readOut, &_modifying);
    }
    
    // Reject if waked on channel closed
    //
    if (
        _isClosed
        ) {
        pthread_mutex_unlock(&_modifying);
        pthread_mutex_unlock(&_writing);
        return NO;
    }
    
    pthread_mutex_unlock(&_modifying);
    pthread_mutex_unlock(&_writing);
    return YES;
}

- (BOOL)receive:(__autoreleasing id *)outData
{
    // Exlusive [reader, modifier] at any given time.
    //
    pthread_mutex_lock(&_reading);
    pthread_mutex_lock(&_modifying);
    
    // Wait for
    // data written in by writters
    // or channel closed.
    //
    while (!(
             _isClosed || (_dataCount > 0)
             )) {
        pthread_cond_wait(&_writtenIn, &_modifying);
    }
    
    // Reject if waked on channel closed
    //
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
    _dataCount--;
    
    // Signal data read out to waiting writer.
    //
    pthread_cond_signal(&_readOut);
    
    pthread_mutex_unlock(&_modifying);
    pthread_mutex_unlock(&_reading);
    return YES;
}

- (BOOL)close
{
    return [super close];
}

@end
