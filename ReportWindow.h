//
//  ReportWindow.h
//  Money
//
//  Created by Paul Dorman on 1/19/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface ReportWindow : NSWindowController {
	IBOutlet NSTableView *accountTable;
	IBOutlet NSDatePicker *beginDate;
	IBOutlet NSDatePicker *endDate;
	IBOutlet NSTableView *categoryTable;
	IBOutlet NSTextField *moreThan;
	IBOutlet NSTextField *lessThan;
	IBOutlet NSTextField *payeeContains;
	IBOutlet NSTextField *memoContains;
	IBOutlet NSTextField *refContains;
	IBOutlet NSButtonCell *anyCleared;
	IBOutlet NSButtonCell *yesCleared;
	IBOutlet NSButtonCell *noCleared;
	
	IBOutlet NSWindow *reportWindow;
	IBOutlet WebView *webView;
}

- (IBAction) changeDateType:(id)sender;
- (IBAction) generateReport:(id)sender;

- (void) refresh;

- (NSView *) printView;

// table view delegate
- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// tableView protocols
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

// item validation protocols
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

@end
