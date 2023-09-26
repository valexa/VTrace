//
//  VtraceAppDelegate.m
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "VtraceAppDelegate.h"

#import "MainViewController.h"

#import "TracerouteController.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@import Firebase;

@implementation VtraceAppDelegate

@synthesize window, controller;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

#ifdef DEBUG
       CLS_LOG(@"DEBUG Launched");
#endif

    [FIRApp configure];
    [Fabric with:@[[Crashlytics class]]];
	
    // Override point for customization after application launch	
	window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height)];
	controller = [[MainViewController alloc] init];
    self.window.rootViewController = self.controller;    
	//bug with 320x480
	controller.view.frame = [UIScreen mainScreen].applicationFrame;		
	[window addSubview:[controller view]];	
	[window makeKeyAndVisible];		
    
    //alloc trace
    traceroute = [[TracerouteController alloc] init];
	
	return YES;	
	
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
    //[controller showInfo];
	//CLS_LOG(@"Foregrounded");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */   
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}

+ (void)logEventNamed:(NSString *)title parameters:(NSDictionary *)parameters {
    NSString *eventName = [title stringByReplacingOccurrencesOfString:@" " withString:@""];
    if ([eventName length] >= 30) {
        eventName = [eventName substringToIndex:10];
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:parameters];
    dict[@"device"] = [UIDevice currentDevice].name;
    if ([parameters[@"error"] isMemberOfClass:[NSError class]]){
        NSError *error = parameters[@"error"];
        [CrashlyticsKit recordError:error];
        dict[@"error"] = error.localizedDescription;
        CLS_LOG(@"LOG EVENT: %@ %@", title, error.localizedDescription);
    } else {
        CLS_LOG(@"LOG EVENT: %@ %@", title, parameters.description);
    }
    [FIRAnalytics logEventWithName:eventName parameters:dict];
}

@end
