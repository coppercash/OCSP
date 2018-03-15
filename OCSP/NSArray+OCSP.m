//
//  NSArray+OCSP.m
//  OCSP
//
//  Created by William on 15/03/2018.
//  Copyright © 2018 coppercash. All rights reserved.
//

#import "NSArray+OCSP.h"

int const
nsarray_ocsp_export = 0;

@implementation NSArray (OCSP)

- (instancetype)ocsp_duplicateFreeCopy
{
    NSMutableOrderedSet *
    refs = [[NSMutableOrderedSet alloc] initWithCapacity:self.count];
    for (id
         element in self
         ) {
        [refs addObject:[NSValue valueWithNonretainedObject:element]];
    }
    NSMutableArray *
    dupfree = [[NSMutableArray alloc] initWithCapacity:refs.count];
    for (NSValue *
         ref in refs
         ) {
        [dupfree addObject:ref.nonretainedObjectValue];
    }
    return dupfree;
}

@end
