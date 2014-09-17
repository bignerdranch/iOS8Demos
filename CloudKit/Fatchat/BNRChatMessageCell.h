//
//  BNRChatMessageCell.h
//  Fatchat
//
//  Created by Steve Sparks on 8/25/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BNRChatMessage;

@interface BNRChatMessageCell : UITableViewCell
@property (strong, nonatomic) BNRChatMessage *message;

@end
