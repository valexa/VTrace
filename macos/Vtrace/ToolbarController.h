//
//  ToolbarController.h
//  Vtrace
//
//  Created by Vlad Alexa on 12/14/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

#import "CustomAnnotationView.h"
#import "CustomPointAnnotation.h"

#import "AddressResolver.h"

#import "VATableView.h"

@interface ToolbarController : NSObject <MKMapViewDelegate,NSTableViewDataSource,VATableViewDelegate,AddressResolverDelegate> {

    IBOutlet NSButton *shareButton;
    IBOutlet NSButton *listButton;
    IBOutlet NSButton *traceButton;
    IBOutlet NSTextField *inputField;
    IBOutlet NSSegmentedControl *mapType;
    IBOutlet MKMapView *mapView;
    IBOutlet NSTableView *tableView;
    IBOutlet NSPopover *listPopover;    
    IBOutlet NSView *popoverView;
    IBOutlet NSTextField *bottomText;
    IBOutlet NSLevelIndicator *bottomLevel;
    NSMutableArray *annotations;
    NSMutableDictionary *hostnames;
    AddressResolver *addressResolver;
	CFTimeInterval traceStartTime;
	CFTimeInterval resolveStartTime;
}

-(IBAction)sharePress:(id)sender;
-(IBAction)listPress:(id)sender;
-(IBAction)tracePress:(id)sender;
-(IBAction)typeChange:(id)sender;

@end
