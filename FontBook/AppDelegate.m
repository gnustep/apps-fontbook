//
//  AppDelegate.m
//  NSFontAssetRequest_test
//
//  Created by Gregory Casamento on 9/6/25.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching: (NSNotification *)aNotification
{
    // code after the app finishes launching...
    [[NSNotificationCenter defaultCenter] addObserver: self
					     selector: @selector(handleNotification:)
						 name: @"GSSelectedFontNotification"
					       object: nil];

    [self loadFonts: nil];
}


- (void)applicationWillTerminate: (NSNotification *)aNotification
{
  // Insert code here to tear down your application
}

- (BOOL)applicationSupportsSecureRestorableState: (NSApplication *)app
{
  return YES;
}

- (void) handleNotification: (NSNotification *)notif
{
  NSDictionary *obj = [notif object];
  NSLog(@"object = %@", obj);
  [fontNameField setStringValue: [obj objectForKey: @"family"]];
}

- (IBAction) downloadFont: (id)sender
{
  NSFontDescriptor *descriptor = [NSFontDescriptor fontDescriptorWithName: [fontNameField stringValue] size: 12.0];
  NSArray *fontDescriptors = [NSArray arrayWithObject: descriptor];

  // This part does NOT work on macOS as Apple has it's own font source... GNUstep uses google fonts.
#ifndef GNUSTEP
  NSFontAssetRequest *request = [[NSFontAssetRequest alloc]
				   initWithFontDescriptors: fontDescriptors
						   options: NSFontAssetRequestOptionUsesStandardUI];

  [request downloadFontAssetsWithCompletionHandler:^BOOL(NSError * _Nullable error) {
      if (error != NULL)
	{
	  NSLog(@"Downloaded with completion code %@", error);
	  return NO;
	}
      return YES;
    }];
#else
    NSLog(@"Not installed, this is a test for GNUstep");
#endif
    
}

- (void)awakeFromNib
{
  // Initialize the fonts controller
  // fontsController = [[GoogleFontsController alloc] init];

  // Set up the table view
  [self setupTableView];

  // Connect the controller to the table view
  // This would typically be done in Interface Builder,
  // but here's how to do it programmatically:
  [tableView setDataSource: fontsController];
  [tableView setDelegate: fontsController];
}

- (void)setupTableView
{
  // Create table columns programmatically
  // (In Interface Builder, you'd set these up visually)

  NSTableColumn *familyColumn = [[NSTableColumn alloc] initWithIdentifier: @"family"];
  [[familyColumn headerCell] setStringValue: @"Font Family"];
  [familyColumn setWidth: 200];
  [tableView addTableColumn: familyColumn];

  NSTableColumn *categoryColumn = [[NSTableColumn alloc] initWithIdentifier: @"category"];
  [[categoryColumn headerCell] setStringValue: @"Category"];
  [categoryColumn setWidth: 100];
  [tableView addTableColumn: categoryColumn];

  NSTableColumn *variantsColumn = [[NSTableColumn alloc] initWithIdentifier: @"variants"];
  [[variantsColumn headerCell] setStringValue: @"Variants"];
  [variantsColumn setWidth: 150];
  [tableView addTableColumn: variantsColumn];

  NSTableColumn *subsetsColumn = [[NSTableColumn alloc] initWithIdentifier: @"subsets"];
  [[subsetsColumn headerCell] setStringValue: @"Subsets"];
  [subsetsColumn setWidth: 200];
  [tableView addTableColumn: subsetsColumn];

  [fontsController setTableView: tableView];
}

- (IBAction) loadFonts: (id)sender
{
  // Load fonts using the Google Fonts API
  // Note: You'll need an API key for the official endpoint
  // NSString *apiKey = @"YOUR_API_KEY_HERE";
  // NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/webfonts/v1/webfonts?key=%@", apiKey];
  NSString *urlString = @"https://fonts.google.com/metadata/fonts";

  // For the metadata endpoint you mentioned (if it becomes accessible):
  // NSString *urlString = @"https://fonts.google.com/metadata/fonts";

  [fontsController loadFontsFromURL: urlString];
}

@end
