//
//  ToolbarController.m
//  Vtrace
//
//  Created by Vlad Alexa on 12/14/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import "ToolbarController.h"

@implementation ToolbarController

- (id)init
{
    self = [super init];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(theEvent:) name:@"ToolbarControllerEvent" object:nil];

    }
    return self;
}

-(void)theEvent:(NSNotification*)notif
{
	if (![[notif name] isEqualToString:@"ToolbarControllerEvent"]) {
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
            //in case we do not have this hop yet
            [hostnames setObject:hostname forKey:ip];
            //in case we have this hop already
            for (CustomPointAnnotation *ann in annotations) {
                if ([ann.title isEqualToString:ip])
                {
                    ann.hostname = hostname;
                }
            }
            [tableView reloadData];

        }
        if ([[notif object] isEqualToString:@"newHop"])
        {
            NSInteger count = [[[notif userInfo] objectForKey:@"dict"] count];
            [bottomLevel setHidden:NO];
            [bottomLevel setMaxValue:count];
            resolveStartTime = CFAbsoluteTimeGetCurrent();
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
                             NSLog(@"No location can be determined for %f %f",location.coordinate.latitude,location.coordinate.longitude);
                         }
                         [hop setValue:place forKey:@"thenote"];
                         [hop setValue:pmark.ISOcountryCode forKey:@"country"];
                         NSLog(@"Geocoded %@",place);
                         [self performSelector:@selector(foundHop:) withObject:hop afterDelay:[[hop objectForKey:@"theid"] intValue]*1.5];
                     }else{
                         NSLog(@"No placemarks found for %f %f %@",location.coordinate.latitude,location.coordinate.longitude,[error localizedDescription]);
                     }
                 }];
                
            }
            
        }
    }
    
}

-(void)awakeFromNib
{
    
    [mapView setShowsCompass:YES];
    [mapView setShowsZoomControls:YES];
	[mapView setShowsUserLocation:NO];
    mapView.camera.altitude *= 1.4;// increase the size of the region slightly is by using the camera property of the map view to zoom out
    
    annotations = [NSMutableArray arrayWithCapacity:1];
    hostnames = [NSMutableDictionary dictionaryWithCapacity:1];
    [listButton setHidden:YES];
    [shareButton setHidden:YES];

}

#pragma mark share

-(void)showShareButton
{
    if (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_8) {
        NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
        if ([service canPerformWithItems:nil]) {
            [shareButton setHidden:NO];
        }else{
            [shareButton setHidden:YES];
        }
    }
}

-(CGFloat)pixelScaling
{
    NSView *view = [[NSApp mainWindow] contentView];
    NSRect pixelBounds = [view convertRectToBacking:view.bounds];
    return pixelBounds.size.width/view.bounds.size.width;
}

-(NSImage*)imageFromView:(NSView *)view
{
    BOOL hidden = [view isHidden];
    [view setHidden:NO];
    NSBitmapImageRep *bir = [view bitmapImageRepForCachingDisplayInRect:[view bounds]];
    [bir setSize:view.bounds.size];
    [view cacheDisplayInRect:[view bounds] toBitmapImageRep:bir];
    [view setHidden:hidden];
    NSImage* image = [[NSImage alloc] initWithSize:view.bounds.size];
    [image addRepresentation:bir];
    
    return image;
}


