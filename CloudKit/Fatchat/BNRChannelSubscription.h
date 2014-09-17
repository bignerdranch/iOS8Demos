//
//  BNRChannelSubscription.h
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BNRChatChannel;
@class CKSubscription;
@class CKRecordID;

@interface BNRChannelSubscription : NSObject
@property (weak, nonatomic) BNRChatChannel *channel;
@property (strong, nonatomic) NSString *subscription;
@property (strong, nonatomic) CKRecordID *recordID;

@end
