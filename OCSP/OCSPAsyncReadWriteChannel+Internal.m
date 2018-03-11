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

- (instancetype)init
{
    if (!(
          self = [super init]
          )) { return nil; }
    _state = OCSPAsyncChannelSlotStateEmpty;
    return self;
}
/*
- (void)empty
{
    switch (
            _state
            ) {
        case
            OCSPAsyncChannelSlotStateWritten
            :
        case
            OCSPAsyncChannelSlotStateRead
            : {
                _data = nil;
                _state = OCSPAsyncChannelSlotStateEmpty;
            } break;
        default:
            NSAssert(NO, @"Invalid state transmission.");
            break;
    }
}
 */

- (void)write:(id)data
{
    switch (
            _state
            ) {
        case
            OCSPAsyncChannelSlotStateEmpty
            : {
                _data = data;
                _state = OCSPAsyncChannelSlotStateWriting;
            } break;
        case
            OCSPAsyncChannelSlotStateReading
            : {
                _data = data;
                _state = OCSPAsyncChannelSlotStateWritten;
            } break;
        case
            OCSPAsyncChannelSlotStateRead
            : {
                _data = nil;
                _state = OCSPAsyncChannelSlotStateEmpty;
            } break;
        default:
            NSAssert(NO, @"Invalid state transmission.");
            break;
    }
}

- (void)read:(id __autoreleasing *)outData
{
    switch (
            _state
            ) {
        case
            OCSPAsyncChannelSlotStateEmpty
            : {
                if (
                    outData != nil
                    ) {
                    *outData = _data;
                }
                _state = OCSPAsyncChannelSlotStateReading;
            } break;
        case
            OCSPAsyncChannelSlotStateWriting
            : {
                if (
                    outData != nil
                    ) {
                    *outData = _data;
                }
                _state = OCSPAsyncChannelSlotStateRead;
            } break;
        case
            OCSPAsyncChannelSlotStateWritten
            : {
                if (
                    outData != nil
                    ) {
                    *outData = _data;
                }
                _state = OCSPAsyncChannelSlotStateEmpty;
            } break;
        default:
            NSAssert(NO, @"Invalid state transmission.");
            break;
    }
}

- (void)close
{
    _data = nil;
    _state = OCSPAsyncChannelSlotStateClosed;
}

#ifdef OCSPDEBUG

- (NSString *)debugID
{
    return [self debugIDSel:nil
                     caseID:nil];
}

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
