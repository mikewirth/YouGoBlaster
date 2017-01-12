//
//  ServerViewController.h
//  YouGoBlaster
//
//  Created by James Guthrie on 7/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Server.h"
#import "ClientServerDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ServerViewController : UIViewController <ClientServerDelegate, MPMediaPickerControllerDelegate, UITableViewDataSource, UITableViewDelegate> {
    Server*   server;
    IBOutlet UILabel* time;
    IBOutlet UILabel* delta;
    IBOutlet UILabel* RSQ;
    IBOutlet UILabel* status;
    IBOutlet UILabel* serverLabel;
    IBOutlet UITableView* clientList;
    AVAudioPlayer*  player;
    NSMutableString* songTitle;
}

@property(nonatomic,retain) Server* server;
@property(nonatomic,assign)	AVAudioPlayer	*player;
@property(nonatomic,retain) UITableView* clientList;
@property(nonatomic,retain) NSMutableString* songTitle;

- (IBAction) selectSong;

- (void) updateTimerDisplay:(double)theTime withDelta:(double)theDelta withRSQ:(double)rSquared withStatus:(NSString*)theStatus;

- (void) displayMediaPicker;

- (void) activate;

@end
