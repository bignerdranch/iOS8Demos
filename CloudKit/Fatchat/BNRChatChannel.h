//
//  BNRChatChannel.h
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNRChatChannel : NSObject
@property (nonatomic) NSString *name;
@property (nonatomic) NSDate *createdDate;

@property (nonatomic) BOOL subscribed;

@property (nonatomic) id recordID;

@end
