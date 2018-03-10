//
//  OCSPAsyncReadWriteChannel+Internal.m
//  OCSP
//
//  Created by William on 24/02/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncReadWriteChannel+Internal.h"

@implementation
OCSPAsyncChannelSlot {
    id
    _data;
    OCSPAsyncChannelSlotState
    _state;
}
- (id)data { return _data; }
- (OCSPAsyncChannelSlotState)state { return _state; }

- (void)empty
{
    _data = nil;
    _state = OCSPAsyncChannelSlotStateEmpty;
}

- (void)fillWithData:(id)data
{
    _data = data;
    _state = OCSPAsyncChannelSlotStateFilled;
}

- (void)close
{
    _data = nil;
    _state = OCSPAsyncChannelSlotStateClosed;
}

#ifdef OCSPDEBUG

- (NSString *)debugIDSel:(id)selection
                  caseID:(id)caseID
{
    return [NSString stringWithFormat:
            @"📭(%p)%@",
            self,
            ((selection == nil) ? @"" :
            [NSString stringWithFormat:
             @"\\👄(%@)\\⚔️(%p)",
             caseID,
             selection
             ])
            ];
}

#endif

@end
