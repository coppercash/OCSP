//
//  OCSPChannel.h
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCSPChannel<Data : id> : NSObject
{
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
- (BOOL)receive:(Data __nullable __autoreleasing * __nullable)outData;
@end
