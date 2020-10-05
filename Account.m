//
//  Account.m
//  Money
//
//  Created by Paul Dorman on 1/2/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Account.h"


@implementation Account

- (id) init{
	self = [super init];
	
	name = @"";
	transactions = [[NSMutableArray alloc] init];
	totals = [[NSMutableArray alloc] init];
	show = YES;
	include = YES;
	
	return self;
}

- (void) dealloc{
	[transactions release];
	[totals release];
	
	[super dealloc];
}

- (void) setName:(NSString *)n{
	[name autorelease];
	name = [n retain];
}

- (NSString *) name{
	return name;
}

- (void) setShow:(BOOL)show{
	self->show = show;
}

- (BOOL) show{
	return show;
}

- (void) setInclude:(BOOL)include{
	self->include = include;
}

- (BOOL) include{
	return include;
}

- (NSMutableArray *) transactions{
	return transactions;
}

- (NSMutableArray *) totals{
	return totals;
}

- (void) recalculateTotals{
	[totals removeAllObjects];
	int j;
	int cents = 0;
	for( j = 0; j < [transactions count]; j++ ){
		cents += ((Transaction*)[transactions objectAtIndex:j])->cents;
		[totals addObject:[NSNumber numberWithInt:cents]];
	}	
}

@end
