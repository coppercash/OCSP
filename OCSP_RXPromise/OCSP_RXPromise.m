//
//  OCSP_RXPromise.m
//  OCSP+RXPromise
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSP_RXPromise.h"
#import <RXPromise/RXPromise.h>

typedef
id Data;

// MARK: - OCSPAsyncChannel

@implementation
OCSPAsyncChannel (RXPromise)

- (RXPromise *(^)(void))orx_receive
{
    __auto_type const __unsafe_unretained
    channel = self;
    return ^RXPromise *(void) {
        __auto_type const
        promise = [[RXPromise alloc] init];
        [channel receive:
         ^(Data data, BOOL ok) {
             ok ?
             [promise fulfillWithValue:data] :
             [promise rejectWithReason:OCSPRXChannelError.closed];
         }];
        return promise;
    };
}

@end

// MARK: - OCSPAsyncReadWriteChannel

@implementation
OCSPAsyncReadWriteChannel (RXPromise)

- (RXPromise *(^)(Data))orx_send
{
    __auto_type const __unsafe_unretained
    channel = self;
    return ^RXPromise *(Data data) {
        __auto_type const
        promise = [[RXPromise alloc] init];
        [channel send:data
                 with:
         ^(BOOL ok) {
             ok ?
             [promise fulfillWithValue:nil] :
             [promise rejectWithReason:OCSPRXChannelError.closed];
         }];
        return promise;
    };
}

@end

// MARK: - OCSPRXChannelError

@implementation
OCSPRXChannelError

+ (NSError *)closed
{
    return [NSError errorWithDomain:NSStringFromClass(self.class)
                               code:-1
                           userInfo:nil];
}

@end

// MARK: - OCSPRXSelectionTry

typedef
NS_ENUM(NSInteger, OCSPRXSelectionTryType) {
    OCSPRXSelectionTryTypeUnknown,
    OCSPRXSelectionTryTypeSend,
    OCSPRXSelectionTryTypeReceive,
    OCSPRXSelectionTryTypeDefault,
};

@interface
OCSPRXSelectionTry : NSObject
@property (readonly) OCSPRXSelectionTryType type;
@property (readonly, nullable) OCSPAsyncChannel __kindof *channel;
@property (readonly, nullable) id data;
@end
@implementation
OCSPRXSelectionTry

- (instancetype)initWithType:(OCSPRXSelectionTryType)type
                     channel:(OCSPAsyncChannel __kindof *)channel
                        data:(id)data
{
    if (!(
          self = [super init]
          )) { return nil; }
    _type = type;
    _channel = channel;
    _data = data;
    return self;
}

@end

// MARK: - OCSPRXSelectionBuilder

@interface
OCSPRXSelectionBuilder (Internal)
@property (readonly) NSMutableArray<OCSPRXSelectionTry *> *tries;
@end

@implementation
OCSPRXSelectionBuilder
{
    NSMutableArray<OCSPRXSelectionTry *> *
    _tries;
}
- (NSMutableArray<OCSPRXSelectionTry *> *)tries { return _tries; }

- (instancetype)init
{
    if (!(
          self = [super init]
          )) { return nil; }
    _tries = [[NSMutableArray alloc] init];
    return self;
}

- (OCSPRXSelectionBuilder *(^)(OCSPAsyncChannel *))receive
{
    __auto_type const __unsafe_unretained
    builder = self;
    return ^(OCSPAsyncChannel *channel) {
        [builder.tries addObject:
         [[OCSPRXSelectionTry alloc] initWithType:OCSPRXSelectionTryTypeReceive
                                          channel:channel
                                             data:nil
          ]
         ];
        return builder;
    };
}

- (OCSPRXSelectionBuilder *(^)(id, OCSPAsyncReadWriteChannel *))send
{
    __auto_type const __unsafe_unretained
    builder = self;
    return ^(id data, OCSPAsyncChannel *channel) {
        [builder.tries addObject:
         [[OCSPRXSelectionTry alloc] initWithType:OCSPRXSelectionTryTypeSend
                                          channel:channel
                                             data:data
          ]
         ];
        return builder;
    };
}

- (void (^)(void))default_
{
    __auto_type const __unsafe_unretained
    builder = self;
    return ^{
        [builder.tries addObject:
         [[OCSPRXSelectionTry alloc] initWithType:OCSPRXSelectionTryTypeDefault
                                          channel:nil
                                             data:nil
          ]
         ];
    };
}

@end

// MARK: - OCSRXSelectionResult

@implementation
OCSRXSelectionResult
{
    NSInteger
    _index;
    id
    _data;
}
- (NSInteger)index { return _index; }
- (id)data { return _data; }

- (instancetype)initWithIndex:(NSInteger)index
                         data:(id)data
{
    if (!(
          self = [super init]
          )) { return nil; };
    _index = index;
    _data = data;
    return self;
}

- (instancetype)initWithIndex:(NSInteger)index
{
    return [self initWithIndex:index
                          data:nil];
}

@end

// MARK: - OCSPRXSelect

RXPromise *(^OCSPRXSelect)(OCSPRXSelectionBuildup) =
^RXPromise *(OCSPRXSelectionBuildup buildup) {
    __auto_type const
    builder = [[OCSPRXSelectionBuilder alloc] init];
    buildup(builder);
    __auto_type const
    promise = [[RXPromise alloc] init];
    OCSPAsyncSelect(^(OCSPAsyncSelectionBuilder *case_) {
        for (__auto_type
             i = 0; i < builder.tries.count; i++
             ) {
            __auto_type const
            t = builder.tries[i];
            switch (
                    t.type
                    ) {
                case
                    OCSPRXSelectionTryTypeSend
                    : {
                        __auto_type const
                        channel = (OCSPAsyncReadWriteChannel *)t.channel;
                        [channel send:t.data
                                   in:case_
                                 with:
                         ^(BOOL ok) {
                             ok ?
                             [promise fulfillWithValue:
                              [[OCSRXSelectionResult alloc] initWithIndex:i]
                              ] :
                             [promise rejectWithReason:OCSPRXChannelError.closed];
                         }];
                    } break;
                case
                    OCSPRXSelectionTryTypeReceive
                    : {
                        __auto_type const
                        channel = t.channel;
                        [channel receiveIn:case_
                                      with:
                         ^(id data, BOOL ok) {
                             ok ?
                             [promise fulfillWithValue:
                              [[OCSRXSelectionResult alloc] initWithIndex:i
                                                                     data:data]
                              ] :
                             [promise rejectWithReason:OCSPRXChannelError.closed];
                         }];
                    } break;
                default
                    : {
                        [case_ default:^{
                            [promise fulfillWithValue:
                             [[OCSRXSelectionResult alloc] initWithIndex:NSNotFound]
                             ];
                        }];
                    } break;
            }
        }
    });
    return promise;
};

// MARK: - Shortcuts

RXPromise *(^ORXSelect)(OCSPRXSelectionBuildup) =
^RXPromise *(OCSPRXSelectionBuildup buildup) {
    return OCSPRXSelect(buildup);
};