-(IBAction)sharePress:(id)sender
{
    NSView *view = [[NSApp mainWindow] contentView];
    NSImage *img = [self imageFromView:view];
    CGFloat scale = [self pixelScaling];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [img lockFocus];
    NSImage *icon = [NSImage imageNamed:@"AppIcon"];
    [icon setSize:CGSizeMake(32/scale, 32/scale)];
    [icon drawAtPoint:NSMakePoint(4, 6) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
    NSString *str = [NSString stringWithFormat:@"Vtrace %@",[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Neue" size:13.0],NSFontAttributeName, nil];
    [str drawAtPoint:NSMakePoint(38, 21) withAttributes:attrsDictionary];
    [@"vladalexa.com/apps/osx/vtrace" drawAtPoint:NSMakePoint(38, 6) withAttributes:attrsDictionary];
    [img unlockFocus];
    NSSharingService *service = [NSSharingService sharingServiceNamed:NSSharingServiceNamePostOnTwitter];
    NSArray *shareItems = [NSArray arrayWithObjects:[inputField stringValue],img, nil];
    [service performWithItems:shareItems];
	//NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:[img TIFFRepresentation]];
	//NSData *imgdata = [rep representationUsingType:NSPNGFileType properties:nil];
    //[imgdata writeToFile:[@"~/desktop/v.png" stringByExpandingTildeInPath] atomically:YES];
}

#pragma mark actions

-(IBAction)listPress:(id)sender
{
    if ([listPopover isShown]) {
        [listPopover close];
    }else{
        [listPopover showRelativeToRect:listButton.frame ofView:listButton preferredEdge:NSMinYEdge];        
    }
}

-(IBAction)typeChange:(id)sender
{
    if ([mapType selectedSegment] == 0) [mapView setMapType:MKMapTypeStandard];
    if ([mapType selectedSegment] == 1) [mapView setMapType:MKMapTypeHybrid];
    if ([mapType selectedSegment] == 2) [mapView setMapType:MKMapTypeSatellite];
}

-(IBAction)tracePress:(id)sender
{
    
    [listButton setHidden:YES];
    [shareButton setHidden:YES];
    [traceButton setEnabled:NO];
    [bottomText setHidden:YES];
    [bottomLevel setMaxValue:0];
    
    addressResolver = [[AddressResolver alloc] initWithAddress:inputField.stringValue];
    addressResolver.delegate = self;
    
    [annotations removeAllObjects];
    [hostnames removeAllObjects];
	[mapView removeAnnotations:[mapView annotations]];
    [mapView removeOverlays:[mapView overlays]];
    [listPopover close];
    [tableView reloadData];
    
    NSLog(@"Starting trace for %@",inputField.stringValue);
	traceStartTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark AddressResolver delegate

- (void)addressResolver:(AddressResolver *)resolver didFinishWithStatus:(NSError *)error
{
	if (error == nil)
    {
        [traceButton setToolTip:resolver.ip];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"TracerouteControllerEvent" object:@"startTrace" userInfo:@{@"address": resolver.ip}];
        addressResolver = nil; // let ARC free it
	}else {
        [traceButton setEnabled:YES];        
        [[NSAlert alertWithMessageText:@"IP or hostname is invalid" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Only IPv4 addresses with working reverse dns are supported or hostnames with working dns"] beginSheetModalForWindow:[NSApp mainWindow] modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
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
    
    [listButton setHidden:NO];
    [self showShareButton];
    [listButton setTitle:[NSString stringWithFormat:@"%lu hops",(unsigned long)[annotations count]]];
    if ([annotations count] == 1) [listButton setTitle:@"1 hop"];
    [tableView reloadData];
    if ([annotations count] < 30) {
        [popoverView setFrame:NSMakeRect(0, 0, popoverView.frame.size.width, ([annotations count]+1)*19)];
        [listPopover setContentSize:popoverView.frame.size];
    }
    
    if ([[dict objectForKey:@"thetitle"] isEqualToString:[traceButton toolTip]])
    {
        //trace ended
        [traceButton setEnabled:YES];
        [traceButton setToolTip:@""];
        [bottomText setStringValue:[NSString stringWithFormat:@"Traceroute took %0.f seconds, the average ping is %1.f ms.",resolveStartTime-traceStartTime,[self averagePing]]];
        [bottomText setHidden:NO];
        [bottomLevel setHidden:YES];
    }else{
        [bottomLevel setDoubleValue:[annotations count]];
    }
    
}

-(float)averagePing
{
    float total = 0.0;
    for (CustomPointAnnotation *ann in annotations) total += [ann.ping floatValue];
    return total/[annotations count];
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
    polylineRender.strokeColor = [NSColor blackColor];
    return polylineRender;
}


#pragma mark NSTableView datasource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)theTableView
{
    return [annotations count];
}

- (id)tableView:(NSTableView *)theTableView objectValueForTableColumn:(NSTableColumn *)theColumn row:(NSInteger)rowIndex
{
	NSString *ident = [theColumn identifier];
    CustomPointAnnotation *item = [annotations objectAtIndex:rowIndex];
    
    if ([ident isEqualToString:@"flag"]) return [NSImage imageNamed:item.country];
    if ([ident isEqualToString:@"location"]) return item.note;
    if ([ident isEqualToString:@"ping"]) return item.ping;
    if ([ident isEqualToString:@"ip"]) return item.title;
    if ([ident isEqualToString:@"long"]) return [NSString stringWithFormat:@"%f",item.coordinate.longitude];
    if ([ident isEqualToString:@"lat"]) return [NSString stringWithFormat:@"%f",item.coordinate.latitude];
    if ([ident isEqualToString:@"hop"]) return [NSString stringWithFormat:@"%li",rowIndex+1];
    if ([ident isEqualToString:@"hostname"]) return item.hostname;

    return nil;
}

#pragma mark NSTableView delegate

- (NSMenu *)menuForClickedRow:(NSInteger)rowIndex inTable:(NSTableView *)theTableView
{
   
    NSMenu *ret = nil;
    CustomPointAnnotation *item = [annotations objectAtIndex:rowIndex];

    if (item.title) {
        ret = [[NSMenu alloc] initWithTitle:item.title];
        [ret addItemWithTitle:item.title action:nil keyEquivalent:@""];
        
        NSMenuItem *menuItem = [ret addItemWithTitle:@"Open in browser" action:@selector(http:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [menuItem setToolTip:item.title];
        
        NSMenuItem *menuItem1 = [ret addItemWithTitle:@"Whois" action:@selector(whois:) keyEquivalent:@""];
        [menuItem1 setTarget:self];
        [menuItem1 setToolTip:item.title];
        
    }
    
    return ret;
}


-(void)whois:(NSMenuItem*)sender
{
    NSString *ip = [sender toolTip];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://whois.arin.net/rest/nets;q=%@?showDetails=true&showARIN=false&ext=netref2",ip]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

-(void)http:(NSMenuItem*)sender
{
    NSString *ip = [sender toolTip];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@",ip]];
	[[NSWorkspace sharedWorkspace] openURL:url];
}

@end
