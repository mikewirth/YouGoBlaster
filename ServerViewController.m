//
//  ServerViewController.m
//  YouGoBlaster
//
//  Created by James Guthrie on 7/6/11.
//  Copyright 2011 ETH. All rights reserved.
//

#import "ServerViewController.h"
#import "YouGoBlasterAppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>


@implementation ServerViewController

@synthesize server, player, clientList, songTitle;

bool shouldPlayMusic = 1;

// After view shows up, start the server
- (void) activate{
    
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
        NSLog(@"Error initializing audio session! %d", result);
    
    [[AVAudioSession sharedInstance] setDelegate: self];
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
    if (setCategoryError)
        NSLog(@"Error setting category! %d", setCategoryError);
    
    float aBufferLength = 0.005; // In seconds
    AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(aBufferLength), &aBufferLength);
    
    //result = AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange, RouteChangeListener, self);
    if (result) 
        NSLog(@"Could not add property listener! %d", result);
    [fileURL release];
    if ( server != nil ) {
        server.delegate = self;
        NSLog(@"starting server");
        [server start];
    }
    //server.text = [server serverName];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

// Cleanup
- (void)dealloc {
    self.server = nil;
    [super dealloc];
}


- (void) displayMediaPicker {
#if TARGET_IPHONE_SIMULATOR
    // simulator code
#else
    //device code
    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    picker.delegate						= self;
    picker.allowsPickingMultipleItems	= NO;
    //picker.prompt						= NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    [self presentModalViewController: picker animated: YES];
    [picker release];
#endif
}

- (void)updateTimerDisplay:(double)theTime withDelta:(double)theDelta withRSQ:(double)theRSQ withStatus:status{
    time.text = [NSString stringWithFormat:@"%f",theTime];
    delta.text = [NSString stringWithFormat:@"%f",theDelta];
    RSQ.text = [NSString stringWithFormat:@"%f",theRSQ];
    //status.text = [NSString stringWithString:theStatus];
    if ((((int)theTime) %6) == 0 && (player.playing == 0) && (shouldPlayMusic)){
        [player play];
        //[self view].backgroundColor = [UIColor blackColor];
    }else{
        //[player stop];
        //[self view].backgroundColor = [UIColor whiteColor];
    }
}

// Server closed from outside
- (void)roomTerminated:(id)room reason:(NSString*)reason {
    // Explain what happened
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Server terminated" message:reason delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
    [self exit];
}

- (void)setPlayStatus:(bool)status{
    shouldPlayMusic = status;
}

- (IBAction) selectSong{

    MPMediaPickerController *picker = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeMusic];
    
    picker.delegate						= self;
    picker.allowsPickingMultipleItems	= NO;
    //picker.prompt						= NSLocalizedString (@"Add songs to play", "Prompt in media item picker");
    
    // The media item picker uses the default UI style, so it needs a default-style
    //		status bar to match it visually
    [[UIApplication sharedApplication] setStatusBarStyle: UIStatusBarStyleDefault animated: YES];
    
    [self presentModalViewController: picker animated: YES];
    [picker release];
}

// User decided to stop the server
- (IBAction)exit {
    // Close the server
    [server exit];
    [player stop];
    [player release];
    
    // Switch back to welcome view
    [[YouGoBlasterAppDelegate getInstance] showServerSelection];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate methods

#pragma mark
#pragma mark MediaPickerDelegate methods

// Media picker delegate methods
- (void)mediaPicker: (MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    // We need to dismiss the picker
    [self dismissModalViewControllerAnimated:YES];
    
    if ([mediaItemCollection count])
    {
        songTitle = [[NSMutableString alloc] initWithString:[[[mediaItemCollection items] objectAtIndex:0] valueForProperty:MPMediaItemPropertyArtist]];
        [songTitle appendString:@" - "];
        [songTitle appendString:[[[mediaItemCollection items] objectAtIndex:0] valueForProperty:MPMediaItemPropertyTitle]];
        
        status.text = songTitle;
    }
    //server sendControlMessage:
    
    // Assign the selected item(s) to the music player and start playback.
    /*[self.musicPlayer stop];
    [self.musicPlayer setQueueWithItemCollection:mediaItemCollection];
    [self.musicPlayer play];*/
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    // User did not select anything
    // We need to dismiss the picker
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark UITableView Delegate methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// There is only one section.
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[server clients] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    static NSString *MyIdentifier = @"MyIdentifier";
    
    // Try to retrieve from the table view a now-unused cell with the given identifier.
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    
    // If no cell is available, create a new one using the given identifier.
    if (cell == nil) {
        // Use the default cell style.
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
    }
        
  if ([[server clients] count]){      
        // Set up the cell.
        cell.textLabel.text = [[[server clients] objectAtIndex:indexPath.row] hostName];
    }else{
        cell.textLabel.text = @"No connections";
    }
	
	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.backgroundColor = [[UIColor alloc] initWithRed:241.0 / 255 green:241.0 / 255 blue:241.0 / 255 alpha:1.0];
}

/*
 To conform to Human Interface Guildelines, since selecting a row would have no effect (such as navigation), make sure that rows cannot be selected.
 */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}


@end
