//
//  Server.m
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


#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <CFNetwork/CFSocketStream.h>

#import "ServerNetworking.h"
#import "AppConfig.h"

// Declare some private properties and methods
@interface ServerNetworking ()
@property(nonatomic,assign) uint16_t port;
@property(nonatomic,retain) NSNetService* netService;


- (BOOL)createServer;
- (void)terminateServer;

- (BOOL)publishService;
- (void)unpublishService;
@end


// Implementation of the Server interface
@implementation ServerNetworking

@synthesize delegate;
@synthesize port, netService, socket;

// Cleanup
- (void)dealloc {
  self.netService = nil;
  self.delegate = nil;
  [super dealloc];
}


// Create server and announce it
- (BOOL)start {
  // Start the socket server
  if ( ! [self createServer] ) {
    return NO;
  }
  
  // Announce the server via Bonjour
  if ( ! [self publishService] ) {
    [self terminateServer];
    return NO;
  }
  
  return YES;
}


// Close everything
- (void)stop {
  [self terminateServer];
  [self unpublishService];
}


#pragma mark Callbacks

#pragma mark Sockets and streams

- (BOOL)createServer {
    socket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    port = 0;
    
    NSError *error = nil;
    if (![socket bindToPort:port error:&error]) {
        NSLog(@"error starting server");
        return false;
    }
    
    isBound = TRUE;
    
    NSLog(@"Server started on port %d", [socket localPort]);
    self.port = [socket localPort];
    
    NSTimeInterval timeout = -1.0;
    [socket receiveWithTimeout:timeout tag:1];
    
    return true;
}


- (void) terminateServer {
    [self unpublishService];
    [socket close];
}


#pragma mark Bonjour

- (BOOL) publishService {
    // come up with a name for our music server
    NSString* musicServerName = [NSString stringWithFormat:@"%@'s music server", [[UIDevice currentDevice] name]];

    // create new instance of netService
 	self.netService = [[NSNetService alloc] initWithDomain:@"" type:@"_yougoblaster._udp." name:musicServerName port:self.port];
	if (self.netService == nil)
		return NO;

    // Add service to current run loop
	[self.netService scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

    // NetService will let us know about what's happening via delegate methods
    [self.netService setDelegate:self];
  
    // Publish the service
	[self.netService publish];
      
    return YES;
}


- (void) unpublishService {
    if ( self.netService ) {
        [self.netService stop];
        [self.netService removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        self.netService = nil;
    }
}


#pragma mark -
#pragma mark NSNetService Delegate Method Implementations

// Delegate method, called by NSNetService in case service publishing fails for whatever reason
- (void)netService:(NSNetService*)sender didNotPublish:(NSDictionary*)errorDict {
    if ( sender != self.netService ) {
        return;
    }

    // Stop socket server
    [self terminateServer];

    // Stop Bonjour
    [self unpublishService];

    // Let delegate know about failure
    [delegate serverFailed:self reason:@"Failed to publish service via Bonjour (duplicate server name?)"];
}


/* Delegate methods */

- (void)onUdpSocket:(AsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    if (tag == 15){
        [delegate stop];
    }
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"Error: Data wasn't sent.");
}

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)theHost port:(UInt16)thePort{
    //NSLog(@"incoming %f",CFAbsoluteTimeGetCurrent());
    int packetHeader;
    NSData* payload = [[NSMutableData alloc] initWithData:[data subdataWithRange:NSMakeRange(sizeof(packetHeader),[data length]-sizeof(packetHeader))]];
    //NSLog(@"received payload length: %u",[payload length]);
    
    [data getBytes:&packetHeader range:NSMakeRange(0,sizeof(packetHeader))];
    //NSLog(@"received packetHeader: %i",packetHeader);
    switch (packetHeader){
        case 1:{[delegate receivedTimestampPacket:[payload autorelease] fromHost:theHost port:thePort];}
            break;
        case 2:    
        case 3:{[delegate receivedControlPacket:[payload autorelease] withControlSignal:packetHeader fromHost:theHost port:thePort];}
            break;
        default:
            [payload release];
    }        

    [socket receiveWithTimeout:-1.0 tag:1];
    
    return TRUE;
}

- (void)onUdpSocket:(AsyncUdpSocket *)sock didNotReceiveDataWithTag:(long)tag dueToError:(NSError *)error {
    NSLog(@"Error while receiving data.");
}

- (void)onUdpSocketDidClose:(AsyncUdpSocket *)sock {
    //NSLog(@"Socket closed.");
    //[socket release];
}


@end
