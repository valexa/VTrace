//
//  TracerouteController.m
//  Vtrace
//
//  Created by Vlad Alexa on 12/15/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import "TracerouteController.h"

@implementation TracerouteController

- (id)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"TracerouteControllerEvent" object:nil];
        
        localTraceDict = [NSMutableDictionary dictionaryWithCapacity:1];
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        [locationManager startUpdatingLocation];
        
    }
    return self;
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"TracerouteControllerEvent"]) {
		return;
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {

	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]])
    {
        if ([[notif object] isEqualToString:@"startTrace"])
        {
            address = [[notif userInfo] objectForKey:@"address"];

            sa_family_t family = AF_INET;
            if ([[[notif userInfo] objectForKey:@"familyString"] isEqualToString:IP_ADDR_IPv6]){
                family = AF_INET6;
            }

            TraceRoute *traceRoute = [[TraceRoute alloc] initWithAddress:address andFamily:family];
            traceRoute.delegate = self;
            
            [localTraceDict removeAllObjects];

            [locationManager requestWhenInUseAuthorization];
            
            [locationManager startUpdatingLocation];
            
            [self performSelector:@selector(locationCheck) withObject:nil afterDelay:5];
            
        }
        if ([[notif object] isEqualToString:@"showError"])
        {
            NSString *message = [[notif userInfo] objectForKey:@"message"];
            NSError *error = (NSError*) [[notif userInfo] objectForKey:@"error"];
            //CLS_LOG(@"%@ ERR: %@",message, error.description);
            UIAlertView *sendAlert = [[UIAlertView alloc] initWithTitle:message message:error.localizedDescription  delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [sendAlert show];
            NSDictionary *parameters = @{@"message": message, @"error": error, @"address": address};
            [VtraceAppDelegate logEventNamed:message parameters:parameters];
        }
    }
    
}

-(void)locationCheck
{
    if (location == nil)
    {
        UIAlertView *sendAlert = [[UIAlertView alloc] initWithTitle:@"You did not permit location access" message:@"Location access is required to determine the starting location" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [sendAlert show];
    }
}

#pragma mark CLLocationManager delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLS_LOG(@"Location: %@", [newLocation description]);
    location = newLocation;
    [manager stopUpdatingLocation];
}

#pragma mark TraceRoute delegate


- (void)traceRoute:(TraceRoute *)tracer didReceiveResponsePacket:(NSData *)packet withDelay:(NSTimeInterval)delay
{
	if (packet)
    {
        if ([packet isEqualToData:[@"SKIP" dataUsingEncoding:NSUTF8StringEncoding]])
        {
            //hop did not respond, we use the data from last hop for it
            NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[localTraceDict objectForKey:[NSString stringWithFormat:@"%i",tracer.ttl-1]]];
            [dict setObject:[NSString stringWithFormat:@"%i",tracer.ttl] forKey:@"theid"];
            [dict setObject:@"0.0.0.0" forKey:@"thetitle"];
            [dict setObject:@"0.0" forKey:@"theping"];
            //save trace
            [localTraceDict setObject:dict forKey:[dict objectForKey:@"theid"]];
            [NSTimer scheduledTimerWithTimeInterval:tracer.ttl*1.5 target:self selector:@selector(locateIP:) userInfo:[dict objectForKey:@"thetitle"] repeats:NO];
        }else{
            //we have a responding hop
            const IPv4Header *ipPtr = [tracer ipInPacket:packet];
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                   [NSString stringWithFormat:@"%i",tracer.ttl],@"theid",
                   [TraceRoute humanizeIP:(uint8_t*)ipPtr->sourceAddress],@"thetitle",
                   [NSString stringWithFormat:@"%f",delay],@"theping",
                   nil];
            //save trace
            [localTraceDict setObject:dict forKey:[dict objectForKey:@"theid"]];
            //resolve location
            [NSTimer scheduledTimerWithTimeInterval:tracer.ttl*1.5 target:self selector:@selector(locateIP:) userInfo:[dict objectForKey:@"thetitle"] repeats:NO];
        }
	}else{
        //hop did not respond, we assume this is our target
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[localTraceDict objectForKey:[NSString stringWithFormat:@"%i",tracer.ttl-1]]];
        if (dict != nil) {
            [dict setObject:[NSString stringWithFormat:@"%i",tracer.ttl] forKey:@"theid"];
            [dict setObject:tracer.address forKey:@"thetitle"];
            //save trace
            [localTraceDict setObject:dict forKey:[dict objectForKey:@"theid"]];
            //resolve location
            [NSTimer scheduledTimerWithTimeInterval:tracer.ttl*1.5 target:self selector:@selector(locateIP:) userInfo:[dict objectForKey:@"thetitle"] repeats:NO];
        }else {
            UIAlertView *sendAlert = [[UIAlertView alloc] initWithTitle:@"Did not get a response for the sent packets" message:@"Routing policies on your network might be filtering packets, try on a different one if possible" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [sendAlert show];
            [VtraceAppDelegate logEventNamed:@"Filtering packets" parameters:@{@"address": address}];
        }
	}
}

