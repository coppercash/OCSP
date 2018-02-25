//
//  OCSPAsyncReadWriteChannel+Internal.h
//  OCSP
//
//  Created by William on 24/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel.h"
#import "OCSPAsyncChannel+Internal.h"

@interface
OCSPAsyncReadWriteChannelState : OCSPAsyncChannelState
{
@public
    id
    _data;
}
@end
