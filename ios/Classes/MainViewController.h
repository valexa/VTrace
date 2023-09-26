//
//  MainViewController.h
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved. 
//

#import <iAd/iAd.h>

#import <MapKit/MapKit.h>

#import "CustomAnnotationView.h"
#import "CustomPointAnnotation.h"

#import "FlipsideViewController.h"
#import "PopViewController.h"


@interface MainViewController : UIViewController <FlipsideViewControllerDelegate,MKMapViewDelegate,UIPopoverControllerDelegate> {

    NSMutableArray *annotations;
    NSMutableDictionary *hostnames;

    NSUserDefaults *defaults;
    
	MKMapView *mapView;
	UIButton *infoButton;
    
	UIPopoverController* popOver;
    FlipsideViewController *flipsideController;
}

- (void)popOver:(UIControl *)sender view:(id)view dict:(NSDictionary*)dict;
- (void) showInfo;
- (void) startTrace:(NSString*)address family:(sa_family_t)family;

@end
