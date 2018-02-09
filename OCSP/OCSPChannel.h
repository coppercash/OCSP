//
//  OCSPChannel.h
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCSPChannel<Value : id> : NSObject
- (BOOL)receive:(Value __autoreleasing *)outValue;
- (void)receiveIn:(void(^)(Value value, BOOL ok))callback;
@end

@interface OCSPReadWriteChannel<Value : id> : OCSPChannel<Value>
- (BOOL)send:(Value)value;
- (void)send:(Value)value
        with:(void(^)(BOOL ok))callback;
@end
