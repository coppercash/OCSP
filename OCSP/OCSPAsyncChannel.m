//
//  OCSPAsyncChannel.m
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@implementation OCSPAsyncChannel
- (void)receiveIn:(void(^)(id, BOOL))callback { if (callback) { callback(nil, NO); } }
@end

@implementation OCSPAsyncReadWriteChannel

- (void)receiveIn:(void(^)(id data, BOOL ok))callback
{
    
}

- (void)send:(id)value
        with:(void(^)(BOOL ok))callback
{
    
}

@end
