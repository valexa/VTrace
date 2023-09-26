//
//  PopViewController.h
//  VTrace
//
//  Created by Vlad Alexa on 4/27/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface PopViewController : UIViewController <UITableViewDelegate,UITableViewDataSource>
{
	IBOutlet UITableView *theTable;
}

@property (nonatomic, retain) NSDictionary *dict;

@end

