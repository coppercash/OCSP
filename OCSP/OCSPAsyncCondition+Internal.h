//
//  OCSPAsyncCondition+Internal.h
//  OCSP
//
//  Created by William on 11/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncCondition.h"
#import "OCSPDebug.h"

NS_ASSUME_NONNULL_BEGIN

#ifdef OCSPDEBUG_COND

@interface OCSPAsyncCondition (Internal)
- (instancetype)initWithLabel:(NSString *)label;
@end
#endif

NS_ASSUME_NONNULL_END
