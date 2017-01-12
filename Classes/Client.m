//
//  Client.m
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

#import "Client.h"
#import "TimeTuple.h"

struct SNTPPacket{
    double originate;
    double receive;
    double transmit;
};

int timeCount = 10;
int resyncCount = 0;
NSString* status = @"Syncing";

double timeDelta = 0;
int RTTave = 1000;
double rSquared = 0;


// Private properties
@interface Client ()
@property(nonatomic,retain) Connection* connection;
@property(nonatomic,retain) NSString* serverName;
@end


@implementation Client

@synthesize connection, serverName, delegate, songTitle, timeTuples, timeOffset;

// Setup connection but don't connect yet
- (id)initWithHost:(NSString*)host andPort:(int)port {
    connection = [[Connection alloc] initWithHostAddress:host andPort:port];
    return self;
}


// Initialize and connect to a net service
- (id)initWithNetService:(NSNetService*)netService {
    connection = [[Connection alloc] initWithNetService:netService];
    return self;
}


// Cleanup
- (void)dealloc {
    [timeTuples dealloc];
    self.connection = nil;
    [super dealloc];
}


// Start everything up, connect to server
- (BOOL)start {
    if ( connection == nil ) {
        return NO;
    }
  
    timeOffset = 0;
        
    timeTuples = [[NSMutableArray alloc] init];
    songTitle = [[NSString alloc] initWithString:@"Acquiring..."];
    
    // We are the delegate
    connection.delegate = self;
    timeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timeUpdater) userInfo:nil repeats:YES];  
    NSLog(@"telling connection to connect");
    return [connection connect];
}


// Stop everything, disconnect from server
- (void)stop {    
    if ( connection == nil ) {
        return;
    }
    [timeTimer invalidate];
    [connection close];
    self.connection = nil;
}

- (void)exit{
    /* when exiting, we want to send a message to the server to say we're going offline.
     * We need to allow for the message to be sent before closing, we do this by sending\
     * a message with the tag 15. The connection then calls the close method when the
     * message with tag 15 was sent.
     */
    int packetHeader = 3;
    NSMutableData* payload = [NSMutableData  dataWithBytes:&packetHeader length:sizeof(packetHeader)];
    [connection sendData:payload withTag:15];
    NSLog(@"queued up payload");
}

- (void) timeUpdater{
    [delegate updateTimerDisplay:CFAbsoluteTimeGetCurrent()+timeDelta+copysign(timeOffset,timeDelta) withDelta:timeDelta+copysign(timeOffset,timeDelta) withRSQ:timeOffset withStatus:status];
}

- (void)sendHello{
    int packetHeader = 2;
    NSMutableData* payload = [NSMutableData  dataWithBytes:&packetHeader length:sizeof(packetHeader)];
    [connection sendData:payload withTag:1];
}


- (void)broadcastCurrentTime{
    int thisTime = timeCount--;
    //NSLog(@"sending packet: %i",(11-thisTime));
    struct SNTPPacket myPacket;
    myPacket.transmit = CFAbsoluteTimeGetCurrent();
    myPacket.originate = 0;
    myPacket.receive = 0;
    
    int packetHeader = 1;
    // Create network packet to be sent to all clients
    NSMutableData* packet = [[NSMutableData alloc] init];
    [packet appendBytes:&packetHeader length:sizeof(packetHeader)];
    [packet appendBytes:&myPacket length:sizeof(myPacket)];
    
    //NSLog(@"client sending packet contents: %@",packet);
    
    // Send it out
    [connection sendData:[packet autorelease] withTag:1];
    if (thisTime == 1){
        [myTimer invalidate];
        myTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(calculateTime) userInfo:nil repeats:NO];
        timeCount = 10;
    }
}

- (void)setupTimer{
    myTimer = [NSTimer scheduledTimerWithTimeInterval:.001 target:self selector:@selector(broadcastCurrentTime) userInfo:nil repeats:YES];
}

- (void)stopTimer{
    if ([myTimer isValid]) {[myTimer invalidate];}
}

- (void)calculateRegression{
    double xave = 0, yave = 0, xisquare = 0, xiyisquare = 0, n=8;
    for (int i=0;i<n;i++){
        //NSLog(@"x %f, y %f",timeTuples[i][0],timeTuples[i][1]);
        /*xave += timeTuples[i][0];
        yave += timeTuples[i][1];
        xisquare += (timeTuples[i][0] * timeTuples[i][0]);
        xiyisquare += (timeTuples[i][1] * timeTuples[i][0]);*/
    }
    xave = xave / n;
    yave = yave / n;
    //NSLog(@"xav %f, yav %f, xisquare %f, yisquare %f",xave, yave, xisquare, xiyisquare);
    double a = ((yave*xisquare) - (xave*xiyisquare))/((xisquare) - (n*xave*xave));
    double b = (xiyisquare - n*xave*yave)/(xisquare-n*xave*xave);
    NSLog(@"b: %f",b);
    double ssxx = 0;
    double ssyy = 0;
    double ssxy = 0;
    for (int i=0;i<n;i++){
        /*double tmp = (timeTuples[i][0] - xave);
        ssxx += tmp * tmp;
        tmp = (timeTuples[i][1] - yave);
        ssyy += tmp * tmp;
        ssxy += (timeTuples[i][1] - yave)*(timeTuples[i][0] - xave);*/
    }
    double rsq = (ssxy*ssxy)/(ssxx*ssyy);
    if (rsq > rSquared){
        rSquared = rsq;
        timeDelta = a;
    }
    /*timeDeltas[bufferPosition % BUFFERSIZE] = a;
    bufferPosition++;
    if (bufferPosition > 9){
        [myTimer invalidate];
        myTimer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(setupTimer) userInfo:nil repeats:YES];
    }*/
    NSLog(@"brSquared: %f",rsq);
    NSLog(@"delta: %f",timeDelta);
    double temp = 0;
    int count = 0;
    /*for (int i=0;i<BUFFERSIZE;i++){
        if (timeDeltas[i]){
            temp += timeDeltas[i];
            count ++;
            NSLog(@"time %d, %f",i,timeDeltas[i]);
        }
    }*/
    timeDelta = temp / count;
}

