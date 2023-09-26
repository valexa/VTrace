//
//  AppDelegate.h
//  Vtrace
//
//  Created by Vlad Alexa on 12/13/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <MapKit/MapKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction) openWebsite:(id)sender;

@end

