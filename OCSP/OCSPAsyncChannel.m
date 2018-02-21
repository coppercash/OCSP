//
//  OCSPAsyncChannel.m
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@implementation OCSPAsyncChannel

- (void)receiveWithOn:(dispatch_queue_t)queue
             callback:(void(^)(id, BOOL))callback
{
    if (callback) { callback(nil, NO); }
}

@end

