//
//  OCSPAsyncSelect+Internal.h
//  OCSP
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncSelect.h"

typedef
void(^OCSPAsyncSelectDetermine)(void);
typedef
void(^OCSPAsyncSelectHesitate)(void);
typedef
void(^OCSPAsyncSelectTry)
(
 OCSPAsyncSelectDetermine determine,
 OCSPAsyncSelectHesitate hesitate
 );

@class
OCSPAsyncLock,
OCSPAsyncCondition;
@interface
OCSPAsyncSelectionBuilder (Internal)
@property (readonly) NSMutableArray<OCSPAsyncLock *> *locks;
@property (readonly) NSMutableArray<OCSPAsyncCondition *> *conditions;
@property (readonly) NSMutableArray<OCSPAsyncSelectTry> *tries;
@end
