//
//  ClientViewController.h
//  YouGoBlaster
//
//  Copyright (c) 2009 Peter Bakhyryev <peter@byteclub.com>, ByteClub LLC
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//  
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//  
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>
#import "ClientServerDelegate.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "TimeOffsetView.h"


@interface ClientViewController : UIViewController <ClientServerDelegate, AVAudioPlayerDelegate> {
    Client*   client;
    IBOutlet UILabel* time;
    IBOutlet UILabel* delta;
    IBOutlet UILabel* RSQ;
    IBOutlet UILabel* status;
    IBOutlet UILabel* serverLabel;
    IBOutlet UILabel* nowPlaying;
    IBOutlet UIButton* resyncButton;
    IBOutlet TimeOffsetView* timeOffsetView;
    AVAudioPlayer*  player;
}

@property(nonatomic,retain) Client* client;
@property(nonatomic,assign)	AVAudioPlayer	*player;
@property(nonatomic,retain) UIButton* resyncButton;


// Exit back to the welcome screen
- (IBAction) exit;
- (IBAction) fixTime;
- (IBAction) resync;
- (IBAction) addTime;
- (IBAction) removeTime;

- (void) updateTimerDisplay:(double)theTime withDelta:(double)theDelta withRSQ:(double)rSquared withStatus:(NSString*)theStatus;

// View is active, start everything up
- (void)activate;

@end
