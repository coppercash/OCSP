//
//  OCSPAsyncReadWriteChannel+Internal.m
//  OCSP
//
//  Created by William on 24/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel+Internal.h"

@implementation
OCSPAsyncReadWriteChannelState

- (instancetype)init
{
    if (!(
          self = [super init]
          )) {  return nil; }
    _data = nil;
    return self;
}

@end
