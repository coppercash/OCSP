//
//  OCSPChannel+Internal.h
//  OCSP
//
//  Created by William on 21/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

typedef NS_OPTIONS(NSInteger, OCSPChannelFlag) {
    OCSPChannelFlagBase = 0x1,
    OCSPChannelFlagModifying = OCSPChannelFlagBase << 1,
    OCSPChannelFlagWaitingReaders = OCSPChannelFlagModifying << 1,
    OCSPChannelFlagWaitingWriters = OCSPChannelFlagWaitingReaders << 1,
};

@interface OCSPChannel (Internal)
- (BOOL)close;
@end
