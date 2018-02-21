//
//  OCSPChannel.m
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"
#import "OCSPChannel+Internal.h"
#import <pthread/pthread.h>

@implementation OCSPChannel 

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
