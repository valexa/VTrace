//
//  IPController.h
//  VAinfo
//
//  Created by Vlad Alexa on 3/30/09.
//  Copyright 2009 __VladAlexa__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol IPControllerDelegate;

@interface IPController : NSObject {
	__unsafe_unretained id <IPControllerDelegate> delegate;
	NSMutableData *receivedData;
	NSURLConnection *theConnection;	
    NSString *url;	
}

@property (nonatomic, assign) id<IPControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableData *receivedData;
@property (nonatomic, retain) NSURLConnection *theConnection;
@property (nonatomic, retain) NSString *url;

- (id) initWithURL:(NSString *)theURL;

@end


@protocol IPControllerDelegate<NSObject>

@required
- (void) connectionDidFinish:(IPController *)theConnection;

@optional
- (void) connectionDidFail:(IPController *)theConnection;

@end