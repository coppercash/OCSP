//
//  OCSPChannel.m
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

@implementation OCSPChannel
- (BOOL)receive:(id __autoreleasing *)outValue { return NO; }
- (void)receiveIn:(void(^)(id, BOOL))callback { if (callback) { callback(nil, NO); } }
@end

@interface OCSPReadWriteChannel ()
@property (readonly, nonatomic, strong) dispatch_semaphore_t
receiver,
sender;
@property (nonatomic, strong) id
value;
@end

@implementation OCSPReadWriteChannel

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    if (pthread_mutex_init(&_writing, NULL) != 0)
    {
        return -1;
    }

    if (pthread_mutex_init(&_reading, NULL) != 0)
    {
        pthread_mutex_destroy(&_writing);
        return -1;
    }

    if (pthread_mutex_init(&_modifying, NULL) != 0)
    {
        pthread_mutex_destroy(&_writing);
        pthread_mutex_destroy(&_reading);
        return -1;
    }

    if (pthread_cond_init(&_waitingReaders, NULL) != 0)
    {
        pthread_mutex_destroy(&_modifying);
        pthread_mutex_destroy(&_writing);
        pthread_mutex_destroy(&_reading);
        return -1;
    }

    if (pthread_cond_init(&_waitingWriters, NULL) != 0)
    {
        pthread_mutex_destroy(&_modifying);
        pthread_mutex_destroy(&_writing);
        pthread_mutex_destroy(&_reading);
        pthread_cond_destroy(&_waitingReaders);
        return -1;
    }

    _isClosed = 0;
    _waitingReaderCount = 0;
    _waitingWriterCount = 0;
    _data = NULL;
    return 0;
    return self;
}

- (BOOL)send:(id)data
{
    pthread_mutex_lock(&_writing);
    pthread_mutex_lock(&_modifying);

    if (_isClosed)
    {
        pthread_mutex_unlock(&_modifying);
        pthread_mutex_unlock(&_writing);
        errno = EPIPE;
        return -1;
    }

    _data = data;
    _waitingWriterCount++;

    if (_waitingReaderCount > 0)
    {
        // Signal waiting reader.
        pthread_cond_signal(&_waitingReaders);
    }

    // Block until reader consumed _data.
    pthread_cond_wait(&_waitingWriters, &_modifying);

    pthread_mutex_unlock(&_modifying);
    pthread_mutex_unlock(&_writing);
    return 0;
}

- (BOOL)receive:(__autoreleasing id *)outValue
{
    pthread_mutex_lock(&_reading);
    pthread_mutex_lock(&_modifying);
    
    while (!_isClosed && !_waitingWriterCount)
    {
        // Block until writer has set _data.
        _waitingReaderCount++;
        pthread_cond_wait(&_waitingReaders, &_modifying);
        _waitingReaderCount--;
    }
    
    if (_isClosed)
    {
        pthread_mutex_unlock(&_modifying);
        pthread_mutex_unlock(&_reading);
        errno = EPIPE;
        return -1;
    }
    
    if (data)
    {
        *data = _data;
    }
    _waitingWriterCount--;
    
    // Signal waiting writer.
    pthread_cond_signal(&_waitingWriters);
    
    pthread_mutex_unlock(&_modifying);
    pthread_mutex_unlock(&_reading);
    return 0;
}

- (void)close
{
    int success = 0;
    pthread_mutex_lock(&_modifying);
    if (_isClosed)
    {
        // Channel already closed.
        success = -1;
        errno = EPIPE;
    }
    else
    {
        // Otherwise close it.
        _isClosed = 1;
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
    free(chan);
}

@end
