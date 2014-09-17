//
//  UITableViewCell+BNR.m
//
//  Created by Steve Sparks on 6/24/14. Based on work by Adam Preble.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "UITableViewCell+BNRAdditions.h"

@implementation UITableViewCell (BNRAdditions)

+ (instancetype)bnr_instantiateCellFromNib
{
	UINib *nib = [self bnr_nib];
	if (!nib) return nil;
	NSArray *objects = [nib instantiateWithOwner:self options:nil];
	return [objects objectAtIndex:0];
}

+ (UINib *)bnr_nib
{
	NSAssert(self != [UITableViewCell class], @"A root cell class can't have its own nib. Specify manually or subclass.");
	UINib *nib = [UINib nibWithNibName:NSStringFromClass(self) bundle:nil];
	return nib;
}
@end
