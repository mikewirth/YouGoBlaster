//
//  TimeOffsetView.m
//  YouGoBlaster
//
//  Created by James Guthrie on 12/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import "TimeOffsetView.h"

@implementation TimeOffsetView

@synthesize timeOffset;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    CGContextRef myContext = UIGraphicsGetCurrentContext();
    
    CGContextSetRGBStrokeColor(myContext, 200/255.0, 200/255.0, 200/255.0, 1.0);
    // Draw them with a 2.0 stroke width so they are a bit more visible.
    CGContextSetLineWidth(myContext, 2.0);
    
    CGFloat center = self.bounds.origin.x + (self.bounds.size.width/2);
    
    for (int i=-6;i<7;i++){
        if ((int)round((timeOffset * 200)) == i){
            CGContextSetRGBStrokeColor(myContext, 200/255.0, 0.0, 0.0, 1.0);
        }else{
            if (i == 0){
                CGContextSetRGBStrokeColor(myContext, 120/255.0, 120/255.0, 120/255.0, 1.0);
            }
        }
        CGContextMoveToPoint(myContext, center + i*10,self.bounds.origin.y + 6);
        CGContextAddLineToPoint(myContext, center + i*10, self.bounds.origin.y + self.bounds.size.height - 6);
        CGContextStrokePath(myContext);
        if ((int)round((timeOffset * 1000/5)) == i || i == 0){
            CGContextSetRGBStrokeColor(myContext, 200/255.0, 200/255.0, 200/255.0, 1.0);
        }
    }
}


- (void)dealloc
{
    [super dealloc];
}

- (void)updateTimeOffest:(double)offset{
    self.timeOffset = offset;
    [self setNeedsDisplay];
}

@end
