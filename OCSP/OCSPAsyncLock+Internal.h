//
//  OCSPAsyncLock+Internal.h
//  OCSP
//
//  Created by William on 10/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncLock.h"
#import "OCSPDebug.h"

#ifdef OCSPDEBUG
@interface OCSPAsyncLock (Internal)
- (instancetype)initWithLabel:(NSString *)label;
@end
#endif
