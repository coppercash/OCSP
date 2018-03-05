//
//  OCSPAsyncChannel.m
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@implementation
OCSPAsyncChannel

- (void)receive:(void(^)(id, BOOL))callback
{
    NSAssert(NO, @"not implemented");
}

- (void)receiveOn:(dispatch_queue_t)queue
               with:(void(^)(id, BOOL))callback
{
    NSAssert(NO, @"not implemented");
}

@end
