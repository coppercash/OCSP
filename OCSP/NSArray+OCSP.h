//
//  NSArray+OCSP.h
//  OCSP
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT int const
nsarray_ocsp_export;

@interface NSArray (OCSP)
- (instancetype)ocsp_duplicateFreeCopy;
@end
