//
//  MyDocument.h
//  Money
//
//  Created by Paul Dorman on 12/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Transaction.h"
#import "AccountsWindow.h"
#import "TransactionsWindow.h"
#import "Account.h"
#import "ReportWindow.h"


@interface AccountDocument : NSDocument
{
	NSMutableDictionary *accounts;	// each account is array of Transaction
	
	NSMutableDictionary *openAccountWindows;
	
	NSMutableArray *categories;		// currently defined categories
	
	NSTextField *total;
	
	AccountsWindow *accountWindow;
	
	ReportWindow *reportWindow;
	
	bool showHidden;
}

- (void) newAccount;
- (BOOL) modifyAccount:(NSUInteger)row;
- (void) deleteAccount:(NSUInteger)row;

// alert delegate for deleteAccount
- (void) deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (void) toggleHiddenAccounts;
- (NSArray *) visibleAccounts;

- (void) loadTransaction:(Transaction *)t;

- (void) openAccount:(NSInteger)row;
- (NSString *) accountName:(TransactionsWindow *)window;
- (BOOL) closeAccountWindow:(TransactionsWindow *)window;
- (void) associateTableView:(NSTableView *)aTableView withAccount:(TransactionsWindow *)window;
- (Transaction *) getTransaction:(NSInteger)row forAccount:(TransactionsWindow *)window;
- (Account *) accountForWindow:(TransactionsWindow *)window;
- (void) deleteTransaction:(NSInteger)row fromAccount:(TransactionsWindow *)window;
- (void) deleteTransaction:(Transaction *)t;
- (void) addTransaction:(Transaction *)transaction;
- (void) replaceTransaction:(NSInteger)row fromAccount:(TransactionsWindow *)window withTransaction:(Transaction *)transaction;

- (void) recalculateTotalsForAccount:(NSString *)account;

/*
 * accountNames = NSArray<NSString*> (or nil for all)
 * categories = NSArray<NSString*> (or nil for all)
 * isCleared = 0: must be cleared, 1: must not be cleared, -1: don't care
 */
- (NSArray *) filterTransactionsFromAccount:(NSArray *)accountNames betweenDate:(NSDate *)startDate andDate:(NSDate *)endDate
							   inCategories:(NSArray *)categories moreThan:(long)lowCents lessThan:(long)highCents
							  payeeContains:(NSString *)payee memoContains:(NSString *)memo refContains:(NSString *)ref
								  isCleared:(int)cleared;

- (void) report;

// AccountsWindow table view protocols
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;

- (void) formatCell:(NSTextFieldCell*)cell atColumn:(NSTableColumn*)column row:(NSInteger)row;

- (void) setTotalField:(NSTextField*)total;

// Transaction combo box protocols
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)aComboBox;
- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index;
- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString;
- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString;

@end

NSString *format(int cents);
NSString *formatDate(NSDate *date);
