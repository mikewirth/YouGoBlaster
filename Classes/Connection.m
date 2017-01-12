//
//  Connection.m
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
#import "Connection.h"

#define TAG_TME 15


// Private properties and methods
@interface Connection ()

// Properties
@property(nonatomic,assign) int port;
@property(nonatomic,assign) CFSocketNativeHandle connectedSocketHandle;
@property(nonatomic,retain) NSNetService* netService;

// Initialize
- (void)clean;

@end


@implementation Connection

@synthesize delegate;
@synthesize host, port;
@synthesize connectedSocketHandle;
@synthesize netService;


// Initialize, empty
- (void)clean {
    isConnected = NO;

    self.netService = nil;
    self.host = nil;
    connectedSocketHandle = -1;
    packetBodySize = -1;
}


// cleanup
- (void)dealloc {
    self.netService = nil;
    self.host = nil;
    self.delegate = nil;

    [super dealloc];
}


// Initialize and store connection information until 'connect' is called
- (id)initWithHostAddress:(NSString*)_host andPort:(int)_port {
    [self clean];
    //socket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    NSLog(@"Initialising with host %@ and port %d", _host, _port);
    
    self.host = _host;
    self.port = _port;
    return self;
}


// Initialize using a native socket handle, assuming connection is open
- (id)initWithNativeSocketHandle:(CFSocketNativeHandle)nativeSocketHandle {
    [self clean];
    //socket = [[AsyncUdpSocket alloc] initWithDelegate:self];
    self.connectedSocketHandle = nativeSocketHandle;
    return self;
}


// Initialize using an instance of NSNetService
- (id)initWithNetService:(NSNetService*)_netService {
    [self clean];
    // Has it been resolved?
    NSLog(@"Initialising with NSNetService %@ and host %@", [_netService name], [_netService hostName]);
    if ( _netService.hostName != nil ) {
        return [self initWithHostAddress:_netService.hostName andPort:_netService.port];
    }

    self.netService = _netService;
    return self;
}

// Connect using whatever connection info that was passed during initialization
- (BOOL)connect {
    NSLog(@"Connection trying to connect");
    NSLog(@"current host value: %@",self.host);
    if ( self.host != nil ) {

        socket = [[AsyncUdpSocket alloc] initWithDelegate:self];
        
        NSError *error = nil;
        if (![socket bindToPort:0 error:&error]) {
            NSLog(@"error starting server");
            return false;
        }
        
        isBound = TRUE;
        
        NSLog(@"Server started on port %d", [socket localPort]);
        
        NSTimeInterval timeout = -1.0;
        [socket receiveWithTimeout:timeout tag:1];
        
        [delegate connectedToServer];
        
        return YES;
    }
    else if ( netService != nil ) {
        // Start resolving
        netService.delegate = self;
        [netService resolveWithTimeout:5.0];
        return YES;
    }
    // Nothing was passed, connection is not possible
    return NO;
}

- (void)sendData:(NSMutableData *)data withTag:(int)tag{
    //NSLog(@"send data");
    if (!isBound) {
        NSLog(@"not connected, no data will be sent");
        return;
    }
    
    //Play with this
    NSTimeInterval timeout = 0.3;
    //NSLog(@"Sending to %@, port: %d, length: %u",self.host, self.port, [data length]);
    [socket sendData:data toHost:self.host port:self.port withTimeout:timeout tag:tag];
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

- (BOOL)onUdpSocket:(AsyncUdpSocket *)sock didReceiveData:(NSData *)data withTag:(long)tag fromHost:(NSString *)theHost port:(UInt16)thePort {

    int packetHeader;
    NSData* payload = [[NSMutableData alloc] initWithData:[data subdataWithRange:NSMakeRange(sizeof(packetHeader),[data length]-sizeof(packetHeader))]];
 
    
    [data getBytes:&packetHeader range:NSMakeRange(0,sizeof(packetHeader))];
    
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
    NSLog(@"connection socket closed.");
}


// Close connection
- (void)close {
    [socket close];

    // Stop net service?
    if ( netService != nil ) {
        [netService stop];
        self.netService = nil;
    }

    // Reset all other variables
    [self clean];
}


#pragma mark -
#pragma mark NSNetService Delegate Method Implementations

// Called if we weren't able to resolve net service
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
    if ( sender != netService ) {
        return;
    }

    // Close everything and tell delegate that we have failed
    NSLog(@"failed to setup Socket Streams 3");
    [delegate connectionAttemptFailed:self];
    [self close];
}


// Called when net service has been successfully resolved
- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    if ( sender != netService ) {
        return;
    }

    // Save connection info
    self.host = netService.hostName;
    self.port = netService.port;
    
    NSLog(@"Resolved %@, %d",self.host,self.port);
    
    // Don't need the service anymore
    self.netService = nil;

    // Connect!
    if ( ![self connect] ) {
        NSLog(@"failed to setup Socket Streams 4");
        [delegate connectionAttemptFailed:self];
        [self close];
    }
}

@end
