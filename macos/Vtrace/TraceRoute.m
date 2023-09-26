//
//  TraceRoute.m
//  VTrace
//
//  Created by Vlad Alexa on 4/11/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "TraceRoute.h"
#import "AddressResolver.h"

@implementation TraceRoute

static void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef addr, const void *data, void *info)
// This C routine is called by CFSocket when there's data waiting on our 
// ICMP socket.  It just redirects the call to Objective-C code.
{
    TraceRoute *    obj;
    
    obj = (__bridge TraceRoute *) info;
    assert([obj isKindOfClass:[TraceRoute class]]);
    
#pragma unused(s)
    assert(s == obj->dsocket);
#pragma unused(type)
    assert(type == kCFSocketReadCallBack);
#pragma unused(addr)
    assert(addr == nil);
#pragma unused(data)
    assert(data == nil);
    
    [obj cocoaSocketReadCallback];
}

@synthesize ttl, address, sentAt, skipTimer, dsocket, delegate;

- (id)initWithAddress:(NSString *)ip andFamily:(sa_family_t)family
{
    self = [super init];
    if (self != nil) {
        CLS_LOG(@"%@", [TraceRoute currentIPAddresses]);
        self.address = ip;
        self.family = family;
        self.identifier = (uint16_t) arc4random();
		[self makeSocket];
		ttl = 1;
		[self sendPacket];			
    }
    return self;
}

- (void)dealloc
{
	//CLS_LOG(@"TraceRoute stoped");
    [self stop]; //takes care of _host and dsocket.
}

- (void)stop
{
    if (dsocket != NULL) {
        CFSocketInvalidate(dsocket);
        CFRelease(dsocket);
        dsocket = NULL;
		CLS_LOG(@"Stopped TraceRoute for %@",address);
    }
}

- (void)makeSocket
{
    int                     err;
    int                     fd;

    // Open the socket.

    fd = -1;
    err = 0;
    switch (self.family) {
        case AF_INET: {
            fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_ICMP);
            if (fd < 0) {
                err = errno;
            }
        } break;
        case AF_INET6: {
            fd = socket(AF_INET6, SOCK_DGRAM, IPPROTO_ICMPV6);
            if (fd < 0) {
                err = errno;
            }
        } break;
        default: {
            err = EPROTONOSUPPORT;
        } break;
    }

	if (fd != -1) {
        CFSocketContext     context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        CFRunLoopSourceRef  rls;
        
        // Wrap it in a CFSocket and schedule it on the runloop.        
        dsocket = CFSocketCreateWithNative(NULL, fd, kCFSocketReadCallBack, SocketReadCallback, &context);
        assert(dsocket != NULL);
        
        // The socket will now take care of clean up our file descriptor.        
        assert( CFSocketGetSocketFlags(dsocket) & kCFSocketCloseOnInvalidate );
        fd = -1;
        
        rls = CFSocketCreateRunLoopSource(NULL, dsocket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);        
        CFRelease(rls);		
		CLS_LOG(@"Started TraceRoute for %@",address);
        [VtraceAppDelegate logEventNamed:@"Started TraceRoute" parameters:@{@"address": address}];
    }else {
        [self didFinishWithStatus:[NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil]];
	}
    assert(fd == -1);
}

- (NSData *)tracePacketWithType:(uint8_t)type payload:(NSData *)payload {

    NSMutableData *         packet;
    ICMPHeader *            icmpPtr;

    packet = [NSMutableData dataWithLength:sizeof(*icmpPtr) + [payload length]];
    assert(packet != nil);

    icmpPtr = [packet mutableBytes];
    icmpPtr->type = 0;
    icmpPtr->code = 0;
    icmpPtr->checksum = 0;
    icmpPtr->identifier     = OSSwapHostToBigInt16(self.identifier);
    icmpPtr->sequenceNumber = OSSwapHostToBigInt16(ttl);
    memcpy(&icmpPtr[1], [payload bytes], [payload length]);

    switch (self.family) {
        case AF_INET: {
            icmpPtr->type = ICMPv4TypeEchoRequest;

            // The IP checksum returns a 16-bit number that's already in correct byte order
            // (due to wacky 1's complement maths), so we just put it into the packet as a
            // 16-bit unit.
            icmpPtr->checksum = in_cksum([packet bytes], [packet length]);
        } break;
        case AF_INET6: {
            icmpPtr->type = ICMPv6TypeEchoRequest;
        } break;
        default: {
            assert(NO);
        } break;
    }

    return packet;
}

