//
//  VtraceAppDelegate.h
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MainViewController;
@class TracerouteController;

@interface VtraceAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    MainViewController *controller;
    TracerouteController *traceroute;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) MainViewController *controller;

+ (void)logEventNamed:(NSString *)title parameters:(NSDictionary *)parameters;

@end

