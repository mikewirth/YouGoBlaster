//
//  YouGoBlasterViewController.m
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

#import "YouGoBlasterViewController.h"
#import "YouGoBlasterAppDelegate.h"
#import "Server.h"
#import "Client.h"


// Private properties
@interface YouGoBlasterViewController ()
@property(nonatomic,retain) ServerBrowser* serverBrowser;
@end


@implementation YouGoBlasterViewController

@synthesize serverBrowser;

// View loaded
- (void)viewDidLoad {
  serverBrowser = [[ServerBrowser alloc] init];
  serverBrowser.delegate = self;
}


// Cleanup
- (void)dealloc {
  self.serverBrowser = nil;
  [super dealloc];
}


// View became active, start your engines
- (void)activate {
  // Start browsing for services
  [serverBrowser start];
}


// User is asking to create new server
- (IBAction)startServer:(id)sender {
    // Stop browsing for servers
    [serverBrowser stop];

    Server* server = [[[Server alloc] init] autorelease];
    [[YouGoBlasterAppDelegate getInstance] showServer:server];
}


// User is asking to join an existing server
- (IBAction)joinServer:(id)sender {
  // Figure out which server is selected
  NSIndexPath* currentRow = [serverList indexPathForSelectedRow];
  if ( currentRow == nil ) {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Which server?" message:@"Please select a server from the list above" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
    [alert release];
    return;
  }

  NSNetService* selectedServer = [serverBrowser.servers objectAtIndex:currentRow.row];
  // Create client that will connect to the server
  Client* client = [[[Client alloc] initWithNetService:selectedServer] autorelease];
  // Stop browsing and switch over to client view
  [serverBrowser stop];
  [[YouGoBlasterAppDelegate getInstance] showClient:client];
}


#pragma mark -
#pragma mark ServerBrowserDelegate Method Implementations

- (void)updateServerList {
  [serverList reloadData];
}


#pragma mark -
#pragma mark UITableViewDataSource Method Implementations

// Number of rows in each section. One section by default.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [serverBrowser.servers count];
}


// Table view is requesting a cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* serverListIdentifier = @"serverListIdentifier";

    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:serverListIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:serverListIdentifier] autorelease];
    }

    // Set cell's text to server's name
    NSNetService* server = [serverBrowser.servers objectAtIndex:indexPath.row];
    [cell.textLabel setText:[server name]];
  
  return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return nil;
}


@end
