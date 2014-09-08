//
//  BNRAutoFlexibleTextCell.h
//  Fatchat
//
//  Created by Steve Sparks on 8/25/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const BNRAutoFlexibleTextCellIdentifier;

@interface BNRAutoFlexibleTextCell : UITableViewCell

@property (nonatomic, weak, readonly) UILabel *titleLabel;
@property (nonatomic, weak, readonly) UILabel *descriptionLabel;

/**
 If YES the text will be wrapped as necessary and then
 centered within the cell.  If NO, the left margin will
 be maintained.

 centered=NO:

 | The quick brown fox sailed down the     |
 | Mississippi river.                      |

 centered=YES:

 |   The quick brown fox sailed down the   |
 |   Mississippi river.                    |

 Defaults to NO.
 */
@property (nonatomic) BOOL centered;

/* A quick way to add some padding to the top and bottom of the
 * flexible cell. */
@property (nonatomic) CGFloat verticalPadding;

@end
