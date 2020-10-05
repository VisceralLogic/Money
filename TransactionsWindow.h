//
//  TransactionsWindow.h
//  Money
//
//  Created by Paul Dorman on 12/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountsWindow.h"
#import "Account.h"

@interface TransactionsWindow : NSWindowController {
	IBOutlet NSTableView *tableView;
	IBOutlet NSScrollView *scrollview;
	IBOutlet NSWindow *transactionWindow;
	
	IBOutlet NSTextField *balance;
	IBOutlet NSTextField *today;
	
	IBOutlet NSButton *deleteButton;
	
	// fields in transaction editor
	IBOutlet NSDatePickerCell *date;
	IBOutlet NSTextField *ref;
	IBOutlet NSTextField *payee;
	IBOutlet NSButton *rec;
	IBOutlet NSComboBox *cat;
	IBOutlet NSTextField *memo;
	IBOutlet NSTextField *amount;
	
	NSInteger index;	// transaction being modified
	
	Account *account;
}

- (IBAction) cancelTransaction:(id)sender;
- (IBAction) recordTransaction:(id)sender;
- (IBAction) newTransaction:(id)sender;
- (IBAction) deleteTransaction:(id)sender;

- (IBAction) toggleReconcile:(id)sender;

- (void) refresh;

- (NSView *) printView;

// delegate method from window
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window;
- (BOOL) windowShouldClose:(id)sender;

// action method from tableView
- (void) doubleClick:(id)stuff;

// delegate method from tableView
- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;

// tableView protocols
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

// item validation protocols
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

@end
