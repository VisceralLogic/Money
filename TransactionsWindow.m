//
//  TransactionsWindow.m
//  Money
//
//  Created by Paul Dorman on 12/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "TransactionsWindow.h"
#import "AccountDocument.h"

@implementation TransactionsWindow

- (id) init {
	self = [super initWithWindowNibName:@"TransactionsWindow"];
	index = -1;
	return self;
}

- (void) awakeFromNib{
	[(AccountDocument*)[self document] associateTableView:tableView withAccount:self];
	account = [(AccountDocument*)[self document] accountForWindow:self];
	[tableView setDataSource:self];
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(doubleClick:)];
	[cat setDataSource:[self document]];
	[self refresh];
	
	// scroll to bottom of window
	NSPoint newScrollOrigin;
    if ([[scrollview documentView] isFlipped]) {
        newScrollOrigin=NSMakePoint(0.0,NSMaxY([[scrollview documentView] frame])-NSHeight([[scrollview contentView] bounds]));
    } else {
        newScrollOrigin=NSMakePoint(0.0,0.0);
    }	
    [[scrollview documentView] scrollPoint:newScrollOrigin];
}

- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName{
	return [displayName stringByAppendingFormat:@" [%@]", [(AccountDocument*)[self document] accountName:self]];
}

- (BOOL) windowShouldClose:(id)sender{
	return [(AccountDocument*)[self document] closeAccountWindow:self];
}

- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *)window{
	return [[self document] undoManager];
}

- (void) doubleClick:(id)stuff{
	index = [tableView clickedRow];
	Transaction *t = [(AccountDocument*)[self document] getTransaction:index forAccount:self];
	[date setDateValue:t->date];
	[ref setStringValue:t->ref];
	[payee setStringValue:t->payee];
    [rec setState:t->cleared ? NSControlStateValueOn : NSControlStateValueOff];
	[cat setStringValue:t->category];
	[memo setStringValue:t->memo];
	[amount setStringValue:format(t->cents)];
	[transactionWindow makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] runModalForWindow:transactionWindow];
}

- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	return NO;
}

- (IBAction) cancelTransaction:(id)sender{
	[transactionWindow close];
	[[NSApplication sharedApplication] stopModal];
}

- (IBAction) recordTransaction:(id)sender{
	[transactionWindow close];
	[[NSApplication sharedApplication] stopModal];
	
	// fill in a new transaction
	Transaction *t = [[[Transaction alloc] init] autorelease];
	t->date = [[date dateValue] retain];
	t->ref = [[ref stringValue] retain];
	t->payee = [[payee stringValue] retain];
    t->cleared = ([rec state] == NSControlStateValueOn);
	t->category = [[cat stringValue] retain];
	t->memo = [[memo stringValue] retain];
	t->cents = roundf([amount floatValue]*100);
	t->account = [[(AccountDocument*)[self document] accountName:self] retain];
	
	if( index == -1 )
		[(AccountDocument*)[self document] addTransaction:t];
	else
		[(AccountDocument*)[self document] replaceTransaction:index fromAccount:self withTransaction:t];

	[self refresh];
}

- (IBAction) newTransaction:(id)sender{
	index = -1;
	[date setDateValue:[NSDate date]];
	[ref setStringValue:@""];
	[payee setStringValue:@""];
    [rec setState:NSControlStateValueOff];
	[cat setStringValue:@""];
	[memo setStringValue:@""];
	[amount setStringValue:format(0)];
	[transactionWindow makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] runModalForWindow:transactionWindow];
}

- (IBAction) deleteTransaction:(id)sender{
	if( [tableView numberOfSelectedRows] > 0 ){
		NSIndexSet *rows = [tableView selectedRowIndexes];
		NSUInteger row = [rows lastIndex];
		do {
			[(AccountDocument*)[self document] deleteTransaction:row fromAccount:self];
		} while( (row = [rows indexLessThanIndex:row]) != NSNotFound );
		[self refresh];
	}
}

- (IBAction) toggleReconcile:(id)sender{
	if( [tableView numberOfSelectedRows] > 0 ){
		NSIndexSet *rows = [tableView selectedRowIndexes];
		NSUInteger row = [rows lastIndex];
		do {
			Transaction *t = [[account transactions] objectAtIndex:row];
			t->cleared = !t->cleared;
		} while( (row = [rows indexLessThanIndex:row]) != NSNotFound );
		[self refresh];
	}
}

- (void) refresh{
	[tableView reloadData];
	
	[balance setStringValue:format([Transaction valueOfTransactions:[account transactions]])];
	[today setStringValue:format([Transaction valueOfTransactions:[account transactions] atDate:[NSDate date]])];
}

- (NSView *) printView{
	return tableView;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
	return (int)[[account transactions] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	Transaction *t = [[account transactions] objectAtIndex:rowIndex];
	NSString *field = [aTableColumn identifier];
	if( [field isEqualToString:@"date"] )
		return formatDate(t->date);
	if( [field isEqualToString:@"payee"] )
		return t->payee;
	else if( [field isEqualToString:@"category"] )
		return t->category;
	else if( [field isEqualToString:@"memo"] )
		return t->memo;
	else if( [field isEqualToString:@"ref"] )
		return t->ref;
	else if( [field isEqualToString:@"rec"] )
		return (t->cleared ? @"R" : @"");
	else if( [field isEqualToString:@"amount"] )
		return format(t->cents);
	else if( [field isEqualToString:@"total"] )
		return format([[[account totals] objectAtIndex:rowIndex] intValue]);
	else 
		return @"";
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	if( [tableView numberOfSelectedRows] > 0 )
		[deleteButton setEnabled:YES];
	else
		[deleteButton setEnabled:NO];
}

- (BOOL) validateMenuItem:(NSMenuItem *)item{
	if( [item action] == @selector(deleteTransactions:) || [item action] == @selector(reconcileTransactions:) ){
		if( [tableView numberOfSelectedRows] > 0 )
			return YES;
		return NO;
	} else if( [item action] == @selector(newTransaction:) )
		return YES;
	
	return NO;
}

@end
