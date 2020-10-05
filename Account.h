//
//  Account.h
//  Money
//
//  Created by Paul Dorman on 1/2/13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "Transaction.h"

@interface Account : NSObject {
	NSString *name;
	NSMutableArray *transactions;
	NSMutableArray *totals;
	BOOL show;
	BOOL include;
}

- (void) setName:(NSString *)name;
- (NSString *) name;
- (BOOL) show;
- (void) setShow:(BOOL)show;
- (BOOL) include;
- (void) setInclude:(BOOL)include;

- (NSMutableArray *) transactions;
- (NSMutableArray *) totals;
- (void) recalculateTotals;

@end
