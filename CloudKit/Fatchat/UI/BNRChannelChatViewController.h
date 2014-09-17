//
//  BNRChannelChatViewController.h
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BNRChatChannel;
@interface BNRChannelChatViewController : UITableViewController
@property (nonatomic) BNRChatChannel *channel;

- (instancetype)initWithChannel:(BNRChatChannel*)channel;
@end
