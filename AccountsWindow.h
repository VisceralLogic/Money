//
//  AccountsWindow.h
//  Money
//
//  Created by Paul Dorman on 12/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Account.h"


@interface AccountsWindow : NSWindowController {
    IBOutlet NSTableView *tableView;
	IBOutlet NSTextField *total;
	
	IBOutlet NSButton *modifyButton;
	
	// modify account window
	IBOutlet NSWindow *modifyWindow;
	IBOutlet NSTextField *name;
	IBOutlet NSButton *visible;
	IBOutlet NSButton *include;
	BOOL returnVal;
}

- (IBAction) newAccount:(id)sender;
- (IBAction) modifyAccount:(id)sender;
- (IBAction) deleteAccount:(id)sender;

- (IBAction) modifyAccountOK:(id)sender;
- (IBAction) modifyAccountCancel:(id)sender;

- (BOOL) modifyThisAccount:(Account*)account;

- (void) refresh;

- (NSView *) printView;

// action method from tableView
- (void) doubleClick:(id)stuff;

// delegate method from tableView
- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

// delegate method from window
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;

// item validation protocol
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

@end
