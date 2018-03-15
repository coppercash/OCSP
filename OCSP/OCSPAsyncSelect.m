//
//  OCSPAsyncSelect.m
//  OCSP
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "OCSPAsyncSelect+Internal.h"
#import "OCSPAsyncLock+Internal.h"
#import "OCSPAsyncCondition+Internal.h"

@implementation
OCSPAsyncSelectionBuilder {
    NSMutableArray<OCSPAsyncLock *> *
    _locks;
    NSMutableArray<OCSPAsyncCondition *> *
    _conditions;
    NSMutableArray<OCSPAsyncSelectTry> *
    _tries;
}
- (NSMutableArray *)locks { return _locks; }
- (NSMutableArray *)conditions { return _conditions; }
- (NSMutableArray *)tries { return _tries; }

- (instancetype)init
{
    if (!(
          self = [super init]
          )) { return nil; }
    _locks = [[NSMutableArray alloc] init];
    _conditions = [[NSMutableArray alloc] init];
    _tries = [[NSMutableArray alloc] init];
    return self;
}

- (void)default:(OCSPAsyncSelectionDefaultRun)run
{
    
    [_tries addObject:
     [
      ^(
        OCSPAsyncSelectDetermine determine,
        OCSPAsyncSelectHesitate hesitate
        ){
          determine();
          !run ?: run();
      }
      copy]
     ];
}

+ (void)try
:(NSArray<OCSPAsyncConditionCheck> *)tries
:(NSInteger)index
:(OCSPAsyncSelectDetermine)determine
:(OCSPAsyncSelectHesitate)hesitate
{
    if (!(
          index < tries.count
          )) {
        hesitate();
        return;
    }
    __auto_type const
    try = tries[index];
    try(
        determine,
        ^{
            [self try
             :tries
             :(index + 1)
             :determine
             :hesitate
             ];
        }
        );
}

@end

const
void(^OCSPAsyncSelect)(OCSPAsyncSelectionBuildup) = ^(OCSPAsyncSelectionBuildup buildup) {
    __auto_type const
    builder = [[OCSPAsyncSelectionBuilder alloc] init];
    buildup(builder);
    __auto_type const
    lock = [[OCSPAsyncCombinedLock alloc] initWithLocks:builder.locks];
    __auto_type const
    condition = [[OCSPAsyncCombinedCondition alloc] initWithConditions:builder.conditions];
    __auto_type const
    tries = builder.tries;
    [condition withLock:lock
                  check:
     ^(OCSPAsyncConditionLeave leave, OCSPAsyncConditionWait wait) {
         [OCSPAsyncSelectionBuilder try
          :tries
          :0
          :leave
          :wait
          ];
     }];
};


