//
//  FlipsideViewController.m
//  Vtrace
//
//  Created by Vlad Alexa on 10/9/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "FlipsideViewController.h"

@implementation FlipsideViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
        
        self.list = [NSMutableArray arrayWithCapacity:1];

    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[_theTable reloadData];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {	
    // When the user presses return, take focus away from the text field so that the keyboard is dismissed.
    [theTextField resignFirstResponder];
    [_traceButton setEnabled:YES];
    return YES;
}

-(void)setHostname:(NSString*)hostname forIP:(NSString*)ip
{
    if (!hostname || !ip) return;

    NSMutableDictionary *new = nil;
    NSUInteger index;
    for (NSDictionary *dict in _list) {
        if ([[dict objectForKey:@"thetitle"] isEqualToString:ip])
        {
            index = [_list indexOfObject:dict];
            new = [NSMutableDictionary dictionaryWithDictionary:dict];
            [new setObject:hostname forKey:@"thehostname"];
        }
    }
    
    if (new) {
        [_list replaceObjectAtIndex:index withObject:new];
        [_theTable reloadData];
    }
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
    return [_list count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	// Only one section
	return 1;
}

// to determine which UITableViewCell to be used on a given row
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	static NSString *MyIdentifier = @"MyIdentifier";	
	UITableViewCell *cell = nil;
	//do not reuse the cell so the table refreshes on rotations
	//cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];	
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
	
	NSDictionary *d = [_list objectAtIndex:[indexPath indexAtPosition:1]];
	if (d != nil){		
		//image
		NSString *image = [NSString stringWithFormat:@"%@.png",[d valueForKey:@"country"]];
		UIImage *leftIcon = [UIImage imageNamed:image];
		UIImageView *flagView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 0, 32, 32)];
		[flagView setImage:leftIcon];
		[cell.contentView addSubview:flagView];
		//image footer
		UILabel *countryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 33, 44, 9)];
		countryLabel.font = [UIFont systemFontOfSize:9.0];
		countryLabel.textAlignment = NSTextAlignmentCenter;
		countryLabel.text = [d valueForKey:@"country"];	
		[cell.contentView addSubview:countryLabel];
		//title
		UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55, 0, 200, 32)];
		titleLabel.textAlignment = NSTextAlignmentLeft;	
		titleLabel.font = [UIFont systemFontOfSize:20];
		titleLabel.text = [d valueForKey:@"thetitle"];
		[cell.contentView addSubview:titleLabel];
		//title footer
		UILabel *tfLabel = [[UILabel alloc] initWithFrame:CGRectMake(45, 27, 270, 17)];
		tfLabel.textColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];	
		tfLabel.textAlignment = NSTextAlignmentLeft;	
		tfLabel.font = [UIFont systemFontOfSize:13];
		tfLabel.text = [d valueForKey:@"thenote"];
		[cell.contentView addSubview:tfLabel];	
		//hostname
		if (self.view.bounds.size.width > 450) {
			float middle;
			if (self.view.bounds.size.width < 500) {
				middle = 230.0;
			}else{
				middle = (self.view.bounds.size.width-190)/2;				
			}		
			UILabel *hnLabel = [[UILabel alloc] initWithFrame:CGRectMake(middle, 16, self.view.bounds.size.width/2.6, 17)];
			hnLabel.textColor = [UIColor colorWithRed:0.92 green:0.49 blue:0.34 alpha:1.0];
            hnLabel.backgroundColor = [UIColor clearColor];
			hnLabel.textAlignment = NSTextAlignmentCenter;	
			hnLabel.font = [UIFont systemFontOfSize:12];
			hnLabel.text = [d valueForKey:@"thehostname"];
			[cell.contentView addSubview:hnLabel];	
		}
		//accessory top
		UILabel *accLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-70, 16, 60, 13)];
		accLabel.textColor = [UIColor colorWithRed:0.1 green:0.2 blue:0.5 alpha:0.7];
		accLabel.textAlignment = NSTextAlignmentRight;	
		accLabel.font = [UIFont systemFontOfSize:12];
		accLabel.text = [NSString stringWithFormat:@"%.1f ms",[[d valueForKey:@"theping"] floatValue]];
		[cell.contentView addSubview:accLabel];
		//accesory footer
		UILabel *afLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width-70, 1, 60, 16.5)];
		afLabel.textAlignment = NSTextAlignmentRight;	
		afLabel.font = [UIFont systemFontOfSize:16];
		afLabel.text = [d valueForKey:@"theid"];
		[cell.contentView addSubview:afLabel];		
	}else {
		CLS_LOG(@"No data for %lu",(unsigned long)[indexPath indexAtPosition:1]);
	}
	
	return cell;
}

 
#pragma mark Actions

- (IBAction)trace
{
    [_traceButton setEnabled:NO];
	addressResolver = [[AddressResolver alloc] initWithAddress:theInput.text]; //if ip does not have a reverse dns it is not accepted
    addressResolver.delegate = self;
}

- (IBAction)done {
	[self.delegate flipsideViewControllerDidFinish:self address:@"null" family:0];	
}

#pragma mark AddressResolver delegate

- (void)addressResolver:(AddressResolver *)resolver didFinishWithStatus:(NSError *)error
{
	if (error == nil)
    {
        [_list removeAllObjects];
        [self setTitle:resolver.ip];
        [self.delegate flipsideViewControllerDidFinish:self address:resolver.ip family:resolver.family];
        addressResolver = nil; // let ARC free it
	}else {
        [_traceButton setEnabled:YES];
        UIAlertView *sendAlert = [[UIAlertView alloc] initWithTitle:@"IP or hostname is invalid" message:@"Only addresses with working reverse dns are supported or hostnames with working dns" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [VtraceAppDelegate logEventNamed:@"Invalid Entry" parameters:@{@"error": theInput.text}];
        [sendAlert show];
	}
}

#pragma mark utility

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{	
	[_theTable reloadData];
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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
}


@end
