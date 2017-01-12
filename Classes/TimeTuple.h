//
//  CommTime.h
//  YouGoBlaster
//
//  Created by James Guthrie on 11/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TimeTuple : NSObject {
    double RTTTime;
    double actualTime;
}

@property (nonatomic,assign) double RTTTime;
@property (nonatomic,assign) double actualTime;

- (NSComparisonResult) compareRTT:(TimeTuple *)timeTuple;
@end
