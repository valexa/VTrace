//
//  main.m
//  Vtrace
//
//  Created by Vlad Alexa on 12/13/13.
//  Copyright (c) 2013 Vlad Alexa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "VAValidation.h"

int main(int argc, const char * argv[])
{
    
    @autoreleasepool {
        int v = [VAValidation v];
        int a = [VAValidation a];
        if (v+a != 0) return(v+a);
    }
    
    return NSApplicationMain(argc, argv);
}