- (void)sendPacket
{

    int             err;
    NSData *        payload;
    NSData *        packet;
    ssize_t         bytesSent;
  
    // Construct the packet.
	payload = [[NSString stringWithFormat:@"%28zd bottles of beer on the wall", (ssize_t) 99 - (size_t) (ttl % 100) ] dataUsingEncoding:NSASCIIStringEncoding];
	assert(payload != nil);        
	assert([payload length] == 56);

    packet = [self tracePacketWithType:ICMPv4TypeEchoRequest payload:payload];
    assert(packet != nil);

    //set the TTL
    switch (self.family) {
        case AF_INET: {
            err = setsockopt(CFSocketGetNative(dsocket), IPPROTO_IP, IP_MULTICAST_TTL, &ttl, sizeof(ttl));
        } break;
        case AF_INET6: {
            err = setsockopt(CFSocketGetNative(dsocket), IPPROTO_IPV6, IPV6_MULTICAST_HOPS, &ttl, sizeof(ttl));
        } break;
    }
	if (err == 0) {
		//CLS_LOG(@"Setting the TTL to %i",ttl);
	}else {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
		CLS_LOG(@"Error setting the TTL to %i ERR: %@",ttl, error);
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TracerouteControllerEvent" object:@"showError" userInfo:@{@"message": @"Error setting the TTL", @"error": error}];
	}

    // Send the packet.
    if (dsocket == NULL) {
        bytesSent = -1;
        err = EBADF;
    } else {
        CFSocketNativeHandle handle = CFSocketGetNative(dsocket);
        if (handle == -1) {
            CLS_LOG(@"Error getting native socket, invalid handle");
            err = errno;
        }
        NSData* sockaddrData = [AddressResolver sockaddrForAddress:address];
        bytesSent = sendto(handle,[packet bytes],[packet length], 0, [sockaddrData bytes], [sockaddrData length] );
        err = 0;
        if (bytesSent < 0) {
            err = errno;
        }
    }
	
    // Handle the results of the send.
    
    if ( (bytesSent > 0) && (((NSUInteger) bytesSent) == [packet length]) ) {
		//CLS_LOG(@"Sent %i bytes packet.",[packet length]);
		self.sentAt = [NSDate date];
		skipTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(skipHop) userInfo:nil repeats:NO];
    } else {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TracerouteControllerEvent" object:@"showError" userInfo:@{@"message": @"Failed to send packet", @"error": error}];
    }
    
}

#pragma mark external stuff