- (void)traceRoute:(TraceRoute *)tracer didFinishWithStatus:(NSError *)error
{
	CLS_LOG(@"TraceRoute finished.");
	if (error){
		CFShow((__bridge CFTypeRef)(error));
	}
}

#pragma mark AddressResolver delegate

- (void)resolveIP:(NSTimer*)sender
{
	NSString *ip = (NSString *)[sender userInfo];
	AddressResolver *resolver = [[AddressResolver alloc] initWithAddress:ip];
    resolver.delegate = self;
	CLS_LOG(@"Added %@ to hostname resolve queue",ip);
}

- (void)addressResolver:(AddressResolver *)resolver didFinishWithStatus:(NSError *)error
{
	if (error == nil)
    {

        NSString *familyString = IP_ADDR_IPv4;
        if (resolver.family == AF_INET6) {
            familyString = IP_ADDR_IPv6;
        }

        [CrashlyticsKit setUserIdentifier:resolver.address];
        [CrashlyticsKit setUserName:resolver.name];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"MainControllerEvent" object:@"resolvedHostname" userInfo:@{@"name": resolver.name, @"address": resolver.address, @"familyString": familyString}];
	}else{
		CLS_LOG(@"Failed to resolve %@",resolver.address);
	}
    //end network activity
}

#pragma mark IPController callback

- (void) locateIP:(NSTimer*)sender
{
	NSString *ip = (NSString *)[sender userInfo];
    NSString *url;
    if ([ip length] > 100) {
        url = ip; //from retry
        //ip = [[ip componentsSeparatedByString:@"ip="] lastObject];
    }else{
        NSString *apikey =  @"7aab000be328d5a62ef2f794f98ae8bdefd7c290734ae912802c407c12468c05";
        url = [NSString stringWithFormat:@"https://api.ipinfodb.com/v3/ip-city/?key=%@&timezone=false&format=xml&ip=%@",apikey,ip];
    }

	IPController *cont = [[IPController alloc] initWithURL:url];
    cont.delegate = self;
}

