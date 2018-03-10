//
//  OCSPAsyncCondition+Internal.h
//  OCSP
//
//  Created by William on 11/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncCondition.h"
#import "OCSPDebug.h"

#ifdef OCSPDEBUG
@interface OCSPAsyncCondition (Internal)
- (instancetype)initWithLabel:(NSString *)label;
@end
#endif

