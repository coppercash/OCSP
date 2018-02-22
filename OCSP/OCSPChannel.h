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
    _modifying; // exlusive modifier (reader or writer) at any given time
    pthread_cond_t
    _readOut,   // signal on data read out (or channel closed)
    _writtenIn; // signal on data writren in (or channel closed)
    NSUInteger
    _dataCount; // written in data count. <= 1 if no exception
    BOOL
    _isClosed;
    NSInteger
    _flags;
}
- (BOOL)receive:(Data __nullable __autoreleasing * __nullable)outData;
@end
