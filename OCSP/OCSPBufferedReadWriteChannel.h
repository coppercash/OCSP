//
//  OCSPBufferedReadWriteChannel.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

@interface
OCSPBufferedReadWriteChannel<Data : id> : OCSPChannel
{
    NSMutableArray *
    _queue;
    NSUInteger
    _readerCount,
    _capacity;
}
- (instancetype __nonnull)initWithCapacity:(NSUInteger)capacity;
- (BOOL)send:(Data __nullable)value;
- (BOOL)close;
@end
