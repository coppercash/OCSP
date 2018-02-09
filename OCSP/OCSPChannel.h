//
//  OCSPChannel.h
//  OCSP
//
//  Created by William on 09/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OCSPChannel<Data : id> : NSObject
- (BOOL)receive:(Data __autoreleasing *)outData;
@end

@interface OCSPReadWriteChannel<Data : id> : OCSPChannel
- (BOOL)send:(Data)value;
- (void)close;
@end


