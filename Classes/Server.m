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

#import "Server.h"
#import "Connection.h"
#import "ClientDevice.h"

struct SNTPPacket{
    double originate;
    double receive;
    double transmit;
};

// Private properties
@interface Server ()
@property(nonatomic,retain) ServerNetworking* serverNetworking;
@end

@implementation Server

@synthesize serverNetworking, delegate, clients;

// Initialization
- (id)init {
    clients = [[NSMutableArray alloc] initWithArray:nil];
    return self;
}


// Cleanup
- (void)dealloc {
    NSLog(@"dealloc'ing");
    [serverNetworking release];
    [super dealloc];
}


// Start the server and announce self
- (BOOL)start {
    // Create new instance of the server and start it up
    serverNetworking = [[ServerNetworking alloc] init];

    // We will be processing server events
    serverNetworking.delegate = self;

    // Try to start it up
    if ( ! [serverNetworking start] ) {
    self.serverNetworking = nil;
    return NO;
    }
    NSLog(@"started server");
    
    timeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timeUpdater) userInfo:nil repeats:YES];  
    
    [delegate setPlayStatus:true];
    
    return YES;
}

// Stop everything
- (void)stop {
    // Destroy serverNetworking
    [serverNetworking stop];
    self.serverNetworking = nil;
}

- (void)exit{
    /* when exiting, we want to send a message to the server to say we're going offline.
     * We need to allow for the message to be sent before closing, we do this by sending\
     * a message with the tag (15*[clients count]). When the last 
     * client's message is successfully sent (tag == 15), the connection then calls the close method.
     */
    [timeTimer invalidate];
    if ([clients count] > 0){
        int packetHeader = 3;
        NSMutableData* payload = [NSMutableData  dataWithBytes:&packetHeader length:sizeof(packetHeader)];
        for (ClientDevice *client in clients){
            NSLog(@"sending goodbye to %@:%hu with tag: %i",[client hostName],[client port],15*[clients count]);
            [[serverNetworking socket] sendData:payload toHost:[client hostName] port:[client port] withTimeout:-1 tag:15*[clients count]];
            NSUInteger index = [clients indexOfObject:client];
            [clients removeObject:client];            
            [[delegate clientList] deleteRowsAtIndexPaths:[NSArray arrayWithObject: [NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
        }
    }else{
        [self stop];
    }
}

- (void) timeUpdater{
    [delegate updateTimerDisplay:CFAbsoluteTimeGetCurrent() withDelta:0 withRSQ:0 withStatus:@"Blank"];
}

#pragma mark -
#pragma mark ServerDelegate Method Implementations

// Server has failed. Stop the world.
- (void) serverFailed:(ServerNetworking*)serverNetworking reason:(NSString*)reason {
  // Stop everything and let our delegate know
  [self stop];
  [delegate roomTerminated:self reason:reason];
}

// we received a timestamp packet from the server connection
- (void) receivedTimestampPacket:(NSMutableData*)packet fromHost:(NSString *)hostName port:(int)thePort {
    
    double currentTime = CFAbsoluteTimeGetCurrent();
    struct SNTPPacket myPacket;
    
    NSRange rangeToDelete = {0, sizeof(packet)};
    memcpy(&myPacket, [packet bytes], sizeof(myPacket));
    [packet replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
    
    myPacket.originate = myPacket.transmit;
    myPacket.receive = currentTime;
    myPacket.transmit = CFAbsoluteTimeGetCurrent();
    
    int packetHeader = 1;
    NSMutableData* outPacket = [[NSMutableData alloc] init];
    [outPacket appendBytes:&packetHeader length:sizeof(packetHeader)];
    [outPacket appendBytes:&myPacket length:sizeof(myPacket)];
    
    NSTimeInterval timeout = -1;
    [[serverNetworking socket] sendData:[outPacket autorelease] toHost:hostName port:thePort withTimeout:timeout tag:1];
    
    //NSLog(@"outgoing %f",CFAbsoluteTimeGetCurrent());
    //NSLog(@"data was returned %@", outPacket);
    
    [[serverNetworking socket] receiveWithTimeout:-1.0 tag:1];
    
}

// we received a control packet from the client connection
- (void) receivedControlPacket:(NSMutableData*)packet withControlSignal:(int)controlSignal fromHost:(NSString *)hostName port:(int)thePort {
    //NSLog(@"received control signal: %i",controlSignal);
    switch (controlSignal) {
        case 2:{
            // we received a "hello" from the client, we add the client to our list, and it would be polite to reply.
            
            ClientDevice* theClient = [[ClientDevice alloc] init];
            [theClient setHostName:hostName];
            [theClient setPort:thePort];
            [clients addObject:theClient];
            
            [[delegate clientList] insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.clients.count-1 inSection:0]] withRowAnimation: UITableViewRowAnimationTop];
            
            NSMutableDictionary* dictionaryToSend = [[NSMutableDictionary alloc] init];
            [dictionaryToSend setValue:[delegate songTitle] forKey:@"songTitle"];

            NSMutableData* packetToSend = [[NSMutableData alloc] initWithBytes:&controlSignal length:sizeof(controlSignal)] ;
            [packetToSend appendData:[NSKeyedArchiver archivedDataWithRootObject:dictionaryToSend]];
            [dictionaryToSend release];
            [[serverNetworking socket] sendData:[packetToSend autorelease] toHost:hostName port: thePort withTimeout:-1 tag:1];
        }
            break;
        case 3:{
            // we received a "goodbye" from the client;
            NSUInteger index = [clients indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {return ([[obj hostName] isEqualToString:hostName]);}];
            ClientDevice* theClient = [clients objectAtIndex:index];
            [clients removeObject:theClient];
            [theClient release];
            [[delegate clientList] deleteRowsAtIndexPaths:[NSArray arrayWithObject: [NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        }
            break;
        default:
            break;
    }
}

@end
