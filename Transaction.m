//
//  Transaction.m
//  Money
//
//  Created by Paul Dorman on 12/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "Transaction.h"

NSCalendar *gregorian;

@implementation Transaction

+ (void) initialize{
	gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
}

- (void) dealloc{
	[date release];
	[account release];
	[ref release];
	[payee release];
	[memo release];
	[category release];
	
	[super dealloc];
}

- (id) initWithString:(NSString *)entry{
	self = [super init];
	
	NSArray *split = [entry componentsSeparatedByString:@"\t"];
	
	NSString *dateStamp = [split objectAtIndex:0];
	NSArray *dateComps = [dateStamp componentsSeparatedByString:@"/"];
	NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
	[components setMonth:[(NSString*)[dateComps objectAtIndex:0] intValue]];
	[components setDay:[(NSString*)[dateComps objectAtIndex:1] intValue]];
	int year = [[dateComps objectAtIndex:2] intValue];
	if( year < 80 )
		year += 2000;
	else if( year < 100 )
		year += 1900;
	[components setYear:year];
	date = [[gregorian dateFromComponents:components] retain];
	
	account = [[NSString stringWithString:[split objectAtIndex:1]] retain];
	ref = [[NSString stringWithString:[split objectAtIndex:2]] retain];
	payee = [[NSString stringWithString:[split objectAtIndex:3]] retain];
	memo = [[NSString stringWithString:[split objectAtIndex:4]] retain];
	category = [[NSString stringWithString:[split objectAtIndex:5]] retain];
	cleared = [(NSString*)[split objectAtIndex:6] isEqualToString:@"C"] || [(NSString*)[split objectAtIndex:6] isEqualToString:@"R"];
	
	BOOL negative = [(NSString*)[split objectAtIndex:7] hasPrefix:@"-"];
	NSArray *value = [(NSString*)[split objectAtIndex:7] componentsSeparatedByString:@"."];
	NSString *dollarString = [value objectAtIndex:0];
	NSArray *dollarComps = [dollarString componentsSeparatedByString:@","];
	dollarString = [dollarComps objectAtIndex:0];
	int i = 1;
	while( i < [dollarComps count] ){
		dollarString = [dollarString stringByAppendingString:[dollarComps objectAtIndex:i]];
		i++;
	}
	int dollars = [dollarString intValue] * 100;
	cents = dollars + [(NSString*)[value objectAtIndex:1] intValue]*(negative ? -1 : 1);
	
	return self;
}

- (NSString *) stringValue{
	NSMutableString *builder = [NSMutableString stringWithCapacity:100];
	
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
	NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
	[builder appendFormat:@"%02ld/%02ld/%ld\t", (long)[comps month], (long)[comps day], (long)[comps year]];
	
	[builder appendFormat:@"%@\t", account];
	[builder appendFormat:@"%@\t", ref];
	[builder appendFormat:@"%@\t", payee];
	[builder appendFormat:@"%@\t", memo];
	[builder appendFormat:@"%@\t", category];
	[builder appendFormat:@"%@\t", cleared ? @"R" : @""];
	
	BOOL negative = cents < 0;
	int multiplier = negative ? -1 : 1;
	[builder appendFormat:@"%@%d.%02d", negative ? @"-" : @"", (cents/100)*multiplier, (cents%100)*multiplier];
	
	return builder;
}

+ (NSString *) htmlTable:(NSArray *)transactions{
	NSMutableString *builder = [NSMutableString stringWithCapacity:100*[transactions count]];
	
    unsigned unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth |  NSCalendarUnitDay;
	
	[builder appendString:@"<table border=\"1\">\n"];
	[builder appendString:@"<tr><th>Date<th>Account<th>Ref<th>Payee<th>Memo<th>Category<th>Reconciled<th>Amount\n"];
	int i;
	for( i = 0; i < [transactions count]; i++ ){
		Transaction *t = [transactions objectAtIndex:i];
		BOOL negative = t->cents < 0;
		int multiplier = negative ? -1 : 1;
		
		NSDateComponents *comps = [gregorian components:unitFlags fromDate:t->date];

        [builder appendFormat:@"<tr><td>%02ld/%02ld/%ld<td>%@<td>%@<td>%@<td>%@<td>%@<td>%@<td>%@%d.%02d\n",
         (long)[comps month], (long)[comps day], (long)[comps year],
		 t->account, t->ref, t->payee, t->memo, t->category,  t->cleared ? @"R" : @"", 
		 negative ? @"-" : @"", (t->cents/100)*multiplier, (t->cents%100)*multiplier];
	}
	[builder appendString:@"</table>\n"];
	
	return builder;
}

- (NSDate *) date{
	return date;
}

- (void) setDate:(NSDate *)_date{
	[date release];
	date = [_date retain];
}

- (NSString *) description{
	return [NSString stringWithFormat:@"Transaction: %@", [self stringValue]];
}

+ (int) valueOfTransactions:(NSArray *)transactions atDate:(NSDate *)date{
	int cents = 0;
	int i = 0;
	
	for( ; i < [transactions count]; i++ ){
		Transaction *t = [transactions objectAtIndex:i];
		if( [t->date compare:date] == NSOrderedAscending )
			cents += ((Transaction*)[transactions objectAtIndex:i])->cents;
	}
	
	return cents;
}

+ (int) valueOfTransactions:(NSArray *)transactions{
	int cents = 0;
	int i = 0;
	
	for( ; i < [transactions count]; i++ ){
		cents += ((Transaction*)[transactions objectAtIndex:i])->cents;
	}
	
	return cents;
}

@end
