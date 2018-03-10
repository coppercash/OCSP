//
//  OCSPAsyncReadWriteChannel+Internal.h
//  OCSP
//
//  Created by William on 24/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel.h"
#import "OCSPAsyncChannel.h"
#import "OCSPDebug.h"

NS_ASSUME_NONNULL_BEGIN

typedef
NS_ENUM(NSInteger, OCSPAsyncChannelSlotState)
{
    OCSPAsyncChannelSlotStateEmpty = 0,
    OCSPAsyncChannelSlotStateFilled,
    OCSPAsyncChannelSlotStateClosed,
};

@interface
OCSPAsyncChannelSlot : NSObject
@property (readonly, nullable) id data;
@property (readonly) OCSPAsyncChannelSlotState state;
- (void)empty;
- (void)fillWithData:(id __nullable)data;
- (void)close;

#ifdef OCSPDEBUG
- (NSString *)debugIDSel:(id __nullable)selection
                  caseID:(id __nullable)caseID;
#endif

@end

NS_ASSUME_NONNULL_END
