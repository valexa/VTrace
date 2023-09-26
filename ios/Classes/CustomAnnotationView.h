//
//  ToolbarController.h
//  Vtrace
//
//  Created by Vlad Alexa on 12/14/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//


#import <MapKit/MapKit.h>

#import "CustomPointAnnotation.h"

@interface CustomAnnotationView : MKAnnotationView
{
    CustomPointAnnotation *ann;
    NSString *title;
}

@end
