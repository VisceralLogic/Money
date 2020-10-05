//
//  AccountsWindow.m
//  Money
//
//  Created by Paul Dorman on 12/28/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountsWindow.h"
#import "AccountDocument.h"

@implementation AccountsWindow

- (id) init {
	self = [super initWithWindowNibName:@"AccountsWindow"];
	return self;
}

- (void) awakeFromNib{
	[tableView setDataSource:[self document]];
	[tableView setTarget:self];
	[tableView setDoubleAction:@selector(doubleClick:)];
	[(AccountDocument*)[self document] setTotalField:total];
}

- (void) doubleClick:(id)stuff{
	[(AccountDocument*)[self document] openAccount:[tableView clickedRow]];
}

- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	return NO;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	[(AccountDocument*)[self document] formatCell:aCell atColumn:aTableColumn row:rowIndex];
}

- (void) refresh{
	[tableView reloadData];
}

- (NSView *) printView{
	return [[self window] contentView];
}

- (IBAction) newAccount:(id)sender{
	[(AccountDocument*)[self document] newAccount];
}

- (IBAction) modifyAccount:(id)sender{
	[(AccountDocument*)[self document] modifyAccount:[[tableView selectedRowIndexes] firstIndex]];
}

- (IBAction) deleteAccount:(id)sender{
	[(AccountDocument*)[self document] deleteAccount:[[tableView selectedRowIndexes] firstIndex]];
}

- (BOOL) modifyThisAccount:(Account *)account{
	[name setStringValue:[account name]];
    [visible setState:[account show] ? NSControlStateValueOn : NSControlStateValueOff];
    [include setState:[account include] ? NSControlStateValueOn : NSControlStateValueOff];
	[modifyWindow makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] runModalForWindow:modifyWindow];
	[modifyWindow close];
	if( returnVal ){
		[account setName:[name stringValue]];
		[account setShow:[visible state] == NSControlStateValueOn];
		[account setInclude:[include state] == NSControlStateValueOn];
		return YES;
	}
	return NO;
}

- (IBAction) modifyAccountOK:(id)sender{
	[[NSApplication sharedApplication] stopModal];
	returnVal = YES;
}

- (IBAction) modifyAccountCancel:(id)sender{
	[[NSApplication sharedApplication] stopModal];
	returnVal = NO;
}

- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *)window{
	return [[self document] undoManager];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	if( [menuItem action] == @selector(newAccount:) || [menuItem action] == @selector(toggleHiddenAccounts:) ){
		return YES;
	} else if( [menuItem action] == @selector(deleteAccount:) || [menuItem action] == @selector(modifyAccount:) ){
		if( [tableView numberOfSelectedRows] == 1 )
			return YES;
		return NO;
	}
	return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
	if( [tableView numberOfSelectedRows] == 1 )
		[modifyButton setEnabled:YES];
	else
		[modifyButton setEnabled:NO];
}

@end
