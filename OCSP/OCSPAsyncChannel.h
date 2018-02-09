//
//  OCSPAsyncChannel.h
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPChannel.h"

@interface OCSPAsyncChannel<Data : id> : OCSPChannel
- (void)receiveIn:(void(^)(Data data, BOOL ok))callback;
@end

@interface OCSPAsyncReadWriteChannel<Data : id> : OCSPReadWriteChannel
- (void)receiveIn:(void(^)(Data data, BOOL ok))callback;
- (void)send:(Data)value
        with:(void(^)(BOOL ok))callback;
@end
