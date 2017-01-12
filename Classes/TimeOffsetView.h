//
//  TimeOffsetView.h
//  YouGoBlaster
//
//  Created by James Guthrie on 12/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface TimeOffsetView : UIView {
    double timeOffset;
}

@property(nonatomic,assign) double timeOffset;

- (void)updateTimeOffest:(double)offset;

@end
