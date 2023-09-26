//
//  IPController.m
//  VAinfo
//
//  Created by Vlad Alexa on 3/30/09.
//  Copyright 2009 __VladAlexa__. All rights reserved.
//

#import "IPController.h"


@implementation IPController

@synthesize delegate,receivedData,theConnection,url;


- (id) initWithURL:(NSString*)theURL
{
    self = [super init];
	if (self) {		
		self.url = [theURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
		NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];        
		receivedData = [[NSMutableData alloc] initWithLength:0];	
		/* Create the connection with the request and start loading the data. The connection object is owned both by the creator and the loading system. */
		NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self startImmediately:YES];
		if (conn == nil){
			CLS_LOG(@"The NSURLConnection could not be made!...");
		}else {		
			//show network activity
		}
		self.theConnection = conn;
	}
	return self;
}


#pragma mark NSURLConnection delegate methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    /* This method is called when the server has determined that it has
	 enough information to create the NSURLResponse. It can be called
	 multiple times, for example in the case of a redirect, so each time
	 we reset the data. */
    [self.receivedData setLength:0];
	
}


- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    /* Append the new data to the received data. */
    [self.receivedData appendData:data];		
}


- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	CLS_LOG(@"UrlConnection failed (%@)",[error localizedDescription]);	    
    if ( (self.delegate != nil) && [self.delegate respondsToSelector:@selector(connectionDidFail:)] ) {	
		[self.delegate connectionDidFail:self];			
	}
    //hide network activity

}


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self.delegate connectionDidFinish:self];
    //hide network activity

}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
				   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	/* this application does not use a NSURLCache disk or memory cache */
    return nil;
}


- (void)dealloc
{
	//CLS_LOG(@"IPController stoped");
    [theConnection cancel];
}



@end
