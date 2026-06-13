//
//  AppDelegate.m
//  NSFontAssetRequest_test
//
//  Created by Gregory Casamento on 9/6/25.
//

#import "AppDelegate.h"
#ifdef GNUSTEP
#import <GNUstepGUI/GSFontAssetDownloader.h>
#import <dlfcn.h>
#endif

static NSString *FontBookPreviewSampleText = @"Sphinx of black quartz, judge my vow.\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz 0123456789";

#ifdef GNUSTEP
typedef void FBPreviewFcConfig;
typedef unsigned char FBPreviewFcChar8;
typedef int FBPreviewFcBool;
typedef FBPreviewFcConfig *(*FBPreviewFcConfigGetCurrentFunction)(void);
typedef FBPreviewFcBool (*FBPreviewFcConfigAppFontAddFileFunction)(FBPreviewFcConfig *, const FBPreviewFcChar8 *);
#endif

@interface AppDelegate (FontPreview)
- (void)setupPreviewView;
- (void)previewFontFamily: (NSString *)family;
- (void)loadPreviewFontInBackground: (NSString *)family;
- (void)finishPreviewFontLoad: (NSDictionary *)result;
- (void)failPreviewFontLoad: (NSDictionary *)result;
- (void)applyPreviewForFamily: (NSString *)family fontPath: (NSString *)fontPath;
- (BOOL)addTemporaryFontPathToFontconfig: (NSString *)fontPath;
@end

@implementation AppDelegate

- (id)init
{
  self = [super init];
  if (self != nil)
    {
      previewFontPathsByFamily = [[NSMutableDictionary alloc] init];
    }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
#ifdef GNUSTEP
  [previewTextField release];
  [previewStatusField release];
  [previewRequestFamily release];
  [previewFontPathsByFamily release];
  [super dealloc];
#endif
}

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
  NSString *family = [obj objectForKey: @"family"];
  NSLog(@"object = %@", obj);
  [fontNameField setStringValue: family];
  [self previewFontFamily: family];
}

- (IBAction) downloadFont: (id)sender
{
  NSFontDescriptor *descriptor = [NSFontDescriptor fontDescriptorWithName: [fontNameField stringValue] size: 12.0];
  NSArray *fontDescriptors = [NSArray arrayWithObject: descriptor];

  // This part does NOT work on macOS as Apple has it's own font source... GNUstep uses google fonts.
#ifdef GNUSTEP
  NSFontAssetRequest *request = [[NSFontAssetRequest alloc]
				   initWithFontDescriptors: fontDescriptors
						   options: NSFontAssetRequestOptionUsesStandardUI];

  [request downloadFontAssetsWithCompletionHandler:^BOOL(NSError *error) {
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
  // Set up the table view
  [self setupTableView];
  [self setupPreviewView];

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

- (void)setupPreviewView
{
  NSView *contentView = [window contentView];
  NSRect tableFrame = [[tableView enclosingScrollView] frame];
  tableFrame.origin.y = 150;
  tableFrame.size.height = 190;
  [[tableView enclosingScrollView] setFrame: tableFrame];

  previewTextField = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 62, 440, 72)];
  [previewTextField setStringValue: @"Select a font to preview it before installing."];
  [previewTextField setEditable: NO];
  [previewTextField setSelectable: NO];
  [previewTextField setBezeled: YES];
  [previewTextField setDrawsBackground: YES];
  [previewTextField setFont: [NSFont systemFontOfSize: 20.0]];
  [[previewTextField cell] setScrollable: NO];
  [[previewTextField cell] setWraps: YES];
  [previewTextField setAutoresizingMask: NSViewWidthSizable | NSViewMaxYMargin];
  [contentView addSubview: previewTextField];

  previewStatusField = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 134, 440, 16)];
  [previewStatusField setStringValue: @"Preview"];
  [previewStatusField setEditable: NO];
  [previewStatusField setSelectable: NO];
  [previewStatusField setBezeled: NO];
  [previewStatusField setDrawsBackground: NO];
  [previewStatusField setFont: [NSFont systemFontOfSize: 11.0]];
  [previewStatusField setAutoresizingMask: NSViewWidthSizable | NSViewMaxYMargin];
  [contentView addSubview: previewStatusField];
}

- (NSString *)googleCSSURLStringForFamily: (NSString *)family
{
  NSString *encodedFamily = [family stringByAddingPercentEncodingWithAllowedCharacters: [NSCharacterSet URLQueryAllowedCharacterSet]];
  return [NSString stringWithFormat: @"https://fonts.googleapis.com/css2?family=%@", encodedFamily];
}

- (void)setPreviewStatus: (NSString *)status
{
  [previewStatusField setStringValue: status ? status : @""];
}

- (void)previewFontFamily: (NSString *)family
{
  if (family == nil || [family length] == 0)
    {
      return;
    }

  if (previewRequestFamily != family)
    {
#ifdef GNUSTEP
      [previewRequestFamily release];
      previewRequestFamily = [family retain];
#else
      previewRequestFamily = family;
#endif
    }

  [previewTextField setStringValue: FontBookPreviewSampleText];
  [previewTextField setFont: [NSFont systemFontOfSize: 20.0]];
  [self setPreviewStatus: [NSString stringWithFormat: @"Loading %@ preview...", family]];

  NSString *cachedPath = [previewFontPathsByFamily objectForKey: family];
  if (cachedPath != nil)
    {
      [self applyPreviewForFamily: family fontPath: cachedPath];
      return;
    }

#ifdef GNUSTEP
  [NSThread detachNewThreadSelector: @selector(loadPreviewFontInBackground:)
			   toTarget: self
			 withObject: family];
#else
  [self setPreviewStatus: @"Preview downloads are implemented for GNUstep."];
#endif
}

