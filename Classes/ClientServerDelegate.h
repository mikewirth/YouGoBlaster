//
//  ServerDelegate.h
//  YouGoBlaster
//
//  Created by James Guthrie on 10/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Server,Client;

@protocol ClientServerDelegate

- (void) roomTerminated:(id)room reason:(NSString*)string;
- (void) setPlayStatus:(bool)status;
- (void) updateTimerDisplay:(double)time withDelta:(double)delta withRSQ:(double)RSQ withStatus:(NSString*)status;
- (void) fetchChanges;

@end
