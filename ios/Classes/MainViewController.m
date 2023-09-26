//
//  MainViewController.m
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	[super viewDidLoad];
    
   [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"MainControllerEvent" object:nil];
    
    annotations = [NSMutableArray arrayWithCapacity:1];
    hostnames = [NSMutableDictionary dictionaryWithCapacity:1];
    
    flipsideController = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    flipsideController.delegate = self;
    flipsideController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	
	// make mapview	
	mapView=[[MKMapView alloc] initWithFrame:self.view.bounds];	
	[mapView.userLocation addObserver:self forKeyPath:@"location" options:NSKeyValueObservingOptionOld context:NULL];	
	mapView.showsUserLocation=NO;
	mapView.mapType=MKMapTypeStandard;
	mapView.delegate=self;
    mapView.camera.altitude *= 1.4;// increase the size of the region slightly is by using the camera property of the map view to zoom out
	[self.view addSubview:mapView];
	
	//and info button
	infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
	[infoButton setTitle:@"" forState:UIControlStateNormal];
	[infoButton addTarget:self action:@selector(showInfo) forControlEvents:UIControlEventTouchUpInside];		
	[self.view addSubview:infoButton];	
	
    defaults = [NSUserDefaults standardUserDefaults];
    
    [self performSelector:@selector(showInfo) withObject:nil afterDelay:1];
			
}


- (void)viewDidAppear:(BOOL)animated{
    
	[super viewDidAppear:YES];
    
	[self syncLayout];

}


// Subclasses override this method to define how the view they control will respond to device rotation 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    //IOS 6+ to override iphone default UIInterfaceOrientationMaskAllButUpsideDown
    return UIInterfaceOrientationMaskAll;
}

- (void)syncLayout
{

	[popOver dismissPopoverAnimated:NO];
    [mapView setFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height+20)];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        infoButton.frame = CGRectMake(self.view.bounds.size.width-60, 35, 40, 40);
    }else {
    	infoButton.frame = CGRectMake(self.view.bounds.size.width-40, 15, 40, 40);
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration{
    [self syncUI];
}

-(void)syncUI
{
	//resize base items
	[self syncLayout];
}

#pragma mark events

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"MainControllerEvent"]) {
		return;
	}
	if ([[notif object] isKindOfClass:[NSString class]])
    {
	}
	if ([[notif userInfo] isKindOfClass:[NSDictionary class]])
    {
        if ([[notif object] isEqualToString:@"resolvedHostname"])
        {
            NSString *ip = [[notif userInfo] objectForKey:@"address"];
            NSString *hostname = [[notif userInfo] objectForKey:@"name"];
            NSString *familyString = [[notif userInfo] objectForKey:@"familyString"];
            //in case we do not have this hop yet
            [hostnames setObject:hostname forKey:ip];
            //in case we have this hop already
            for (CustomPointAnnotation *ann in annotations) {
                if ([ann.title isEqualToString:ip])
                {
                    ann.hostname = hostname;
                    [flipsideController setHostname:hostname forIP:ip];
                }
            }
    [flipsideController.theTable reloadData];
        }
        if ([[notif object] isEqualToString:@"resolvedLocation"])
        {
            NSDictionary *hop = [[notif userInfo] objectForKey:@"dict"];
            if (![[hop objectForKey:@"thenote"] isEqualToString:@"-, -"])
            {
                [self performSelector:@selector(foundHop:) withObject:hop afterDelay:[[hop objectForKey:@"theid"] intValue]*1.5];
            }else{
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[[hop objectForKey:@"latitude"] floatValue] longitude:[[hop objectForKey:@"longitude"] floatValue]];
                CLGeocoder *reverseGeocoder = [[CLGeocoder alloc] init];
                [reverseGeocoder reverseGeocodeLocation:location completionHandler:^(NSArray* placemarks, NSError* error){
                    if ([placemarks count] > 0)             {
                        CLPlacemark *pmark = [placemarks objectAtIndex:0];
                        NSString *place = @"";
                        if (pmark.locality && pmark.country) {
                            place = [NSString stringWithFormat:@"%@, %@",pmark.locality,pmark.country];
                        }else if (pmark.administrativeArea && pmark.country){
                            place = [NSString stringWithFormat:@"%@, %@",pmark.administrativeArea,pmark.country];
                        }else if (pmark.thoroughfare && pmark.country){
                            place = [NSString stringWithFormat:@"Thoroughfare %@, %@",pmark.thoroughfare,pmark.country];
                        }else if (pmark.ISOcountryCode && pmark.country){
                            place = [NSString stringWithFormat:@"%@, %@",pmark.country,pmark.ISOcountryCode];
                        }else {
                            CLS_LOG(@"No location can be determined for %f %f",location.coordinate.latitude,location.coordinate.longitude);
                        }
                        [hop setValue:place forKey:@"thenote"];
                        [hop setValue:pmark.ISOcountryCode forKey:@"country"];
                        CLS_LOG(@"Geocoded %@",place);
                        [self performSelector:@selector(foundHop:) withObject:hop afterDelay:[[hop objectForKey:@"theid"] intValue]*1.5];
                    }else{
                        CLS_LOG(@"No placemarks found for %f %f %@",location.coordinate.latitude,location.coordinate.longitude,[error localizedDescription]);
                    }
                }];
                
            }
            
        }
    }
    
}


#pragma mark actions

