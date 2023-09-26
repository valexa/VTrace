//
//  PopViewController.m
//  VTrace
//
//  Created by Vlad Alexa on 4/27/10.
//  Copyright 2010 NextDesign. All rights reserved.
//

#import "PopViewController.h"


@implementation PopViewController

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}

/*
 // Implement loadView to create a view hierarchy programmatically, without using a nib.
 - (void)loadView {
 }
 */


 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 - (void)viewDidLoad {
	 [super viewDidLoad];
 }

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark UITableView delegates

/*
 To conform to Human Interface Guildelines, since selecting a row would have no effect (such as navigation), make sure that rows cannot be selected.
 */
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSArray *labels = [[tableView cellForRowAtIndexPath:indexPath].contentView subviews];
	NSString *value = @"";
	for (id label in labels) {
		if ([label isKindOfClass:[UILabel class]]){	
			value = [NSString stringWithFormat:@"%@ %@",value,[label text]];
		}
	}
	UIPasteboard *gpBoard = [UIPasteboard generalPasteboard];	
	[gpBoard setValue:value forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
	//CLS_LOG(@"copied %@",value);
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 7;	
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	
	if ([indexPath indexAtPosition:0] == 0) cell.textLabel.text = [_dict objectForKey:@"theid"];
	if ([indexPath indexAtPosition:0] == 1) cell.textLabel.text = [_dict objectForKey:@"theping"];
	if ([indexPath indexAtPosition:0] == 2) cell.textLabel.text = [_dict objectForKey:@"thetitle"];
	if ([indexPath indexAtPosition:0] == 3) cell.textLabel.text = [_dict objectForKey:@"thehostname"];
	if ([indexPath indexAtPosition:0] == 4) cell.textLabel.text = [_dict objectForKey:@"longitude"];
	if ([indexPath indexAtPosition:0] == 5) cell.textLabel.text = [_dict objectForKey:@"latitude"];
	if ([indexPath indexAtPosition:0] == 6) cell.textLabel.text = [_dict objectForKey:@"thenote"];
	
	cell.textLabel.font = [UIFont systemFontOfSize:16];	
	
	return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	if (section == 0) return @"Hop #";
	if (section == 1) return @"Ping";
	if (section == 2) return @"Ip Address";
	if (section == 3) return @"Hostname";
	if (section == 4) return @"Longitude";
	if (section == 5) return @"Latitude";
	if (section == 6) return @"Location";
	return @"";
}

@end
