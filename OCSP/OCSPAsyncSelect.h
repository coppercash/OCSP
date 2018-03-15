//
//  OCSPAsyncSelect.h
//  OCSP
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef
void(^OCSPAsyncSelectionDefaultRun)(void);
@interface OCSPAsyncSelectionBuilder : NSObject
- (void)default:(OCSPAsyncSelectionDefaultRun)run;
@end

typedef
void(^OCSPAsyncSelectionBuildup)(OCSPAsyncSelectionBuilder *case_);
FOUNDATION_EXPORT const
void(^OCSPAsyncSelect)(OCSPAsyncSelectionBuildup);

NS_ASSUME_NONNULL_END

