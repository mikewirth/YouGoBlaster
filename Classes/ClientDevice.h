//
//  ClientDevice.h
//  YouGoBlaster
//
//  Created by James Guthrie on 14/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ClientDevice : NSObject {
    NSString* hostName;
    UInt16 port;
}

@property(nonatomic,assign) NSString* hostName;
@property(nonatomic,assign) UInt16 port;

@end
