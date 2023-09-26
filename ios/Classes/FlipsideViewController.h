//
//  FlipsideViewController.h
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "AddressResolver.h"

#import <MobileCoreServices/MobileCoreServices.h>

@protocol FlipsideViewControllerDelegate;

@interface FlipsideViewController : UIViewController <AddressResolverDelegate,UITableViewDelegate,UITableViewDataSource>  {
	IBOutlet UITextField *theInput;	
    AddressResolver *addressResolver;
    sa_family_t family;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, retain) NSMutableArray *list;
@property (nonatomic, retain) IBOutlet UITableView *theTable;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *traceButton;

- (IBAction)done;
- (IBAction)trace;
-(void)setHostname:(NSString*)hostname forIP:(NSString*)ip;

@end


@protocol FlipsideViewControllerDelegate
@required
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller address:(NSString *)address family:(sa_family_t)family;
@end

