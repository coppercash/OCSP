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
read,
write;
@property (nonatomic, strong) id
value;
@end

@implementation OCSPReadWriteChannel

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _read = dispatch_semaphore_create(0);
    _write = dispatch_semaphore_create(1);
    return self;
}

- (BOOL)receive:(__autoreleasing id *)outValue
{
    dispatch_semaphore_wait(self.read, DISPATCH_TIME_FOREVER);
    if (
        outValue
        ) {
        *outValue = self.value;
    }
    dispatch_semaphore_signal(self.write);
    return YES;
}

- (BOOL)send:(id)value
{
    dispatch_semaphore_wait(self.write, DISPATCH_TIME_FOREVER);
    self.value = value;
    dispatch_semaphore_signal(self.read);
    return YES;
}

- (void)send:(id)value
        with:(void(^)(BOOL))callback
{
    
}

@end
