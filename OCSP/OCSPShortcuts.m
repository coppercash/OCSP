//
//  OCSPShortcuts.m
//  OCSP
//
//  Created by William on 16/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPShortcuts.h"

const
void(^ASelect)(void(^)(ASelecting *)) = ^(void(^_)(ASelecting *)) {
    return OCSPAsyncSelect(_);
};
