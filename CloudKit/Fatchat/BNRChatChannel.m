//
//  BNRChatChannel.m
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRChatChannel.h"

@implementation BNRChatChannel

- (NSUInteger)hash {
    return [self.name hash];
}

- (BOOL)isEqual:(id)object {
    if(![object isKindOfClass:[BNRChatChannel class]]) {
        return NO;
    }
    BNRChatChannel *otherChannel = object;
    return [self.name isEqual:otherChannel.name];
}

@end
