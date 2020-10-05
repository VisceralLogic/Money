//
//  ReportWindow.m
//  Money
//
//  Created by Paul Dorman on 1/19/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "ReportWindow.h"

#import "AccountDocument.h"

@implementation ReportWindow

- (id) init {
	self = [super initWithWindowNibName:@"ReportWindow"];
	return self;
}

- (void) awakeFromNib{
	[beginDate setDateValue:[NSDate date]];
	[endDate setDateValue:[NSDate date]];
}

- (NSString *) windowTitleForDocumentDisplayName:(NSString *)displayName{
	return @"Report";
}

- (void) refresh{
	[accountTable reloadData];
	[categoryTable reloadData];
}

- (NSView *) printView{
	return [[[webView mainFrame] frameView] documentView];
}

- (void) changeDateType:(id)sender{
	if( [[[sender selectedItem] title] isEqualToString:@"Year-to-Date"] ){
		NSDate *date = [NSDate date];
		[endDate setDateValue:date];
		
		NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
		NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
		
		[comps setDay:1];
		[comps setMonth:1];
		
		[beginDate setDateValue:[gregorian dateFromComponents:comps]];
	} else if( [[[sender selectedItem] title] isEqualToString:@"Last Year"] ){
		NSDate *date = [NSDate date];
		
        NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
		NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
		
		[comps setDay:1];
		[comps setMonth:1];
		[comps setYear:[comps year]-1];
		
		[beginDate setDateValue:[gregorian dateFromComponents:comps]];
		
		[comps setDay:31];
		[comps setMonth:12];
		
		[endDate setDateValue:[gregorian dateFromComponents:comps]];
	}
}

- (void) generateReport:(id)sender{
	NSMutableArray *accounts = nil;
	NSMutableArray *categories = nil;
    long lowCents;
    if( [[moreThan stringValue] length] != 0 )
        lowCents = [moreThan floatValue]*100;
    else
        lowCents = NSIntegerMin;
    long highCents;
    if( [[lessThan stringValue] length] != 0 )
        highCents = [lessThan floatValue]*100;
    else
        highCents = NSIntegerMax;
    int cleared = [anyCleared state] == NSControlStateValueOn ? -1 : [yesCleared state] == NSControlStateValueOn ? 0 : 1;
	
	NSIndexSet *set = [accountTable selectedRowIndexes];
	if( ![set containsIndex:0] ){
		NSUInteger index = [set firstIndex];
		accounts = [[[NSMutableArray alloc] init] autorelease];
		NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:@"account"] autorelease];
		do {
			[accounts addObject:[(AccountDocument*)[self document] tableView:nil objectValueForTableColumn:column row:index-1]];
		} while ( (index = [set indexGreaterThanIndex:index]) != NSNotFound );
	}
	
	set = [categoryTable selectedRowIndexes];
	if( ![set containsIndex:0] ){
		NSUInteger index = [set firstIndex];
		categories = [[[NSMutableArray alloc] init] autorelease];
		do {
			[categories addObject:[(AccountDocument*)[self document] comboBox:nil objectValueForItemAtIndex:index]];
		} while ( (index = [set indexGreaterThanIndex:index]) != NSNotFound );
	}
	
	NSArray *transactions = [(AccountDocument*)[self document] filterTransactionsFromAccount:accounts betweenDate:[beginDate dateValue] andDate:[endDate dateValue] inCategories:categories moreThan:lowCents lessThan:highCents payeeContains:[payeeContains stringValue] memoContains:[memoContains stringValue] refContains:[refContains stringValue] isCleared:cleared];

	NSString *total = [NSString stringWithFormat:@"<h3>Total: %@</h3><p>\n", format([Transaction valueOfTransactions:transactions])];
	NSString *htmlTable = [Transaction htmlTable:transactions];
	
	[reportWindow makeKeyAndOrderFront:self];
	[[webView mainFrame] loadHTMLString:[total stringByAppendingString:htmlTable] baseURL:[NSURL fileURLWithPath:@"/"]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
	if( aTableView == accountTable )
		return [(AccountDocument*)[self document] numberOfRowsInTableView:nil] + 1;
	else {
		return [(AccountDocument*)[self document] numberOfItemsInComboBox:nil];
	}

}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if( aTableView == accountTable ){
		if( rowIndex == 0 )
			return @"All Accounts";
		else {
			return [(AccountDocument*)[self document] tableView:nil objectValueForTableColumn:aTableColumn row:rowIndex-1];
		}		
	} else {
		if( rowIndex == 0 )
			return @"All Categories";
		else {
			return [(AccountDocument*)[self document] comboBox:nil objectValueForItemAtIndex:rowIndex];
		}

	}

}

- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
	return NO;
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
	if( [[menuItem title] isEqualToString:@"Date"] )
		return YES;
	if( [[menuItem title] isEqualToString:@"Year-to-Date"] )
		return YES;
	if( [[menuItem title] isEqualToString:@"Last Year"] )
		return YES;
	return NO;
}

@end
