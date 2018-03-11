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
    OCSPAsyncChannelSlotStateEmpty = 1,
    OCSPAsyncChannelSlotStateWriting,
    OCSPAsyncChannelSlotStateRead,
    OCSPAsyncChannelSlotStateReading,
    OCSPAsyncChannelSlotStateWritten,
    OCSPAsyncChannelSlotStateClosed,
};

@interface
OCSPAsyncChannelSlot : NSObject
@property (readonly) OCSPAsyncChannelSlotState state;
- (void)write:(id)data;
- (void)read:(id __nullable __autoreleasing * __nullable)outData;
- (void)close;

#ifdef OCSPDEBUG
@property (readonly) NSString * debugID;
- (NSString *)debugIDSel:(id __nullable)selection
                  caseID:(id __nullable)caseID;
#endif

@end

NS_ASSUME_NONNULL_END
