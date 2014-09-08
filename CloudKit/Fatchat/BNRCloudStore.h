//
//  BNRCloudStore.h
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BNRChatMessage.h" // need the asset type enum
@class BNRChatChannel;
@class BNRCloudStore;



@protocol BNRCloudStoreChannelDelegate <NSObject>
@optional

- (BOOL) cloudStore:(BNRCloudStore*)store shouldCreateChannel:(BNRChatChannel*)channel;
- (void) cloudStore:(BNRCloudStore*)store didCreateChannel:(BNRChatChannel*)channel;

- (BOOL) cloudStore:(BNRCloudStore*)store shouldSendMessage:(BNRChatMessage*)messge onChannel:(BNRChatChannel*)channel;
- (void) cloudStore:(BNRCloudStore*)store didSendMessage:(BNRChatMessage*)message onChannel:(BNRChatChannel*)channel;

@end

@protocol BNRCloudStoreMessageDelegate <NSObject>
@optional

- (BOOL) cloudStore:(BNRCloudStore*)store shouldSendMessage:(BNRChatMessage*)messge onChannel:(BNRChatChannel*)channel;
- (void) cloudStore:(BNRCloudStore*)store didSendMessage:(BNRChatMessage*)message onChannel:(BNRChatChannel*)channel;
- (void) cloudStore:(BNRCloudStore *)store didReceiveMessage:(BNRChatMessage *)message onChannel:(BNRChatChannel *)channel;

@end

@interface BNRCloudStore : NSObject

@property (copy, nonatomic) NSString *myIdentifier;
@property (copy, nonatomic) NSString *handle;

@property (weak, nonatomic) NSObject<BNRCloudStoreChannelDelegate> *channelDelegate;
@property (weak, nonatomic) NSObject<BNRCloudStoreMessageDelegate> *messageDelegate;

+ (instancetype) sharedStore;


- (void)fetchChannelsWithCompletion:(void(^)(NSArray *channels, NSError *error))completion;
- (void)createNewChannel:(NSString*)channelName completion:(void(^)(BNRChatChannel *newChannel, NSError *error))completion;


- (void)fetchMessagesForChannel:(BNRChatChannel*)channel completion:(void(^)(NSArray *channels, NSError *error))completion;
- (void)createNewMessageWithText:(NSString*)text
                    assetFileUrl:(NSString*)assetFileUrl
                       assetType:(BNRChatMessageAssetType)assetType
                         channel:(BNRChatChannel*)channel
                      completion:(void(^)(BNRChatMessage *newChannel, NSError *error))completion;

- (void)subscribeToChannel:(BNRChatChannel *)channel completion:(void(^)(BNRChatChannel *channel, NSError *error))completion;
- (void)unsubscribeFromChannel:(BNRChatChannel*)channel completion:(void(^)(BNRChatChannel *channel, NSError *error))completion;
;


- (void)destroyChannel:(BNRChatChannel *)channel;

// "Message for you, sir!"
- (void)didReceiveNotification:(NSDictionary*)notificationInfo;

@end