- (void) connectionDidFinish:(IPController *)conn
{
	NSMutableDictionary *tags = [NSMutableDictionary dictionaryWithCapacity:1];
	NSString *str = [[NSString alloc] initWithData:conn.receivedData encoding:NSUTF8StringEncoding];
	if ([str rangeOfString:@"<statusCode>OK</statusCode>"].location == NSNotFound)
    {
        //if (![consolePopover isShown]) [consolePopover showRelativeToRect:traceButton.frame ofView:traceButton preferredEdge:NSMinYEdge];
        //[consoleText insertText:[NSString stringWithFormat:@"%@ Error from location api:%@\n",[NSDate date],str]];
        //[consoleText insertText:[NSString stringWithFormat:@"%@ Retrying in 15 sec\n",[NSDate date]]];
        [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(locateIP:) userInfo:conn.url repeats:NO];
	}else{
        //[consolePopover close];
        NSArray *lines = [str componentsSeparatedByString:@"\n"];
        [tags setObject:[self xmlParse:[self stringWithTag:@"ipAddress" arr:lines] tag:@"ipAddress"] forKey:@"thetitle"];
        [tags setObject:[self xmlParse:[self stringWithTag:@"countryCode" arr:lines] tag:@"countryCode"] forKey:@"country"];
        [tags setObject:[self xmlParse:[self stringWithTag:@"countryName" arr:lines] tag:@"countryName"] forKey:@"thenote"];
        [tags setObject:[NSString stringWithFormat:@"%@, %@",[self xmlParse:[self stringWithTag:@"cityName" arr:lines] tag:@"cityName"],[tags objectForKey:@"thenote"]] forKey:@"thenote"];
        [tags setObject:[self xmlParse:[self stringWithTag:@"latitude" arr:lines] tag:@"latitude"] forKey:@"latitude"];
        [tags setObject:[self xmlParse:[self stringWithTag:@"longitude" arr:lines] tag:@"longitude"] forKey:@"longitude"];
        //CLS_LOG(@"Got %i data bytes containing %i tags",[conn.receivedData length],[tags count]);
        //add ping and the hop number
        for (NSString *theid in localTraceDict)
        {
            NSDictionary *dict = [localTraceDict objectForKey:theid];
            if ([[dict objectForKey:@"thetitle"] isEqualToString:[tags objectForKey:@"thetitle"]]) {
                [tags setObject:[dict objectForKey:@"theid"] forKey:@"theid"];
                [tags setObject:[dict objectForKey:@"theping"] forKey:@"theping"];
            }
        }
        //make sure coords aint 0
        if ([[tags valueForKey:@"latitude"] intValue] == 0)
        {
            [tags setObject:[NSString stringWithFormat:@"%f",location.coordinate.latitude] forKey:@"latitude"];
            [tags setObject:[NSString stringWithFormat:@"%f",location.coordinate.longitude] forKey:@"longitude"];
            CLS_LOG(@"Fixing %@ to %f %f ",[tags valueForKey:@"thetitle"],location.coordinate.latitude,location.coordinate.longitude);
        }
        //make sure ip is not 0.0.0.0
        if ([[tags valueForKey:@"thetitle"] isEqualToString:@"0.0.0.0"])
        {
            NSString *localAddr = [TraceRoute currentIPAddresses][3];
            CLS_LOG(@"Fixing %@ to %@ ",[tags valueForKey:@"thetitle"],localAddr);
            [tags setObject:localAddr forKey:@"thetitle"];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MainControllerEvent" object:@"resolvedLocation" userInfo:@{@"dict": tags}];
        CLS_LOG(@"Added %@ to infodb locate queue",[tags valueForKey:@"thetitle"]);
        [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(resolveIP:) userInfo:[tags valueForKey:@"thetitle"] repeats:NO];
    }
}

-(void)connectionDidFail:(IPController *)conn
{
    //if (![consolePopover isShown]) [consolePopover showRelativeToRect:traceButton.frame ofView:traceButton preferredEdge:NSMinYEdge];
    //[consoleText insertText:[NSString stringWithFormat:@"%@ Connection failed to location api\n",[NSDate date]]];
    //[consoleText insertText:[NSString stringWithFormat:@"%@ Retrying in 15 sec\n",[NSDate date]]];
    [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(locateIP:) userInfo:conn.url repeats:NO];
}

-(NSString*)stringWithTag:(NSString*)str arr:(NSArray *)arr
{
	NSString *tag = [NSString stringWithFormat:@"</%@>",str];
	for (NSString *s in arr) {
		if ([s rangeOfString:tag].location != NSNotFound){
			return s;
		}
	}
	return @"";
}

- (NSString *)xmlParse:(NSString *)line tag:(NSString *)tag
{
	line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSUInteger loc = [tag length]+2;
	NSUInteger len = [line length]-(loc*2)-1;
	NSString *ret = @" ";
	if (loc+len <= [line length]) {
		if (len > 0) {
			ret = [line substringWithRange:NSMakeRange(loc,len)];
			//CLS_LOG(@"Parsed tag (%i) from [%@] to [%@]",loc,line,ret);
		}else {
			//CLS_LOG(@"Length %i is less than 1 for (%@)",len,line);
		}
	}else {
        //CLS_LOG(@"Location %i with len %i exceeds bounds %i for (%@)",loc,len,[line length],line);
	}
	return ret;
}


@end
