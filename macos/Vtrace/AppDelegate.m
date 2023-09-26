//
//  AppDelegate.m
//  Vtrace
//
//  Created by Vlad Alexa on 12/13/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application

    [NSUserDefaults standardUserDefaults] registerDefaults:@{ @"NSApplicationCrashOnExceptions": @YES }];
   
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

- (IBAction) openWebsite:(id)sender
{
	NSURL *url = [NSURL URLWithString:@"https://getsatisfaction.com/vladalexa/products/vladalexa_vtrace"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}



@end


