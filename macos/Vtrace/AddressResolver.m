//
//  AddressResolver.m
//  VTrace
//
//  Created by Vlad Alexa on 4/12/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "AddressResolver.h"

static void HostResolveCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
{	
	AddressResolver *obj = (AddressResolver *)CFBridgingRelease(info);
	assert([obj isKindOfClass:[AddressResolver class]]);
		
    if ( (error != NULL) && (error->domain != 0) ) {
		NSError *nserr = [obj CFStreamErrorToNSError:*error];
        [VtraceAppDelegate logEventNamed:@"HostResolveCallback" parameters:@{@"error": nserr}];
		CLS_LOG(@"HostResolveCallback error %@",[nserr localizedDescription]);		
		if ([obj.delegate respondsToSelector:@selector(addressResolver:didFinishWithStatus:)] ) {
			[obj.delegate addressResolver:obj didFinishWithStatus:nserr];						
		}	
		//[obj stop];	//sent on release
    } else {
		if (([obj getIpv4] || [obj getIpv6]) && [obj getName]) {
			CLS_LOG(@"Resolved %@ %@",obj.name,obj.ip);

			if ([obj.delegate respondsToSelector:@selector(addressResolver:didFinishWithStatus:)] ) {
				[obj.delegate addressResolver:obj didFinishWithStatus:nil];
			}			
		}else{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TracerouteControllerEvent" object:@"showError" userInfo:@{@"message": @"HostResolveCallback resolution succesfull but getIp/getName failed"}];
		}
		//[obj stop];	//sent on release
    }
}

@implementation AddressResolver

@synthesize address,host,name,ip,delegate;

- (id)initWithAddress:(NSString *)theAddress
{
    self = [super init];
    if (self != nil) {
		self.address = theAddress;
		
		Boolean             success;
		CFHostClientContext context = {0, CFBridgingRetain(self), NULL, NULL, NULL};
		CFStreamError       streamError;
		CFHostInfoType		type;
		
		//create the host
		if ([self isIp:address])
        {
            NSData* sockaddrData = [AddressResolver sockaddrForAddress:address];
			host = CFHostCreateWithAddress(kCFAllocatorDefault, (__bridge CFDataRef)sockaddrData);
     		type = kCFHostNames;
		}else {
			host = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)CFBridgingRetain(address));
     		type = kCFHostAddresses;			
		}
		if (host == NULL) CLS_LOG(@"Resolving host null for (%@)",address);		
		
		//squedule async resolution
		CFHostSetClient(host, HostResolveCallback, &context);		
		CFHostScheduleWithRunLoop(host,CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);		
		success = CFHostStartInfoResolution(host,type, &streamError);
		if (!success) CLS_LOG(@"Error starting resolution for (%@)",address);
    }
    return self;
}

- (void) dealloc
{
	//CLS_LOG(@"AddressResolver stoped");
    [self stop];
}

-(BOOL) getIpv4
{
	
    Boolean     resolved;
    NSArray *   addresses;
    
    // Get the first IPv4 ip    
    addresses = (NSArray *) CFBridgingRelease(CFHostGetAddressing(host, &resolved));
    if ( resolved && (addresses != nil) ) {
        resolved = false;
        for (NSData * addr in addresses) {
            const struct sockaddr_in *addrPtr = (const struct sockaddr_in *) [addr bytes];
            if ( [addr length] >= sizeof(struct sockaddr_in) && addrPtr->sin_family == AF_INET) {
                NSString *theIp = [NSString stringWithCString:inet_ntoa((struct in_addr)addrPtr->sin_addr) encoding:NSUTF8StringEncoding];
                self.ip = theIp;
                self.family = AF_INET;
                resolved = true;
                break;
            }
        }
    }	
	
	if (resolved) {
        //CLS_LOG(@"Resolved ip");
    } else {
        CLS_LOG(@"Error resolving IPv4 ip");
    }
	return resolved;
}

-(BOOL) getIpv6
{

    Boolean     resolved;
    NSArray *   addresses;
    char addrBuf[ MAX(INET_ADDRSTRLEN, INET6_ADDRSTRLEN) ];

    // Get the first IPv6 ip
    addresses = (NSArray *) CFBridgingRelease(CFHostGetAddressing(host, &resolved));
    if ( resolved && (addresses != nil) ) {
        resolved = false;
        for (NSData * addr in addresses) {
            const struct sockaddr_in6 *addrPtr = (const struct sockaddr_in6 *) [addr bytes];
            if ( [addr length] >= sizeof(struct sockaddr_in6) && addrPtr->sin6_family == AF_INET6) {
                inet_ntop(AF_INET6, &addrPtr->sin6_addr, addrBuf, INET6_ADDRSTRLEN);
                NSString *theIp = [NSString stringWithCString:addrBuf encoding:NSUTF8StringEncoding];
                self.ip = theIp;
                self.family = AF_INET6;
                resolved = true;
                break;
            }
        }
    }

    if (resolved) {
        //CLS_LOG(@"Resolved ip");
    } else {
        CLS_LOG(@"Error resolving IPv6 ip");
    }
    return resolved;
}

