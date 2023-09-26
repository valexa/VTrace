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
    
    self.enabled = YES;
    //self.animatesDrop= YES;
    self.multipleTouchEnabled = NO;
    
    UIImage *pin = [self UIImageFromPDF:@"pin.pdf" size:CGSizeMake(22,32)] ;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(22,32),NO,0.0);
    //draw pin
    [pin drawAtPoint:CGPointMake(0, 0)];
    //draw ping
    UIColor *pingColor = [UIColor grayColor];
    if([annotation.ping floatValue] < 50) pingColor = [UIColor colorWithRed:0.53 green:0.71 blue:0.27 alpha:1.0];
    if([annotation.ping floatValue] > 50) pingColor = [UIColor colorWithRed:0.69 green:0.58 blue:0.27 alpha:1.0];
    if([annotation.ping floatValue] > 100) pingColor = [UIColor colorWithRed:0.68 green:0.23 blue:0.26 alpha:1.0];
    //draw number
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont fontWithName:@"Helvetica Neue" size:10.0],NSFontAttributeName,pingColor,NSForegroundColorAttributeName, nil];
    if ([self.reuseIdentifier integerValue] < 10) {
        [self.reuseIdentifier drawAtPoint:CGPointMake(8, 3.5) withAttributes:attrsDictionary];
    }else{
        [self.reuseIdentifier drawAtPoint:CGPointMake(5, 3.5) withAttributes:attrsDictionary];
    }
    UIImage *pinImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = pinImage;
    self.centerOffset = CGPointMake(0, -14);
    
    
    UIImageView *leftIconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:ann.country]];
    self.leftCalloutAccessoryView = leftIconView;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        self.rightCalloutAccessoryView = rightButton;
    }
    
    return self;
}

-(UIImage *)UIImageFromPDF:(NSString*)fileName size:(CGSize)size{
	CFURLRef pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), (__bridge CFStringRef)fileName, NULL, NULL);
	if (pdfURL) {
		CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL(pdfURL);
		CFRelease(pdfURL);
        UIGraphicsBeginImageContextWithOptions(size,NO,0.0);
		CGContextRef context = UIGraphicsGetCurrentContext();
		//translate the content
		CGContextTranslateCTM(context, 0.0, size.height);
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextSaveGState(context);
		//scale to our desired size
		CGPDFPageRef page = CGPDFDocumentGetPage(pdf, 1);
		CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, CGRectMake(0, 0, size.width, size.height), 0, true);
		CGContextConcatCTM(context, pdfTransform);
		CGContextDrawPDFPage(context, page);
		CGContextRestoreGState(context);
		//return autoreleased UIImage
		UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		CGPDFDocumentRelease(pdf);
		return ret;
	}else {
		CLS_LOG(@"Could not load %@",fileName);
	}
	return nil;
}

@end