- (NSUInteger)icmpHeaderOffsetInPacket:(NSData *)packet
// Returns the offset of the ICMPHeader within an IP packet.
{
    NSUInteger              result;
    const struct IPv4Header  * ipPtr;
    size_t                  ipHeaderLength;
    
    result = NSNotFound;
    if ([packet length] >= (sizeof(IPv4Header ) + sizeof(ICMPHeader))) {
        ipPtr = (const IPv4Header *) [packet bytes];

        switch (self.family) {
            case AF_INET: {
                assert((ipPtr->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
            } break;
            case AF_INET6: {
                assert((ipPtr->versionAndHeaderLength & 0xF0) == 0x60);     // IPv6
            } break;
            default: {
                assert(NO);
            } break;
        }

        ipHeaderLength = (ipPtr->versionAndHeaderLength & 0x0F) * sizeof(uint32_t);
        if ([packet length] >= (ipHeaderLength + sizeof(ICMPHeader))) {
            result = ipHeaderLength;
        }
    }
    return result;
}

- (const struct ICMPHeader *)icmpInPacket:(NSData *)packet
{
    const struct ICMPHeader *   result;
    NSUInteger                  icmpHeaderOffset;
    
    result = nil;
    icmpHeaderOffset = [self icmpHeaderOffsetInPacket:packet];
    if (icmpHeaderOffset != NSNotFound) {
        result = (const struct ICMPHeader *) (((const uint8_t *)[packet bytes]) + icmpHeaderOffset);
    }
    return result;
}

- (const struct IPv4Header *)ipInPacket:(NSData *)packet
{
    const struct IPv4Header *result = nil;
    
	result = (const struct IPv4Header *) [packet bytes];

    switch (self.family) {
        case AF_INET: {
            assert((result->versionAndHeaderLength & 0xF0) == 0x40);     // IPv4
        } break;
        case AF_INET6: {
            assert((result->versionAndHeaderLength & 0xF0) == 0x60);     // IPv6
        } break;
        default: {
            assert(NO);
        } break;
    }
	
    return result;
}

+ (NSString*)humanizeIP:(uint8_t[4])ip{	
	return [NSString stringWithFormat:@"%d.%d.%d.%d",ip[0],ip[1],ip[2],ip[3]];
}

+ (NSMutableArray *)currentIPAddresses
{

    NSMutableArray *addresses = [NSMutableArray array];

    // retrieve the current interfaces - returns 0 on success
    struct ifaddrs *interfaces;
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        struct ifaddrs *interface;
        for(interface=interfaces; interface; interface=interface->ifa_next) {
            if(!(interface->ifa_flags & IFF_UP) ) {
                continue; // deeply nested code harder to read
            }
            const struct sockaddr_in *addr = (const struct sockaddr_in*)interface->ifa_addr;
            char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];
            if(addr && (addr->sin_family==AF_INET || addr->sin_family==AF_INET6)) {
                NSString *type;
                if(addr->sin_family == AF_INET) {
                    if(inet_ntop(AF_INET, &addr->sin_addr, addrBuf, INET_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv4;
                    }
                } else {
                    const struct sockaddr_in6 *addr6 = (const struct sockaddr_in6*)interface->ifa_addr;
                    if(inet_ntop(AF_INET6, &addr6->sin6_addr, addrBuf, INET6_ADDRSTRLEN)) {
                        type = IP_ADDR_IPv6;
                    }
                }
                if(type) {
                    [addresses addObject:@(addrBuf)];
                }
            }
        }
        // Free memory
        freeifaddrs(interfaces);
    }
    return addresses;
}

+ (NSData *)getHostAddress {
    Boolean     resolved;
    NSArray *   addresses;

    // Find the first appropriate address.

    addresses = (__bridge NSArray *) CFHostGetAddressing(CFHostCreateWithName(kCFAllocatorDefault, (__bridge CFStringRef) @"localhost"), &resolved);
        CLS_LOG(@"%@ addr", addresses);
    if ( resolved && (addresses != nil) ) {
        resolved = false;
        for (NSData * address in addresses) {
            const struct sockaddr * addrPtr;
            addrPtr = (const struct sockaddr *) address.bytes;
                    CLS_LOG(@"%@", addrPtr);
            if ( address.length >= sizeof(struct sockaddr) ) {
                switch (addrPtr->sa_family) {
                    case AF_INET: {
                        return address;
                    } break;
                    case AF_INET6: {
                        return address;
                    } break;
                    default: {
                        assert(NO);
                    } break;
                }
            }
            if (resolved) {
                break;
            }
        }
    }
    [VtraceAppDelegate logEventNamed:@"getHostAddress" parameters:@{@"error": @"no address"}];
    return  nil;

}

+ (sa_family_t)hostAddressFamily {
    sa_family_t     result;

    result = AF_UNSPEC;

    NSData *hostAddress = [TraceRoute getHostAddress];

    if ( (hostAddress != nil) && (hostAddress.length >= sizeof(struct sockaddr)) ) {
        result = ((const struct sockaddr *) hostAddress.bytes)->sa_family;
    }
    return result;
}

#pragma mark internal stuff

-(void)skipHop{

    if (skipCount < 3){
        skipCount++;
        CLS_LOG(@"Hop at %i timed out, skipping.",ttl);
        [self.delegate traceRoute:self didReceiveResponsePacket:[@"SKIP" dataUsingEncoding:NSUTF8StringEncoding] withDelay:0.0];
        ttl += 1;
        [self sendPacket];
    }else{
        skipCount = 0;
        //set this is as the last hop and stop
        [self.delegate traceRoute:self didReceiveResponsePacket:nil withDelay:0.0];
        [self.delegate traceRoute:self didFinishWithStatus:nil];
        //[self stop]; 	//sent on release
    }
}

- (void)didFinishWithStatus:(NSError *)error
// Shut down the pinger object and tell the delegate about the error.
{
    assert(error != nil);
    
    // We retain ourselves temporarily because it's common for the delegate method 
    // to release its last reference to use, which causes -dealloc to be called here. 
    // If we then reference self on the return path, things go badly.  I don't think 
    // that happens currently, but I've got into the habit of doing this as a 
    // defensive measure.
    
    //[[self retain] autorelease];
    
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(traceRoute:didFinishWithStatus:)] ) {
        [self.delegate traceRoute:self didFinishWithStatus:error];
		//[self stop]; //sent on release
    }
}

