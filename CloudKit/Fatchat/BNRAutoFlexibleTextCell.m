//
//  BNRAutoFlexibleTextCell.m
//  Fatchat
//
//  Created by Steve Sparks on 8/25/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRAutoFlexibleTextCell.h"

NSString *const BNRAutoFlexibleTextCellIdentifier = @"BNRAutoFlexibleTextCell";

@interface BNRAutoFlexibleTextCell ()

@property (nonatomic, weak, readwrite) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *descriptionLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleLabelHeight;

@property (nonatomic, strong) IBOutletCollection(NSLayoutConstraint) NSArray *labelsHorizontalMargins;
@property (nonatomic, strong) NSArray *labelsCenterX;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *interLabelGap;
@property (nonatomic, strong) NSLayoutConstraint *titleLabelCenterY;
@property (nonatomic, strong) NSLayoutConstraint *descriptionLabelCenterY;

@property (nonatomic) BOOL hidesTitleLabel;
@property (nonatomic) BOOL hidesDescriptionLabel;

@end

static void *BNRAutoFlexibleTitleLabelContext = &BNRAutoFlexibleTitleLabelContext;
static void *BNRAutoFlexibleDescriptionLabelContext = &BNRAutoFlexibleDescriptionLabelContext;

@implementation BNRAutoFlexibleTextCell

- (void)awakeFromNib
{
	self.titleLabel.text = nil;
	self.descriptionLabel.text = nil;

	[self addObserver:self forKeyPath:@"titleLabel.text" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:BNRAutoFlexibleTitleLabelContext];
	[self addObserver:self forKeyPath:@"descriptionLabel.text" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:BNRAutoFlexibleDescriptionLabelContext];

	self.labelsCenterX = @[
		[NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
		[NSLayoutConstraint constraintWithItem:self.descriptionLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]
	];
	self.titleLabelCenterY = [NSLayoutConstraint constraintWithItem:self.titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
	self.descriptionLabelCenterY = [NSLayoutConstraint constraintWithItem:self.descriptionLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.contentView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"titleLabel.text" context:BNRAutoFlexibleTitleLabelContext];
	[self removeObserver:self forKeyPath:@"descriptionLabel.text" context:BNRAutoFlexibleDescriptionLabelContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == BNRAutoFlexibleTitleLabelContext) {
		NSString *newTitleText = change[NSKeyValueChangeNewKey];
		self.hidesTitleLabel = ([newTitleText isEqual:[NSNull null]] || (newTitleText.length == 0));
		return;
	} else if (context == BNRAutoFlexibleDescriptionLabelContext) {
		NSString *newText = change[NSKeyValueChangeNewKey];
		self.hidesDescriptionLabel = ([newText isEqual:[NSNull null]] || (newText.length == 0));
		return;
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setHidesTitleLabel:(BOOL)hidesTitleLabel
{
	if (_hidesTitleLabel == hidesTitleLabel)
		return;

	_hidesTitleLabel = hidesTitleLabel;

	self.titleLabel.hidden = _hidesTitleLabel;

	[self setNeedsUpdateConstraints];
}

- (void)setHidesDescriptionLabel:(BOOL)hidesDescriptionLabel
{
	if (_hidesDescriptionLabel == hidesDescriptionLabel)
		return;

	_hidesDescriptionLabel = hidesDescriptionLabel;

	self.descriptionLabel.hidden = _hidesDescriptionLabel;

	[self setNeedsUpdateConstraints];
}

- (void)setCentered:(BOOL)centered
{
	if (_centered == centered)
		return;

	_centered = centered;

	[self setNeedsUpdateConstraints];
}

- (void)updateConstraints
{
	[super updateConstraints];
	
	if (self.centered) {
		[self.contentView removeConstraints:self.labelsHorizontalMargins];
		[self.contentView addConstraints:self.labelsCenterX];
	} else {
		[self.contentView removeConstraints:self.labelsCenterX];
		[self.contentView addConstraints:self.labelsHorizontalMargins];
	}
	
	BOOL hidesTitleLabel = (self.hidesTitleLabel || !self.titleLabel.text.length);
	BOOL hidesDescriptionLabel = (self.hidesDescriptionLabel || !self.descriptionLabel.text.length);
	
	if (hidesTitleLabel) {
		[self.contentView removeConstraint:self.interLabelGap];
		[self.contentView addConstraint:self.descriptionLabelCenterY];
	} else {
		[self.contentView removeConstraint:self.descriptionLabelCenterY];
	}
	
	if (self.hidesDescriptionLabel || !self.descriptionLabel.text.length) {
		[self.contentView removeConstraint:self.interLabelGap];
		[self.contentView addConstraint:self.titleLabelCenterY];
	} else {
		[self.contentView removeConstraint:self.titleLabelCenterY];
	}
	
	if (!hidesTitleLabel && !hidesDescriptionLabel) {
		[self.contentView addConstraint:self.interLabelGap];
	}
}


#pragma mark - Sizing

- (CGFloat)minimumHeightForTableView:(UITableView *)tableView
{
    UITableViewCellSeparatorStyle style;
    CGFloat width;
    if (tableView) {
        style = tableView.separatorStyle;
        width = tableView.frame.size.width;
    } else {
        style = UITableViewCellSeparatorStyleNone;
        width = 0;
    }
    return [self minimumHeightForMinimumWidth:width separatorStyle:style] + (self.verticalPadding * 2.0);
}

+ (NSString *)keyPathOfSubviewForUpdatingLayoutWidth
{
    return @"contentView";
}

- (CGFloat)minimumHeightForMinimumWidth:(CGFloat)width separatorStyle:(UITableViewCellSeparatorStyle)style
{
    // Configure the layout width for labels using their prototype width
    if (CGRectGetWidth(self.contentView.bounds) != width) {
        self.contentView.frame = CGRectMake(0, 0, width, 1000);
        [self.contentView layoutIfNeeded];

        for (UIView *view in self.subviews) {
            if([view isKindOfClass:[UILabel class]]) {
                UILabel *label = (UILabel*)view;
                [label setPreferredMaxLayoutWidth:fminf(width, label.bounds.size.width)];
            }
        }
    }

    // Actually get autolayout to calculate the value
    [self updateConstraintsIfNeeded];
    CGSize min = [self.contentView systemLayoutSizeFittingSize:CGSizeMake(width, 0)];
    CGFloat height = min.height;

    // Adjust for native separators
    if (self.bounds.size.height > self.contentView.bounds.size.height > 0 || style) {
        height += 1;
    }
    
    return height;
}
@end
