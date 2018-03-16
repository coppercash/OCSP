//
//  OCSPShortcuts.h
//  OCSP
//
//  Created by William on 10/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncChannel.h"

@compatibility_alias
AChan OCSPAsyncChannel;

#import "OCSPAsyncReadWriteChannel.h"

@compatibility_alias
ARWChan OCSPAsyncReadWriteChannel;

#import "OCSPAsyncSelect.h"

@compatibility_alias
ASelecting OCSPAsyncSelectionBuilder;

FOUNDATION_EXPORT const
void(^ASelect)(void(^)(ASelecting *));
