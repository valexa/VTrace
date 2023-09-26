//
//  main.m
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
	if(getenv("NSZombieEnabled")) {
		CLS_LOG(@"NSZombieEnabled enabled!!");
	}
	if(getenv("NSAutoreleaseFreedObjectCheckEnabled")) {
		CLS_LOG(@"NSAutoreleaseFreedObjectCheckEnabled enabled!!");
	}		
	if(getenv("NSTraceEvents")) {
		CLS_LOG(@"NSTraceEvents enabled!!");
	}		
	
    int retVal = UIApplicationMain(argc, argv, nil, @"VtraceAppDelegate");

    return retVal;
}
