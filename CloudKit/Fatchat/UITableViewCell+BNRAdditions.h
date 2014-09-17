//
//  UITableViewCell+BNR.h
//
//  Created by Steve Sparks on 6/24/14. Based on work by Adam Preble.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableViewCell (BNRAdditions)
+ (instancetype)bnr_instantiateCellFromNib;

+ (UINib *)bnr_nib;
@end