- (void)didGetPacket:(NSMutableData *)packet
{		
	//calculate ping
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:sentAt]*1000;
	
	//invalidate skip timer
	if (skipTimer) [skipTimer invalidate];

	//check if protocol = IP 
    const IPv4Header *ipPtr = [self ipInPacket:packet];
	CLS_LOG(@"versionAndHeaderLength=%i differentiatedServices=%i identification=%i protocol=%i sourceAddress=%@ destinationAddress=%@",ipPtr->versionAndHeaderLength,ipPtr->differentiatedServices,ipPtr->identification,ipPtr->protocol,[TraceRoute humanizeIP:(uint8_t*)ipPtr->sourceAddress],[TraceRoute humanizeIP:(uint8_t*)ipPtr->destinationAddress]);
	if ((int)ipPtr->protocol == 1) {
		//check if type = "Time to Live exceeded in Transit"
		const ICMPHeader *icmpPtr = [self icmpInPacket:packet];
		if ((unsigned int) icmpPtr->type == 11){
			CLS_LOG(@"got hop responding with Time to Live exceeded in Transit");
			[self.delegate traceRoute:self didReceiveResponsePacket:packet withDelay:interval];
			ttl += 1; 
			[self sendPacket];			
		}else if ([address isEqualToString:[TraceRoute humanizeIP:(uint8_t*)ipPtr->sourceAddress]]) {			
			CLS_LOG(@"got last hop");
			[self.delegate traceRoute:self didReceiveResponsePacket:packet withDelay:interval];
			[self.delegate traceRoute:self didFinishWithStatus:nil];
			//[self stop]; 	//sent on release
        } else {
            CLS_LOG(@"got hop responding with : %hhu",icmpPtr->type);
            [self.delegate traceRoute:self didReceiveResponsePacket:packet withDelay:interval];
            ttl += 1;
            [self sendPacket];
        }
	}
	
}

- (void)cocoaSocketReadCallback
// Called by the socket handling code (SocketReadCallback) to process an ICMP 
// messages waiting on the socket.
{
    int                     err;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    ssize_t                 bytesRead;
    void *                  buffer;
    enum { kBufferSize = 65535 };
	
    // 65535 is the maximum IP packet size, which seems like a reasonable bound 
    // here (plus it's what <x-man-page://8/ping> uses).
    
    buffer = malloc(kBufferSize);
    assert(buffer != NULL);
    
    // Actually read the data.
    
    addrLen = sizeof(addr);
    bytesRead = recvfrom(CFSocketGetNative(dsocket), buffer, kBufferSize, 0, (struct sockaddr *) &addr, &addrLen);
    err = 0;
    if (bytesRead < 0) {
        err = errno;
    }
    
    // Process the data we read.
    
    if (bytesRead > 0) {
        NSMutableData *packet = [NSMutableData dataWithBytes:buffer length:bytesRead];
        if (packet != nil){
            // We got some data		
            [self didGetPacket:packet];
        }else{
            CLS_LOG(@"cocoaSocketReadCallback ERROR nil packet");
        }
    } else {
		
        // We failed to read the data, so shut everything down.
        
        if (err == 0) {
            err = EPIPE;
        }
        [self didFinishWithStatus:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
    }
    
    free(buffer);
    
    // Note that we don't loop back trying to read more data.  Rather, we just 
    // let CFSocket call us again.
}


@end

