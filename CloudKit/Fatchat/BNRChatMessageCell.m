//
//  BNRChatMessageCell.m
//  Fatchat
//
//  Created by Steve Sparks on 8/25/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRChatMessageCell.h"
#import "BNRChatMessage.h"

@interface BNRChatMessageCell()
@property (weak, nonatomic) IBOutlet UILabel *messageTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *handleLabel;

@end

@implementation BNRChatMessageCell

- (void)layoutSubviews {
    self.messageTextLabel.layer.cornerRadius = 15.0;

    UIColor *color;
    if(self.message.fromThisDevice) {
        color = [UIColor colorWithRed:0.9 green:1.0 blue:0.9 alpha:1.0];
    } else {
        color = [UIColor colorWithRed:0.7 green:0.9 blue:1.0 alpha:1.0];
    }
    self.messageTextLabel.layer.backgroundColor = color.CGColor;
    self.messageTextLabel.layer.borderWidth = 1.0;
    self.messageTextLabel.text = self.message.message;
    self.handleLabel.text = [NSString stringWithFormat:@"- %@", self.message.senderName];
    [super layoutSubviews];
}

@end
