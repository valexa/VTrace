//
//  TraceRoute.h
//  VTrace
//
//  Created by Vlad Alexa on 4/11/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CFNetwork/CFNetwork.h>
#include <AssertMacros.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#import "SimplePing.h"

@protocol TraceRouteDelegate;

@interface TraceRoute : NSObject {
	int						ttl;
	NSString				*address;
	NSDate					*sentAt;
	__unsafe_unretained NSTimer     *skipTimer;
    int                     skipCount;
    CFSocketRef             dsocket;	
    __unsafe_unretained id<TraceRouteDelegate>  delegate;
}

@property (nonatomic, assign, readwrite)  int ttl;
@property (nonatomic, copy, readwrite)  NSString *address;
@property                                sa_family_t family;
@property (nonatomic, copy, readwrite)  NSDate *sentAt;
@property (nonatomic, assign, readwrite)  NSTimer *skipTimer;
@property (nonatomic, assign, readwrite)  CFSocketRef dsocket;
@property (nonatomic, assign, readwrite) id<TraceRouteDelegate> delegate;
@property (nonatomic, assign, readwrite) uint16_t identifier;

- (id)initWithAddress:(NSString *)ip andFamily:(sa_family_t)family;
- (void)didFinishWithStatus:(NSError *)error;
- (void)didGetPacket:(NSMutableData *)packet;
- (void)cocoaSocketReadCallback;
- (void)makeSocket;
- (void)sendPacket;
- (void)stop;
- (const struct IPv4Header *)ipInPacket:(NSData *)packet;
- (const struct ICMPHeader *)icmpInPacket:(NSData *)packet;
- (NSUInteger)icmpHeaderOffsetInPacket:(NSData *)packet;
+ (NSString*)humanizeIP:(uint8_t[4])ip;
+ (NSData *)getHostAddress;
+ (NSMutableArray *)currentIPAddresses;
+ (sa_family_t)hostAddressFamily;

@end

@protocol TraceRouteDelegate <NSObject>

@required

- (void)traceRoute:(TraceRoute *)tracer didReceiveResponsePacket:(NSData *)packet withDelay:(NSTimeInterval)delay;
- (void)traceRoute:(TraceRoute *)tracer didFinishWithStatus:(NSError *)error;

@end

