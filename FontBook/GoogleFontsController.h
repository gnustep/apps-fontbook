//
//  GoogleFontsController.h
//  Google Fonts Viewer for GNUstep
//
//  Created for Objective-C 1.0 / GNUstep
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface GoogleFontsController : NSObject  <NSTableViewDelegate, NSTableViewDataSource>
{
    IBOutlet NSTableView *fontsTableView;
    NSMutableArray *fontsArray;
    NSMutableData *receivedData;
}

// Properties (manual getter/setter for ObjC 1.0)
- (NSMutableArray *)fontsArray;
- (void)setFontsArray:(NSMutableArray *)array;

// Initialization
- (id)init;
- (void)dealloc;

// Font loading methods
- (void)loadFontsFromURL:(NSString *)urlString;
- (void)parseFontsData:(NSData *)data;

// NSTableViewDataSource methods
- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;

// NSTableViewDelegate methods
- (void)tableViewSelectionDidChange:(NSNotification *)notification;
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row;

- (void) setTableView: (NSTableView *)tv;
- (NSTableView *) tableView;

@end
