//
//  MainApplication.m
//  Money
//
//  Created by Paul Dorman on 12/30/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "MainApplication.h"

@implementation MainApplication

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender{
	// don't open a new untitled file at startup
	return NO;
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification{
	NSArray *recentDocuments = [[NSDocumentController sharedDocumentController] recentDocumentURLs];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[recentDocuments objectAtIndex:0] display:YES error:nil];
}

- (IBAction) newTransaction:(id)sender{
	[[[[NSApplication sharedApplication] keyWindow] windowController] newTransaction:sender];
}

- (IBAction) deleteTransactions:(id)sender{
	[[[[NSApplication sharedApplication] keyWindow] windowController] deleteTransaction:sender];
}

- (IBAction) reconcileTransactions:(id)sender{
	[[[[NSApplication sharedApplication] keyWindow] windowController] toggleReconcile:sender];
}

- (IBAction) newAccount:(id)sender{
	[[[[NSApplication sharedApplication] keyWindow] windowController] newAccount:sender];
}

- (IBAction) modifyAccount:(id)sender{
	[[[[NSApplication sharedApplication] keyWindow] windowController] modifyAccount:sender];
}

- (IBAction) deleteAccount:(id)sender{
	[[[[NSApplication sharedApplication] keyWindow] windowController] deleteAccount:sender];
}

- (IBAction) toggleHiddenAccounts:(id)sender{
	[[[[[NSApplication sharedApplication] keyWindow] windowController] document] toggleHiddenAccounts];
}

- (IBAction) report:(id)sender{
	[[[[[NSApplication sharedApplication] keyWindow] windowController] document] report];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	if( [[menuItem title] isEqualToString:@"Report"] )
		return YES;
	
	return [[[[NSApplication sharedApplication] keyWindow] windowController] validateMenuItem:menuItem];
}

@end
