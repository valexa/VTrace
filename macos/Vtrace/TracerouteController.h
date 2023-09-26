//
//  TracerouteController.h
//  Vtrace
//
//  Created by Vlad Alexa on 12/15/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

#import "AddressResolver.h"
#import "IPController.h"
#import "TraceRoute.h"

@interface TracerouteController : NSObject <CLLocationManagerDelegate,AddressResolverDelegate,TraceRouteDelegate,IPControllerDelegate>
{
    IBOutlet NSButton *traceButton;
    IBOutlet NSPopover *consolePopover;
    IBOutlet NSTextView *consoleText;
    NSMutableDictionary *localTraceDict;
    CLLocationManager *locationManager;
    CLLocation *location;
}

@end
