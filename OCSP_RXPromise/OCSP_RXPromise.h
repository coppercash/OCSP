//
//  OCSP_RXPromise.h
//  OCSP+RXPromise
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <OCSP/OCSP.h>

NS_ASSUME_NONNULL_BEGIN

@class
RXPromise;

@interface
OCSPAsyncChannel<__covariant Data> (RXPromise)
@property (readonly) RXPromise *(^orx_receive)(void);
@end

@interface
OCSPAsyncReadWriteChannel<__covariant Data> (RXPromise)
@property (readonly) RXPromise *(^orx_send)(Data __nullable data);
@end

@interface
OCSPRXChannelError : NSError
+ (NSError *)closed;
@end

@interface
OCSPRXSelectionBuilder : NSObject
@property (readonly) OCSPRXSelectionBuilder * (^receive)(OCSPAsyncChannel *);
@property (readonly) OCSPRXSelectionBuilder * (^send)(id __nullable, OCSPAsyncReadWriteChannel *);
@property (readonly) void (^default_)(void);
@end

@interface
OCSRXSelectionResult : NSObject
@property (readonly) NSInteger index;
@property (readonly, nullable) id data;
@end

typedef
void(^OCSPRXSelectionBuildup)(OCSPRXSelectionBuilder *_);
FOUNDATION_EXPORT const
RXPromise *(^OCSPRXSelect)(OCSPRXSelectionBuildup);

@compatibility_alias
ORXSelecting OCSPRXSelectionBuilder;
@compatibility_alias
ORXSelected OCSRXSelectionResult;
FOUNDATION_EXPORT const
RXPromise *(^ORXSelect)(OCSPRXSelectionBuildup);

NS_ASSUME_NONNULL_END

