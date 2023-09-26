//
//  ToolbarController.h
//  Vtrace
//
//  Created by Vlad Alexa on 12/14/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface CustomPointAnnotation : MKPointAnnotation

@property (copy) NSString *note;
@property (copy) NSString *ping;
@property (copy) NSString *country;
@property (copy) NSString *hostname;

@end
