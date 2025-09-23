//
//  AppDelegate.h
//  NSFontAssetRequest_test
//
//  Created by Gregory Casamento on 9/6/25.
//

#import <Cocoa/Cocoa.h>
#import "GoogleFontsController.h"

@interface AppDelegate : NSObject
{
    IBOutlet NSWindow *window;
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *fontNameField;
    IBOutlet NSButton *button;
    IBOutlet GoogleFontsController *fontsController;
}

- (IBAction)loadFonts:(id)sender;

@end

