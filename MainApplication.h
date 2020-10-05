//
//  MainApplication.h
//  Money
//
//  Created by Paul Dorman on 12/30/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

@interface MainApplication : NSObject {

}

- (IBAction) newTransaction:(id)sender;
- (IBAction) deleteTransactions:(id)sender;
- (IBAction) reconcileTransactions:(id)sender;

- (IBAction) newAccount:(id)sender;
- (IBAction) modifyAccount:(id)sender;
- (IBAction) deleteAccount:(id)sender;

- (IBAction) toggleHiddenAccounts:(id)sender;

- (IBAction) report:(id)sender;

- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;

@end