- (void)loadPreviewFontInBackground: (NSString *)family
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSString *cssURLString = [self googleCSSURLStringForFamily: family];
  NSURL *cssURL = [NSURL URLWithString: cssURLString];
  NSError *error = nil;
  NSString *fontPath = nil;

#ifdef GNUSTEP
  GSFontAssetDownloader *downloader = [GSFontAssetDownloader downloaderWithOptions: 0];
  fontPath = [downloader downloadFontDataFromCSSURL: cssURL
					withFormat: @"woff2"
					  fontName: family
					     error: &error];
  if (fontPath == nil)
    {
      error = nil;
      fontPath = [downloader downloadFontDataFromCSSURL: cssURL
					    withFormat: @"truetype"
					      fontName: family
						 error: &error];
    }
  if (fontPath == nil)
    {
      error = nil;
      fontPath = [downloader downloadFontDataFromCSSURL: cssURL
					    withFormat: nil
					      fontName: family
						 error: &error];
    }
#endif

  if (fontPath != nil)
    {
      NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
					     family, @"family",
					   fontPath, @"fontPath",
					   nil];
      [self performSelectorOnMainThread: @selector(finishPreviewFontLoad:)
			     withObject: result
			  waitUntilDone: NO];
    }
  else
    {
      NSString *message = [NSString stringWithFormat: @"No preview font available for %@.", family];
      if (error != nil)
	{
	  message = [NSString stringWithFormat: @"Preview failed for %@: %@", family, [error localizedDescription]];
	}
      NSDictionary *result = [NSDictionary dictionaryWithObjectsAndKeys:
					     family, @"family",
					   message, @"message",
					   nil];
      [self performSelectorOnMainThread: @selector(failPreviewFontLoad:)
			     withObject: result
			  waitUntilDone: NO];
    }
  [pool release];
}

- (void)finishPreviewFontLoad: (NSDictionary *)result
{
  NSString *family = [result objectForKey: @"family"];
  NSString *fontPath = [result objectForKey: @"fontPath"];

  if (![family isEqualToString: previewRequestFamily])
    {
      return;
    }

  [previewFontPathsByFamily setObject: fontPath forKey: family];
  [self applyPreviewForFamily: family fontPath: fontPath];
}

- (void)failPreviewFontLoad: (NSDictionary *)result
{
  NSString *family = [result objectForKey: @"family"];
  NSString *message = [result objectForKey: @"message"];

  if (![family isEqualToString: previewRequestFamily])
    {
      return;
    }

  [self setPreviewStatus: message];
}

- (void)applyPreviewForFamily: (NSString *)family fontPath: (NSString *)fontPath
{
  NSFont *previewFont = nil;

#ifdef GNUSTEP
  if ([self addTemporaryFontPathToFontconfig: fontPath])
    {
      [[NSFontManager sharedFontManager] refreshAvailableFonts];
    }
#endif

  previewFont = [NSFont fontWithName: family size: 24.0];
  if (previewFont == nil)
    {
      NSFontDescriptor *descriptor = [[NSFontDescriptor fontDescriptorWithName: family size: 24.0] fontDescriptorWithFamily: family];
      previewFont = [NSFont fontWithDescriptor: descriptor size: 24.0];
    }

  if (previewFont != nil)
    {
      [previewTextField setFont: previewFont];
      [previewTextField setStringValue: FontBookPreviewSampleText];
      [self setPreviewStatus: [NSString stringWithFormat: @"Previewing %@ from temporary download.", family]];
    }
  else
    {
      [previewTextField setFont: [NSFont systemFontOfSize: 20.0]];
      [self setPreviewStatus: [NSString stringWithFormat: @"Downloaded %@ preview, but GNUstep could not activate it for this session.", family]];
    }
}

- (BOOL)addTemporaryFontPathToFontconfig: (NSString *)fontPath
{
#ifdef GNUSTEP
  static void *fontconfigHandle = NULL;
  static FBPreviewFcConfigGetCurrentFunction getCurrentConfig = NULL;
  static FBPreviewFcConfigAppFontAddFileFunction addAppFontFile = NULL;

  if (fontPath == nil)
    {
      return NO;
    }

  if (fontconfigHandle == NULL)
    {
      fontconfigHandle = dlopen("libfontconfig.so.1", RTLD_LAZY);
      if (fontconfigHandle == NULL)
	{
	  fontconfigHandle = dlopen("libfontconfig.so", RTLD_LAZY);
	}
      if (fontconfigHandle != NULL)
	{
	  getCurrentConfig = (FBPreviewFcConfigGetCurrentFunction)dlsym(fontconfigHandle, "FcConfigGetCurrent");
	  addAppFontFile = (FBPreviewFcConfigAppFontAddFileFunction)dlsym(fontconfigHandle, "FcConfigAppFontAddFile");
	}
    }

  if (getCurrentConfig == NULL || addAppFontFile == NULL)
    {
      return NO;
    }

  return addAppFontFile(getCurrentConfig(), (const FBPreviewFcChar8 *)[fontPath fileSystemRepresentation]) ? YES : NO;
#else
  return NO;
#endif
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
