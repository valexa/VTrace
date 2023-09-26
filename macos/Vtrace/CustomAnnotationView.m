//
//  ToolbarController.h
//  Vtrace
//
//  Created by Vlad Alexa on 12/14/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import "CustomAnnotationView.h"

@implementation CustomAnnotationView

-(id)initWithAnnotation:(CustomPointAnnotation*)annotation reuseIdentifier:(NSString *)reuseIdentifier{
    
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    
    ann = annotation;
    
    title = ann.title;
    
    self.canShowCallout = YES;
    
    NSImage *pin = [NSImage imageNamed:@"pin"];
    [pin setSize:NSMakeSize(27, 40)];
     NSImage *pinImg = [NSImage imageWithSize:pin.size flipped:NO drawingHandler:^BOOL (NSRect dstRect)
    {
        [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
        //draw pin
        [pin drawInRect:dstRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1 respectFlipped:YES hints:@{NSImageHintInterpolation: @(NSImageInterpolationHigh)}];
        //draw ping
        NSColor *pingColor = [NSColor grayColor];
        if([annotation.ping floatValue] < 50) pingColor = [NSColor colorWithCalibratedRed:0.53 green:0.71 blue:0.27 alpha:1.0];
        if([annotation.ping floatValue] > 50) pingColor = [NSColor colorWithCalibratedRed:0.69 green:0.58 blue:0.27 alpha:1.0];
        if([annotation.ping floatValue] > 100) pingColor = [NSColor colorWithCalibratedRed:0.68 green:0.23 blue:0.26 alpha:1.0];
        //NSBezierPath *path = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(5, 17, 17.5,17.5)];
        //[pingColor set];
        //[path fill];
        //draw number
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica Neue" size:12.0],NSFontAttributeName,pingColor,NSForegroundColorAttributeName, nil];
        if ([self.reuseIdentifier integerValue] < 10) {
            [self.reuseIdentifier drawAtPoint:NSMakePoint(10, 20) withAttributes:attrsDictionary];
        }else{
            [self.reuseIdentifier drawAtPoint:NSMakePoint(6.5, 20) withAttributes:attrsDictionary];
        }
        return YES;
    }];
    
    self.image = pinImg;
    self.centerOffset = CGPointMake(0, -18);

    NSString *imgName = @"";
    if([annotation.ping floatValue] < 50) imgName = @"NSStatusAvailable";
    if([annotation.ping floatValue] > 50) imgName = @"NSStatusPartiallyAvailable";
    if([annotation.ping floatValue] > 100) imgName = @"NSStatusUnavailable";
    
    NSButton *leftButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
    NSImage *leftImg = [NSImage imageNamed:imgName];
    [leftButton setImage:leftImg];
    [leftButton setBordered:NO];
    [leftButton setButtonType:NSSwitchButton];
    [leftButton setTitle:@""];
    [leftButton setAction:@selector(leftPressed:)];
    [leftButton setTarget:self];
    self.leftCalloutAccessoryView = leftButton;
    
    NSButton *rightButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
    NSImage *info = [NSImage imageNamed:annotation.country];
    [info setSize:NSMakeSize(30, 30)];
    [rightButton setImage:info];
    [rightButton setTitle:@""];
    [rightButton setAction:@selector(rightPressed:)];
    [rightButton setTarget:self];
    [rightButton setBordered:NO];
    [rightButton setButtonType:NSMomentaryChangeButton];
    self.rightCalloutAccessoryView = rightButton;
    
    return self;
}

- (void)leftPressed:(id)sender
{
    if ([sender tag] < 1)
    {
        [ann setTitle:[NSString stringWithFormat:@"%i",[ann.ping intValue]]];
        [sender setTag:1];
    }else{
        [ann setTitle:title];
        [sender setTag:0];
    }
}

- (void)rightPressed:(id)sender
{
    if ([sender tag] < 1)
    {
        [ann setTitle:ann.note];
        [sender setTag:1];
    }else{
        [ann setTitle:title];
        [sender setTag:0];
    }
}


@end
