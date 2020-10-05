//
//  Transaction.h
//  Money
//
//  Created by Paul Dorman on 12/18/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//


@interface Transaction : NSObject {
@public
	NSDate *date;
	NSString *account;
	NSString *ref;
	NSString *payee;
	NSString *category;
	NSString *memo;
	BOOL cleared;
	int cents;
}

- (id) initWithString:(NSString *)entry;

// properties
- (NSDate *) date;
- (void) setDate:(NSDate *)date;

- (NSString *) stringValue;

+ (int) valueOfTransactions:(NSArray *)transactions atDate:(NSDate *)date;
+ (int) valueOfTransactions:(NSArray *)transcations;

+ (NSString *) htmlTable:(NSArray *)transactions;

@end