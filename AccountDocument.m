//
//  MyDocument.m
//  Money
//
//  Created by Paul Dorman on 12/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "AccountDocument.h"

NSNumberFormatter *nf;
NSDateFormatter *df;

NSString *format(int cents){
	return [nf stringFromNumber:[NSNumber numberWithFloat:cents/100+.01*(cents%100)]];	
}

NSString *formatDate(NSDate *date){
	return [df stringFromDate:date];
}

@implementation AccountDocument

+ (void) initialize{
	nf = [[NSNumberFormatter alloc] init];
	[nf setFormatterBehavior:NSNumberFormatterBehavior10_4];
	[nf setNumberStyle:NSNumberFormatterCurrencyStyle];
	df = [[NSDateFormatter alloc] init];
	[df setDateStyle:NSDateFormatterShortStyle];
	[df setTimeStyle:NSDateFormatterNoStyle];
}

- (id)init{
    self = [super init];
    
	accounts = [[NSMutableDictionary alloc] init];
	
	openAccountWindows = [[NSMutableDictionary alloc] init];
	
	categories = [[NSMutableArray alloc] init];
	
	showHidden = NO;

    return self;
}

- (void)makeWindowControllers{
	accountWindow = [[AccountsWindow alloc] init];
	[accountWindow setShouldCloseDocument:YES];
	[self addWindowController:accountWindow];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError{
    if( [typeName isEqualToString:@"Transaction File"] ){
		NSMutableString *text = [[[NSMutableString alloc] init] autorelease];
		NSArray *values = [accounts allValues];
		int i;
		for( i = 0; i < [values count]; i++ ){
			NSArray *transactions = [[values objectAtIndex:i] transactions];
			int j;
			for( j = 0; j < [transactions count]; j++ ){
				[text appendFormat:@"%@\n", [[transactions objectAtIndex:j] stringValue]];
			}
		}
		NSRange range;
		range.location = [text length]-1;
		range.length = 1;
		[text deleteCharactersInRange:range];
		return [NSData dataWithBytes:[text UTF8String] length:[text lengthOfBytesUsingEncoding:NSUTF8StringEncoding]];
	} else if( [typeName isEqualToString:@"Money File"] ){
		NSMutableDictionary *pList = [[[NSMutableDictionary alloc] init] autorelease];
		NSString *transactions = [[[NSString alloc] initWithData:[self dataOfType:@"Transaction File" error:NULL] encoding:NSUTF8StringEncoding] autorelease];
		[pList setObject:transactions forKey:@"Transactions"];
		NSMutableDictionary *data = [[[NSMutableDictionary alloc] init] autorelease];
		[pList setObject:data forKey:@"Accounts"];
		int i;
		NSArray *array = [accounts allValues];
		for( i = 0; i < [array count]; i++ ){
			NSMutableDictionary *dict = [[[NSMutableDictionary alloc] init] autorelease];
			Account *account = [array objectAtIndex:i];
			[data setObject:dict forKey:[account name]];
			[dict setObject:[NSNumber numberWithBool:[account show]] forKey:@"Show"];
			[dict setObject:[NSNumber numberWithBool:[account include]] forKey:@"Include"];
		}
		
		return [NSPropertyListSerialization dataFromPropertyList:pList format:NSPropertyListXMLFormat_v1_0 errorDescription:nil];
	}
	
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError{
	if( [typeName isEqualToString:@"Transaction File"] ){
		NSString *contents = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		NSArray *entries = [contents componentsSeparatedByString:@"\n"];
		
		int i;
		for( i = 0; i < [entries count]; i++ ){
			Transaction *t = [[[Transaction alloc] initWithString:[entries objectAtIndex:i]] autorelease];
			if( !t )
				return NO;
			[self loadTransaction:t];
		}
		
		// all transactions have been read, ensure they are ordered by date
		NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
		NSEnumerator *keys = [accounts keyEnumerator];
		NSString *key;
		while( key = [keys nextObject] ){
			[[(Account*)[accounts objectForKey:key] transactions] sortUsingDescriptors:[NSArray arrayWithObject:sort]];
			[(Account*)[accounts objectForKey:key] recalculateTotals];
			NSString *transferAccount = [NSString stringWithFormat:@"[%@]", key];
			// add account transfers to categories
			if( ![categories containsObject:transferAccount] )
				[categories addObject:transferAccount];
		}
		[categories sortUsingSelector:@selector(compare:)];	
	} else if( [typeName isEqualToString:@"Money File"] ){
		NSMutableDictionary *pList = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:NULL errorDescription:NULL];
		
		NSDictionary *data = [pList objectForKey:@"Accounts"];
		NSArray *array = [data allKeys];
		int i;
		for( i = 0; i < [array count]; i++ ){
			Account *account = [[Account alloc] init];
			NSString *name = [array objectAtIndex:i];
			NSDictionary *dict = [data objectForKey:name];
			[account setName:name];
			[account setShow:[[dict objectForKey:@"Show"] boolValue]];
			[account setInclude:[[dict objectForKey:@"Include"] boolValue]];
			[accounts setObject:account forKey:name];
		}
		
		NSString *transactions = [pList objectForKey:@"Transactions"];
		[self readFromData:[NSData dataWithBytes:[transactions UTF8String] length:[transactions lengthOfBytesUsingEncoding:NSUTF8StringEncoding]] ofType:@"Transaction File" error:outError];
	}
	
	return YES;
}

- (void) loadTransaction:(Transaction *)t{
	Account *account = [accounts objectForKey:t->account];
	if( !account ) {
		account = [[Account alloc] init];
		[account setName:t->account];
		[accounts setObject:account forKey:t->account];
	}
	[[account transactions] addObject:t];
	if( ![categories containsObject:t->category] )
		[categories addObject:t->category];
}


- (void) newAccount{
	Transaction *t = [[[Transaction alloc] init] autorelease];
	t->account = @"";
	t->date = [[NSDate date] retain];
	t->ref = @"";
	t->payee = @"Opening Balance";
	t->cleared = NO;
	t->category = @"[]";
	t->memo = @"";
	t->cents = 0;
	[self loadTransaction:t];
	
	if( [self modifyAccount:0] ){
		[accountWindow refresh];
		
		//[[self undoManager] setActionName:@"New Account"];
	}
	else
		[accounts removeObjectForKey:@""];
}

- (NSArray *) visibleAccounts{
	NSMutableArray *array = [NSMutableArray arrayWithArray:[accounts allKeys]];
	[array sortUsingSelector:@selector(compare:)];
	if( !showHidden ){
		int i;
		for( i = 0; i < [array count]; i++ ){
			Account *account = [accounts objectForKey:[array objectAtIndex:i]];
			if( ![account show] )
				[array removeObjectAtIndex:i--];
		}		
	}

	return array;
}

- (BOOL) modifyAccount:(NSUInteger)row{
	NSArray *array = [self visibleAccounts];	
	Account *account = [accounts objectForKey:[array objectAtIndex:row]];
	NSString *name = [[account name] retain];
	if( [accountWindow modifyThisAccount:account] ){
		[accounts removeObjectForKey:name];
		[accounts setObject:account forKey:[account name]];
		
		NSString *newCategory = [NSString stringWithFormat:@"[%@]", [account name]];
		NSString *oldCategory = [NSString stringWithFormat:@"[%@]", name];
		[categories removeObject:oldCategory];
		[categories addObject:newCategory];
		[categories sortUsingSelector:@selector(compare:)];
		
		int i;
		NSArray *allAccounts = [accounts allValues];
		for( i = 0; i < [allAccounts count]; i++ ){
			int j;
			NSArray *transactions = [[allAccounts objectAtIndex:i] transactions];
			for( j = 0; j < [transactions count]; j++ ){
				Transaction *t = [transactions objectAtIndex:j];
				if( [t->category isEqualToString:oldCategory] ){
					[t->category autorelease];
					t->category = [newCategory retain];
				}
			}
		}
		
		NSArray *windows = [openAccountWindows allKeys];
		for( i = 0; i < [windows count]; i++ ){
			[(TransactionsWindow*)[[windows objectAtIndex:i] longValue] refresh];
		}
		
		[accountWindow refresh];
		[self setTotalField:total];
		[name release];
		return YES;
	}
	[name release];
	return NO;
}

- (void) deleteAccount:(NSUInteger)row{
	NSArray *array = [self visibleAccounts];
	NSString *name = [array objectAtIndex:row];
	NSAlert *alert = [NSAlert alertWithMessageText:@"Delete Account?" defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:[NSString stringWithFormat:@"Do you want to delete the account: %@?", name]];
	[alert beginSheetModalForWindow:[accountWindow window] modalDelegate:self didEndSelector:@selector(deleteAlertDidEnd:returnCode:contextInfo:) contextInfo:name];
}

- (void) deleteAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo{
	if( returnCode != NSAlertDefaultReturn )
		return;

	[accounts removeObjectForKey:(NSString*)contextInfo];
	NSString *category = [NSString stringWithFormat:@"[%@]", (NSString*)contextInfo];
	
	int i;
	NSArray *allAccounts = [accounts allValues];
	for( i = 0; i < [allAccounts count]; i++ ){
		int j;
		NSMutableArray *transactions = [[allAccounts objectAtIndex:i] transactions];
		for( j = 0; j < [transactions count]; j++ ){
			Transaction *t = [transactions objectAtIndex:j];
			if( [t->category isEqualToString:category] ){
				[transactions removeObjectAtIndex:j--];
			}
		}
		[[allAccounts objectAtIndex:i] recalculateTotals];
	}
	
	NSArray *windows = [openAccountWindows allKeys];
	for( i = 0; i < [windows count]; i++ ){
		if( [[[openAccountWindows objectForKey:[windows objectAtIndex:i]] objectForKey:@"Name"] isEqualToString:(NSString*)contextInfo] )
			 [(TransactionsWindow*)[[windows objectAtIndex:i] longValue] close];
		else
			 [(TransactionsWindow*)[[windows objectAtIndex:i] longValue] refresh];
	}
	
	[accountWindow refresh];
	[self setTotalField:total];
}

- (NSArray *) filterTransactionsFromAccount:(NSArray *)accountNames betweenDate:(NSDate *)startDate andDate:(NSDate *)endDate
							   inCategories:(NSArray *)categories moreThan:(long)lowCents lessThan:(long)highCents
							  payeeContains:(NSString *)payee memoContains:(NSString *)memo refContains:(NSString *)ref
								  isCleared:(int)cleared{
	
	NSMutableArray *results = [[[NSMutableArray alloc] init] autorelease];
	
	if( !accountNames ){
		accountNames = [accounts allKeys];
	}
	
	if( !categories ){
		categories = self->categories;
	}

	int i;
	for( i = 0; i < [accountNames count]; i++ ){
		[results addObjectsFromArray:[[accounts objectForKey:[accountNames objectAtIndex:i]] transactions]];
	}		
	
	
	for( i = 0; i < [results count]; i++ ){
		Transaction *t = [results objectAtIndex:i];
		
		NSComparisonResult order;
		if( ((order = [t->date compare:startDate]) == NSOrderedAscending) ||	// TODO: may return true if dates are same
		   ((order = [t->date compare:endDate]) == NSOrderedDescending) ){
			[results removeObjectAtIndex:i--];
			continue;
		}
		
		if( ![categories containsObject:t->category] ){
			[results removeObjectAtIndex:i--];
			continue;
		}
		
		if( t->cents < lowCents || t->cents > highCents ){
			[results removeObjectAtIndex:i--];
			continue;
		}
		
		if( [payee length] > 0 && [t->payee rangeOfString:payee options:NSCaseInsensitiveSearch].location == NSNotFound){
			[results removeObjectAtIndex:i--];
			continue;
		}
		
		if( [memo length] > 0 && [t->memo rangeOfString:memo options:NSCaseInsensitiveSearch].location == NSNotFound ){
			[results removeObjectAtIndex:i--];
			continue;
		}
		
		if( [ref length] > 0 && [t->ref rangeOfString:ref options:NSCaseInsensitiveSearch].location == NSNotFound ){
			[results removeObjectAtIndex:i--];
			continue;
		}
		
		if( (cleared == 0 && !t->cleared) || (cleared == 1 && t->cleared) ){
			[results removeObjectAtIndex:i--];
			continue;
		}
	}
	
	return results;
}

- (void) report{
	if( !reportWindow ){
		reportWindow = [[ReportWindow alloc] init];
		[self addWindowController:reportWindow];
		[reportWindow showWindow:self];	
	} else {
		[reportWindow showWindow:self];
		[reportWindow refresh];
	}
}

#pragma mark Category Combo Box

- (NSInteger) numberOfItemsInComboBox:(NSComboBox *)aComboBox{
	return [categories count];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(NSInteger)index{
	return [categories objectAtIndex:index];
}

- (NSUInteger)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString{
	return [categories indexOfObject:aString];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString{
	int i;
	for( i = 0; i < [categories count]; i++ ){
		NSString *category = [categories objectAtIndex:i];
		if( [category rangeOfString:uncompletedString options:(NSAnchoredSearch|NSCaseInsensitiveSearch)].location == 0 )
			return category;
	}
	return uncompletedString;
}

#pragma mark Account Windows

- (void) openAccount:(NSInteger)row{
	NSArray *array = [self visibleAccounts];
	NSString *accountName = [array objectAtIndex:row];
	BOOL found = NO;
	NSEnumerator *keys = [openAccountWindows keyEnumerator];
	NSNumber *key;
	while( key = [keys nextObject] ){
		if( [(NSString*)[(NSDictionary*)[openAccountWindows objectForKey:key] objectForKey:@"Name"] isEqualToString:accountName] ){
			[(TransactionsWindow*)[key longValue] showWindow:self];
			found = YES;
			break;
		}
	}
	if( !found ){
		TransactionsWindow *window = [[TransactionsWindow alloc] init];
		NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
		[dict setObject:accountName forKey:@"Name"];
		[openAccountWindows setObject:dict forKey:[NSNumber numberWithLong:(long)window]];
		
		[self addWindowController:window];
		[window showWindow:self];			
	}
}

- (NSString *) accountName:(TransactionsWindow *)window{
	return [[openAccountWindows objectForKey:[NSNumber numberWithLong:(long)window]] objectForKey:@"Name"];
}

- (Transaction *) getTransaction:(NSInteger)row forAccount:(TransactionsWindow *)window{
	return [[[accounts objectForKey:[self accountName:window]] transactions] objectAtIndex:row];
}

- (Account *) accountForWindow:(TransactionsWindow *)window{
	return [accounts objectForKey:[self accountName:window]];
}

- (void) deleteTransaction:(NSInteger)row fromAccount:(TransactionsWindow *)window{
	NSMutableArray *transactions = [[accounts objectForKey:[self accountName:window]] transactions];
	[self deleteTransaction:[transactions objectAtIndex:row]];
}

- (void) deleteTransaction:(Transaction *)t{
	[t retain];
	NSMutableArray *transactions = [[accounts objectForKey:t->account] transactions];
	[transactions removeObject:t];
	[self recalculateTotalsForAccount:t->account];
	
	// remove linked transaction from corresponding account
	if( [t->category hasPrefix:@"["] && ![t->category isEqualToString:[NSString stringWithFormat:@"[%@]", t->account]] ){
		NSString *accountName = [[t->category stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] retain];
		transactions = [[accounts objectForKey:accountName] transactions];
		int i;
		for( i = 0; i < [transactions count]; i++ ){
			Transaction *t2 = [transactions objectAtIndex:i];
			if( [t2->category isEqualToString:[NSString stringWithFormat:@"[%@]", t->account]] &&
			   [t2->date isEqualToDate:t->date] &&
			   [t2->payee isEqualToString:t->payee] &&
			   [t2->ref isEqualToString:t->ref] &&
			   [t2->memo isEqualToString:t->memo] &&
			   t2->cleared == t->cleared &&
			   t2->cents == - t->cents ){
				[transactions removeObjectAtIndex:i];
				break;
			}
		}
		[self recalculateTotalsForAccount:accountName];
		
		// refresh window if it's open
		NSEnumerator *keys = [openAccountWindows keyEnumerator];
		NSNumber *key;
		while( key = [keys nextObject] ){
			if( [(NSString*)[(NSDictionary*)[openAccountWindows objectForKey:key] objectForKey:@"Name"] isEqualToString:accountName] ){
				[(TransactionsWindow*)[key longValue] refresh];
				break;
			}
		}			
	}
	
	[[[self undoManager] prepareWithInvocationTarget:self] addTransaction:t];
	[[self undoManager] setActionName:@"Delete Transaction"];
	
	[t release];
	
	[accountWindow refresh];
	[self setTotalField:total];
	
}

- (void) addTransaction:(Transaction *)t{
	[[(Account*)[accounts objectForKey:t->account] transactions] addObject:t];
	NSSortDescriptor *sort = [[[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES] autorelease];
	[[(Account*)[accounts objectForKey:t->account] transactions] sortUsingDescriptors:[NSArray arrayWithObject:sort]];		
	[self recalculateTotalsForAccount:t->account];
	if( ![categories containsObject:t->category] ){
		[categories addObject:t->category];
		[categories sortUsingSelector:@selector(compare:)];
	}
	
	// refresh window if it's open
	NSEnumerator *keys = [openAccountWindows keyEnumerator];
	NSNumber *key;
	while( key = [keys nextObject] ){
		if( [(NSString*)[(NSDictionary*)[openAccountWindows objectForKey:key] objectForKey:@"Name"] isEqualToString:t->account] ){
			[(TransactionsWindow*)[key longValue] refresh];
			break;
		}
	}		
	
	// make a linked transaction in the corresponding account
	if( [t->category hasPrefix:@"["]  && ![t->category isEqualToString:[NSString stringWithFormat:@"[%@]", t->account]] ){
		NSString *accountName = [[t->category stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]] retain];
		Transaction *t2 = [[[Transaction alloc] init] autorelease];
		
		t2->account = accountName;
		t2->payee = [t->payee retain];
		t2->memo = [t->memo retain];
		t2->ref = [t->ref retain];
		t2->date = [t->date retain];
		t2->cleared = t->cleared;
		t2->cents = - t->cents;
		t2->category = [[NSString stringWithFormat:@"[%@]", t->account] retain];
		
		[[(Account*)[accounts objectForKey:t2->account] transactions] addObject:t2];
		[[(Account*)[accounts objectForKey:t2->account] transactions] sortUsingDescriptors:[NSArray arrayWithObject:sort]];
		[self recalculateTotalsForAccount:t2->account];
		
		// refresh window if it's open
		NSEnumerator *keys = [openAccountWindows keyEnumerator];
		NSNumber *key;
		while( key = [keys nextObject] ){
			if( [(NSString*)[(NSDictionary*)[openAccountWindows objectForKey:key] objectForKey:@"Name"] isEqualToString:t2->account] ){
				[(TransactionsWindow*)[key longValue] refresh];
				break;
			}
		}		
	}
	
	[[[self undoManager] prepareWithInvocationTarget:self] deleteTransaction:t];
	[[self undoManager] setActionName:@"Add Transaction"];
	
	[accountWindow refresh];
	[self setTotalField:total];
}

- (void) replaceTransaction:(NSInteger)row fromAccount:(TransactionsWindow *)window withTransaction:(Transaction *)transaction{
	[self deleteTransaction:row fromAccount:window];
	[self addTransaction:transaction];
}

- (void) recalculateTotalsForAccount:(NSString *)account{
	[[accounts objectForKey:account] recalculateTotals];
}

- (BOOL) closeAccountWindow:(TransactionsWindow *)window{
	[openAccountWindows removeObjectForKey:[NSNumber numberWithLong:(long)window]];
	return YES;
}

- (void) associateTableView:(NSTableView *)aTableView withAccount:(TransactionsWindow *)window{
	NSMutableDictionary *dict = [openAccountWindows objectForKey:[NSNumber numberWithLong:(long)window]];
	[dict setObject:[NSNumber numberWithLong:(long)aTableView] forKey:@"TableView"];
}

- (void) toggleHiddenAccounts{
	showHidden = !showHidden;
	[accountWindow refresh];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
	if( showHidden )
		return [accounts count];
	
	return [[self visibleAccounts] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	NSArray *array = [self visibleAccounts];
	NSString *account = [array objectAtIndex:rowIndex];
	if( [(NSString*)[aTableColumn identifier] isEqualToString:@"account"] )
		return account;
	else if( [(NSString*)[aTableColumn identifier] isEqualToString:@"value"] )
		return format([[[[accounts objectForKey:account] totals] lastObject] intValue]);
	else
		return [NSString stringWithFormat:@"Value: %d", rowIndex];;
}

- (void) formatCell:(NSTextFieldCell *)cell atColumn:(NSTableColumn *)column row:(NSInteger)row{
	NSArray *array = [self visibleAccounts];
	NSString *name = [array objectAtIndex:row];
	Account *account = [accounts objectForKey:name];
	
	if( [account show] )
		[cell setTextColor:[NSColor blackColor]];
	else
		[cell setTextColor:[NSColor grayColor]];
	
	if( ![account include] )
		[cell setStringValue:[NSString stringWithFormat:@"\t%@", [cell stringValue]]];
}

- (void) setTotalField:(NSTextField*)totalField{
	total = totalField;
	
	int cents = 0;
	int i;
	for( i = 0; i < [accounts count]; i++ ){
		Account *account = [[accounts allValues] objectAtIndex:i];
		if( [account include] )
			cents += [[[account totals] lastObject] intValue];
	}
	
	[total setStringValue:format(cents)];
}

- (void) printDocument:(id)sender{
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:[[[[NSApplication sharedApplication] keyWindow] windowController] printView] printInfo:[self printInfo]];
	[op runOperation];
}

@end
