//
//  YouGoBlasterAppDelegate.m
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

#import <QuartzCore/QuartzCore.h>
#import "YouGoBlasterAppDelegate.h"
#import "YouGoBlasterViewController.h"
#import "ClientViewController.h"
#import "ServerViewController.h"

static YouGoBlasterAppDelegate* _instance;

@implementation YouGoBlasterAppDelegate

@synthesize window;
@synthesize viewController;
@synthesize clientViewController;
@synthesize serverViewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    // Allow other classes to use us
    _instance = self;
    
    // Override point for customization after app launch
    [window addSubview: [clientViewController view]];
    [window addSubview: [viewController view]];
    [window addSubview: [serverViewController view]];
    [window makeKeyAndVisible];
    
    // Greet user
    [self showServerSelection];
}


- (void)dealloc {
    [viewController release];
    [clientViewController release];
    [serverViewController release];
    [window release];
    [super dealloc];
}


+ (YouGoBlasterAppDelegate*)getInstance {
  return _instance;
}


// Show client
- (void)showClient:(Client*)client {
    clientViewController.client = client;

    [clientViewController activate];
    
    CATransition *transition = [CATransition animation];
	transition.duration = 0.5;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
    [window.layer addAnimation:transition forKey:nil];

    [window bringSubviewToFront: [clientViewController view]];
}

- (void)showServer:(Server*)server {
    serverViewController.server = server;
    
    [serverViewController activate];
    
    CATransition *transition = [CATransition animation];
	transition.duration = 0.5;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	[window.layer addAnimation:transition forKey:nil];
    
    [window bringSubviewToFront: [serverViewController view]];
    [serverViewController displayMediaPicker];
}


// Show screen with server selection
- (void)showServerSelection {
    [viewController activate];

    CATransition *transition = [CATransition animation];
	transition.duration = 0.5;
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type = kCATransitionFade;
	[window.layer addAnimation:transition forKey:nil];
    
    [window bringSubviewToFront:viewController.view];
}


@end