-(BOOL) getName 
{	
    Boolean     resolved;
    NSArray *   addresses;
    
    // Get the first FQDN name    
    addresses = (NSArray *) CFBridgingRelease(CFHostGetNames(host, &resolved));
    if ( resolved && (addresses != nil) ) {
        resolved = false;
        for (id addr in addresses) {
			self.name = (NSString *)addr;
			resolved = true;
			break;
        }
    }	
	
	if (resolved) {
        //CLS_LOG(@"Resolved name");
    } else {
        CLS_LOG(@"Error resolving name");
        [VtraceAppDelegate logEventNamed:@"ErrorResolvingName" parameters:@{@"address": address}];
    }
	return resolved;	
}

-(BOOL) isIp:(NSString*)string
{
	struct in_addr pin;
	int success = inet_aton([string UTF8String],&pin);
	if (success == 1) return YES;
	return NO;
}

+(void) ptonTest:(NSString*)string
{
    int success;
    if ([string rangeOfString:@":"].location != NSNotFound) {
        struct in6_addr addr;
        success = inet_pton(AF_INET6, [string UTF8String], &addr);
    } else if ([string rangeOfString:@"."].location != NSNotFound) {
        struct in_addr addr;
        success = inet_pton(AF_INET, [string UTF8String], &addr);
    } else {
        assert(NO);
    }

    if (success == 0) {
        NSString *error = @"The address was not parseable in the specified address family";
        CLS_LOG(@"%@", error);
        [VtraceAppDelegate logEventNamed:@"CreatingAddressErr" parameters:@{@"error": error}];
    } else if (success == -1) {
        NSError *error = [NSError errorWithDomain:NSPOSIXErrorDomain code:errno userInfo:nil];
        CLS_LOG(@"Creating address system error : %@",error);
        [VtraceAppDelegate logEventNamed:@"CreatingAddressErr" parameters:@{@"error": error}];
    }
}

/*! Returns the string representation of the supplied address.
 *  \param address Contains a (struct sockaddr) with the address to render.
 *  \returns A string representation of that address.
 */

+ (NSString *) displayAddressForAddress:(NSData *) address {
    int         err;
    NSString *  result;
    char        hostStr[NI_MAXHOST];

    result = nil;

    if (address != nil) {
        err = getnameinfo(address.bytes, (socklen_t) address.length, hostStr, sizeof(hostStr), NULL, 0, NI_NUMERICHOST);
        if (err == 0) {
            result = @(hostStr);
        } else {
            CLS_LOG(@"displayAddressForAddress error");
            [VtraceAppDelegate logEventNamed:@"displayAddressForAddress" parameters:@{@"error": @"nil"}];
        }
    }

    if (result == nil) {
        result = @"?";
    }

    return result;
}

/*! Returns a (struct sockaddr) for the address to render.
 */

+ (NSData *) sockaddrForAddress:(NSString *) address {

    const char* addr = [address UTF8String];

    int         err;
    NSData *result = nil;

    struct addrinfo *res0, *res;

    err = getaddrinfo (addr, NULL, NULL, &res0);
    if (err == 0) {
        for (res = res0; res; res = res->ai_next) {
            result = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
            CLS_LOG(@"sockaddrForAddress: %@",[AddressResolver stringFromSockaddr:result]);
        }
        freeaddrinfo (res0);
    } else if (err == EAI_NONAME) {
        [VtraceAppDelegate logEventNamed:@"sockaddrForAddress" parameters:@{@"error": @"EAI_NONAME"}];
    } else {
        [VtraceAppDelegate logEventNamed:@"sockaddrForAddress" parameters:@{@"error": @"nil"}];
    }

    if (result == nil) {
        result = [@"?" dataUsingEncoding:NSUTF8StringEncoding];
    }

    return result;
}

+ (NSString *) stringFromSockaddr:(NSData *) data {
    return [AddressResolver displayAddressForAddress:data];
    //return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSError*) CFStreamErrorToNSError:(CFStreamError)streamError
{
    NSDictionary *  userInfo;
    NSError *       error;
	
    if (streamError.domain == kCFStreamErrorDomainNetDB) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey,
					nil
					];
    } else {
        userInfo = nil;
    }
    error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:userInfo];
    assert(error != nil);
	
    return error;
}

- (void) stop
{
    if (host != NULL) {
        CFHostSetClient(host, NULL, NULL);
        CFHostUnscheduleFromRunLoop(host, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        host = NULL;
    }
}

@end
