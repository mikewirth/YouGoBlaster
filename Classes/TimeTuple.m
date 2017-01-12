//
//  CommTime.m
//  YouGoBlaster
//
//  Created by James Guthrie on 11/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import "TimeTuple.h"


@implementation TimeTuple

@synthesize RTTTime, actualTime;

- (NSComparisonResult) compareRTT:(TimeTuple *)timeTuple{
    if ([self RTTTime] < [timeTuple RTTTime]){
        return NSOrderedAscending;
    }
    if ([self RTTTime] > [timeTuple RTTTime]){
        return NSOrderedDescending;
    }
    return NSOrderedSame;
}
@end