- (void) useLowestTime{
    timeDelta = [[[timeTuples sortedArrayUsingSelector:@selector(compareRTT:)] objectAtIndex:0] actualTime];
}

- (void) averageBufferTime{
    timeDelta = 0;
    RTTave = 0;
    for (TimeTuple *timeTuple in timeTuples){
        timeDelta += [timeTuple actualTime];
        RTTave += (int)([timeTuple RTTTime]*1000);
    }
    timeDelta = timeDelta/[timeTuples count];
    RTTave = RTTave/[timeTuples count];
    NSLog(@"timeDelta, RTTave: %f, %d",timeDelta,RTTave);
}

- (void) useLowestTimes:(int)manyTimes{
    // iterate over the top x items;
    manyTimes = MIN(manyTimes, [timeTuples count]);
    timeDelta = 0;
    RTTave = 0;
    for (TimeTuple *timeTuple in [[timeTuples sortedArrayUsingSelector:@selector(compareRTT:)] subarrayWithRange: NSMakeRange(0,manyTimes)]){
        timeDelta += [timeTuple actualTime];
        RTTave += (int)([timeTuple RTTTime]*1000);
    }
    timeDelta = timeDelta/manyTimes;
    RTTave = RTTave/manyTimes;
    NSLog(@"timeDelta, RTTave: %f, %d",timeDelta,RTTave);
}

- (void) calculateTime{
    // the math
    [self useLowestTimes:5];
    // the logic
    bool flag = false;
    switch(RTTave/10){
        case 0: {
                status = [NSString stringWithString:@"Excellent"];
                flag = true;
            }
            break;
        case 1: {
                status = [NSString stringWithString:@"Very Good"];
                flag = true;
            }
            break;
        case 2: {
                status = [NSString stringWithString:@"Good"];
                flag = true;
            }
            break;
        case 3: {
                status = [NSString stringWithString:@"Adequate"];
                if (resyncCount < 1){
                    flag = false;
                }else{
                    flag = true;
                }
            }
            break;
        case 4: {
                status = [NSString stringWithString:@"Poor"];
                if (resyncCount < 2){
                    flag = false;
                }else{
                    flag = true;
                }
            }
            break;
        case 5: {
                status = [NSString stringWithString:@"Very Poor"];
                if (resyncCount < 3){
                    flag = false;
                }else{
                    flag = true;
                }
            }
            break;
        default:{
                status = [NSString stringWithString:@"Unusable"];
                if (resyncCount < 4){
                    flag = false;
                }else{
                    flag = true;
                }
        }
    }
    if (flag){
        [delegate setPlayStatus:true];
        [[delegate resyncButton] setEnabled:YES];
    }else{
        resyncCount++;
        NSLog(@"resyncCount, %i",resyncCount);
        myTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(setupTimer) userInfo:nil repeats:NO];
        timeCount = 10;
        [[delegate resyncButton] setEnabled:NO];
    }
    [delegate fetchChanges];
}

- (void) addTime{
    timeOffset += 0.005;    
}

- (void) removeTime{
    timeOffset -= 0.005;
}

#pragma mark -
#pragma mark ConnectionDelegate Method Implementations

- (void)connectionAttemptFailed:(Connection*)connection {
    [delegate roomTerminated:self reason:@"Wasn't able to connect to server"];
}


- (void)receivedTimestampPacket:(NSMutableData*)packet fromHost:(NSString *)host port:(int)port {
    struct SNTPPacket myPacket;

    [packet getBytes:&myPacket range:NSMakeRange(0,[packet length])];
    
    NSRange rangeToDelete = {0, sizeof(packet)};
    [packet replaceBytesInRange:rangeToDelete withBytes:NULL length:0];
    if (myPacket.originate == 0){ //the packet isn't coming back to us from the server
    }else{ //this packet has useful info for us.
        double currentTime = CFAbsoluteTimeGetCurrent();
        double RTT = currentTime - myPacket.originate;
        double t = ((myPacket.receive-myPacket.originate)+(myPacket.transmit-currentTime))/2;
        
        TimeTuple* time = [TimeTuple alloc];
        [time setRTTTime:RTT];
        [time setActualTime:t];
        
        [timeTuples addObject:[time autorelease]];
    }
}

- (void) receivedControlPacket:(NSData *)controlPacket withControlSignal:(int)controlSignal fromHost:(NSString *)hostName port:(int)thePort{
    
    switch (controlSignal){
        case 2:{
            // we received a response to our "hello"
            NSDictionary* receivedData = [NSKeyedUnarchiver unarchiveObjectWithData:controlPacket];
            songTitle = [[receivedData valueForKey:@"songTitle"] retain];
        }
            break;
            
        case 3:{
            // the server is telling us it's going offline
            [delegate exit];
        }
            break;
        
    }
    [delegate fetchChanges];
}

- (void) connectedToServer{
    serverName = [connection host];
    [self sendHello];
    [delegate fetchChanges];
    [self setupTimer];
}

@end