- (void)popOver:(UIControl *)sender view:(id)view dict:(NSDictionary*)dict
{
	Class available = NSClassFromString(@"UIPopoverController");
	if (available && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
		[mapView deselectAnnotation:[[mapView selectedAnnotations] lastObject] animated:YES];		
		PopViewController *content = [[PopViewController alloc] initWithNibName:@"PopView" bundle:nil];
        content.dict = dict;
		popOver = [[UIPopoverController alloc] initWithContentViewController:content];
		popOver.delegate = self;
		[popOver setPopoverContentSize:CGSizeMake(300,460) animated:YES];
		CGRect rect = CGRectMake(-6,-6,sender.frame.size.width,sender.frame.size.height);
		[popOver presentPopoverFromRect:rect inView:view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}else {
		CLS_LOG(@"UIPopoverController not available");
	}
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller address:(NSString *)address family:(sa_family_t)family
{
	[self dismissModalViewControllerAnimated:YES];
	//refresh in case device was rotated while in info
	[self didRotateFromInterfaceOrientation:UIInterfaceOrientationPortrait];
	if (![address isEqualToString:@"null"])
    {
        [self startTrace:address family:family];
	}
}

- (void)showInfo{  
	if ([mapView isUserInteractionEnabled]){
		[self presentModalViewController:flipsideController animated:YES];
	}else {
		CLS_LOG(@"Mapview user interaction disabled, waiting 1 sec");
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(showInfo) userInfo:nil repeats:NO];				
	}
}

- (void)startTrace:(NSString*)address family:(sa_family_t)family
{

    NSString *familyString = IP_ADDR_IPv4;
    if (family == AF_INET6) {
        familyString = IP_ADDR_IPv6;
    }

    CLS_LOG(@"Starting trace for %@",address);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"TracerouteControllerEvent" object:@"startTrace" userInfo:@{@"address": address, @"familyString": familyString}];
    
    [annotations removeAllObjects];
    [hostnames removeAllObjects];
	[mapView removeAnnotations:[mapView annotations]];
    [mapView removeOverlays:[mapView overlays]];


}

#pragma mark MKMap

-(void)foundHop:(NSDictionary*)dict
{
    //postpone hops out of order until it's their time
    if ([[dict objectForKey:@"theid"] integerValue] != [annotations count]+1) {
        [self performSelector:@selector(foundHop:) withObject:dict afterDelay:2.5];
        return;
    }
    
    CustomPointAnnotation *previousAnn = [annotations lastObject];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([[dict objectForKey:@"latitude"] doubleValue],[[dict objectForKey:@"longitude"] doubleValue]) ;
    CustomPointAnnotation *ann = [self createMapAnnotationForCoordinate:coord andTitle:[dict objectForKey:@"thetitle"] andDict:dict];
    [annotations addObject:ann];
    [mapView addAnnotation:ann];
    [mapView showAnnotations:[mapView annotations] animated:NO];
    [mapView selectAnnotation:ann animated:YES];
    
    if (previousAnn) {
        CLLocationCoordinate2D points[2];
        points[0]=previousAnn.coordinate;
        points[1]=ann.coordinate;
        MKGeodesicPolyline* geoPolyLine = [MKGeodesicPolyline polylineWithCoordinates:points count:2];
        [mapView addOverlay:geoPolyLine];
    }
    
    if ([[dict objectForKey:@"thetitle"] isEqualToString:flipsideController.title])
    {
        //trace ended
        [flipsideController.traceButton setEnabled:YES];
        [flipsideController setTitle:@""];
    }
    
    [flipsideController.list addObject:dict];
    [flipsideController.theTable reloadData];
    [flipsideController setHostname:[hostnames objectForKey:[dict objectForKey:@"thetitle"]] forIP:[dict objectForKey:@"thetitle"]];
}

-(CustomPointAnnotation *)createMapAnnotationForCoordinate:(CLLocationCoordinate2D)coord andTitle:(NSString *)title andDict:(NSDictionary *)dict
{
    CustomPointAnnotation *annotation = [[CustomPointAnnotation alloc] init];
    annotation.coordinate = coord;
    annotation.title = title;
    annotation.note = [dict objectForKey:@"thenote"];
    annotation.ping = [dict objectForKey:@"theping"];
    annotation.country = [dict objectForKey:@"country"];
    annotation.hostname = [hostnames objectForKey:title];
    return annotation;
}

#pragma mark MKMapViewDelegate

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    NSUInteger index = [annotations indexOfObject:annotation]+1;
    CustomAnnotationView *view = [[CustomAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[NSString stringWithFormat:@"%lu",(unsigned long)index]];
    return view;
}

-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    MKPolylineRenderer *polylineRender = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    polylineRender.lineWidth = 2.0f;
    polylineRender.strokeColor = [UIColor blackColor];
    return polylineRender;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    if ([control isKindOfClass:[UIButton class]])
    {
        CustomPointAnnotation *ann = (CustomPointAnnotation*)[view annotation];
        NSString *theid = [NSString stringWithFormat:@"%ld",(unsigned long)[annotations indexOfObject:ann]+1] ;
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSString stringWithFormat:@"%f",ann.coordinate.latitude],@"longitude",
                               [NSString stringWithFormat:@"%f",ann.coordinate.latitude],@"latitude",
                               theid,@"theid",
                               ann.ping,@"theping",
                               ann.title,@"thetitle",
                               ann.note,@"thenote",
                               ann.hostname,@"thehostname",
                              nil];
        [self popOver:control view:view dict:dict];
    }
}

@end
