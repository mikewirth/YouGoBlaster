//
//  ClientViewController.m
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

#import "ClientViewController.h"
#import "YouGoBlasterAppDelegate.h"
#import "AppConfig.h"

@implementation ClientViewController

@synthesize client;
@synthesize player;
@synthesize resyncButton;

bool shouldPlay = 0;

// After view shows up, start the room
- (void)activate {
    // Load the the sample file, use mono or stero sample	
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath: [[NSBundle mainBundle] pathForResource:@"sample2" ofType:@"wav"]];
    
	self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];	
	if (self.player)
	{
		//fileName.text = [NSString stringWithFormat: @"%@ (%d ch.)", [[player.url relativePath] lastPathComponent], player.numberOfChannels, nil];
		//[self updateViewForPlayerInfo:player];
		//[self updateViewForPlayerState:player];
		player.numberOfLoops = 0;
		player.delegate = self;
	}
	
	OSStatus result = AudioSessionInitialize(NULL, NULL, NULL, NULL);
	if (result)
		NSLog(@"Error initializing audio session! %ld", result);
	
	[[AVAudioSession sharedInstance] setDelegate: self];
	NSError *setCategoryError = nil;
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
	if (setCategoryError)
		NSLog(@"Error setting category! %@", setCategoryError);
    float aBufferLength = 0.005; // In seconds
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(aBufferLength), &aBufferLength);
	
	//result = AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange, RouteChangeListener, self);
	if (result) 
		NSLog(@"Could not add property listener! %ld", result);
	[fileURL release];
    if ( client != nil ) {
        client.delegate = self;
        [client start];
    }
    NSLog(@"servername: %@", [client serverName]);
}

// Cleanup
- (void)dealloc {
    self.client = nil;
    [super dealloc];
}

- (IBAction) sendTime{
    [client setupTimer];
}

- (IBAction) resync{
    [client setupTimer];
}

- (IBAction) fixTime{
    [client fixTimer];
}

- (IBAction) addTime{
    [client addTime];
    [timeOffsetView updateTimeOffest:[client timeOffset]];
}

- (IBAction) removeTime{
    [client removeTime];
    [timeOffsetView updateTimeOffest:[client timeOffset]];
}

// User decided to close connection with the server
- (IBAction)exit {
    [client exit];
    [player stop];
    [player release];

    // Switch back to welcome view
    [[YouGoBlasterAppDelegate getInstance] showServerSelection];
}

#pragma mark -
#pragma mark ClientServerDelegate methods

// Room closed from outside
- (void)roomTerminated:(id)room reason:(NSString*)reason {
    // Explain what happened
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Client terminated" message:reason delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
    [self exit];
}

- (void)setPlayStatus:(bool)status{
    shouldPlay = status;
}

- (void)updateTimerDisplay:(double)theTime withDelta:(double)theDelta withRSQ:(double)theRSQ withStatus:(NSString*)theStatus{
    time.text = [NSString stringWithFormat:@"%f",theTime];
    delta.text = [NSString stringWithFormat:@"%f",theDelta];
    RSQ.text = [NSString stringWithFormat:@"%f",theRSQ];
    status.text = [NSString stringWithString:theStatus];
    if ((((int)theTime) %6) == 0 && (player.playing == 0) && (shouldPlay)){
        [player play];
    }
}

- (void)fetchChanges{
    serverLabel.text = [NSString stringWithFormat:@"Connected to: %@",[client serverName]];
    
    nowPlaying.text = [NSString stringWithFormat:@"Now Playing: %@",[client songTitle]];
}


#pragma mark -
#pragma mark AVAudioPlayerDelegate methods


@end
