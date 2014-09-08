//
//  BNRCloudStore.m
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BNRCloudStore.h"
#import "BNRChatChannel.h"
#import "BNRChatMessage.h"
#import "BNRChannelSubscription.h"

#import <CloudKit/CloudKit.h>

#define LOG_ERROR(__STR__)         if(error) { NSLog(@"Error: %@, op = %@", error.localizedDescription, __STR__); }

#define ONE_SHOT_QUERIES

@interface BNRCloudStore()
@property (strong, nonatomic) CKDatabase *publicDB;
@property (strong, nonatomic) CKRecordZone *publicZone;
@property (strong, nonatomic) CKDiscoveredUserInfo *me;
@property (strong, nonatomic) CKRecordID *myRecordId;
@property (strong, nonatomic) CKRecord *myRecord;
@end

NSString * const ChannelNameKey = @"channelName";
NSString * const ChannelReferenceKey = @"channel";
NSString * const MessageTextKey = @"text";
NSString * const AssetKey = @"asset";
NSString * const AssetTypeKey = @"assetType";
NSString * const MyIdentifierKey = @"myIdentifier";
NSString * const SubscriptionKey = @"subscription";
NSString * const SenderKey = @"sender";
NSString * const DeviceKey = @"device";
NSString * const ServerChangeTokenKey = @"serverChangeToken";

NSString * const ChannelCreateType = @"channel";
NSString * const MessageType = @"message";
NSString * const SubscriptionType = @"subscription";

@interface BNRCloudStore() {
    NSString *_handle;
}
@property (nonatomic) CKApplicationPermissionStatus permissionStatus;
@property (copy, nonatomic) NSArray *channels;
@property (copy, nonatomic) NSArray *subscriptions;
@property (readonly, nonatomic) NSString *deviceId;
@property (nonatomic) CKServerChangeToken *notificationToken;
@end

@implementation BNRCloudStore

+ (instancetype) sharedStore {
    static BNRCloudStore *theStore = nil;
    if(!theStore) {
        theStore = [[BNRCloudStore alloc] init];
    }
    return theStore;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        CKContainer *container = [CKContainer defaultContainer];
        self.publicDB = [container publicCloudDatabase];
        self.publicZone = nil;

        self.handle = [[NSUserDefaults standardUserDefaults] valueForKey:SenderKey];

        [container requestApplicationPermission:CKApplicationPermissionUserDiscoverability completionHandler:^(CKApplicationPermissionStatus status, NSError *error){
            self.permissionStatus = status;

            if(self.permissionStatus == CKApplicationPermissionStatusGranted)
                [self findMeWithCompletion:nil];

            LOG_ERROR(@"requesting application permission");
        }];

        [self findMeWithCompletion:nil];
        // Clean up notes
        [self markNotesRead];
    }
    return self;
}

- (CKDiscoveredUserInfo *)findMeWithCompletion:(void(^)(CKDiscoveredUserInfo*info, NSError *error))completion {
    if(!self.me) {
        CKContainer *container = [CKContainer defaultContainer];

        void(^fetchedMyRecord)(CKRecord *record, NSError *error) = ^(CKRecord *userRecord, NSError *error) {
            LOG_ERROR(@"fetching my own record");
            self.myRecord = userRecord;
            userRecord[@"firstName"] = self.me.firstName;
            userRecord[@"lastName"] = self.me.lastName;
            [self.publicDB saveRecord:userRecord completionHandler:^(CKRecord *record, NSError *error){
                LOG_ERROR(@"attaching my values");
                NSLog(@"Saved record ID %@", record.recordID);
            }];
        };


        void (^discovered)(NSArray *, NSError *) = ^(NSArray *userInfo, NSError *error) {
            LOG_ERROR(@"discovering users");
            CKDiscoveredUserInfo *me = [userInfo firstObject];
            self.myRecordId = me.userRecordID;
            if(me) {
                NSLog(@"Me = %@ %@ %@", me.firstName, me.lastName, me.userRecordID.debugDescription);

                [self.publicDB fetchRecordWithID:self.myRecordId completionHandler:fetchedMyRecord];
            }
            self.me = me;
            // If someone wanted a callback, here's how they get it.
            if(completion) {
                completion(me, error);
            }
        };


        if(self.permissionStatus == CKApplicationPermissionStatusGranted) {
            [container discoverAllContactUserInfosWithCompletionHandler:discovered];
        } else {
            if(completion) {
                completion(self.me, nil);
            }
        }
    } else {
        if(completion) {
            completion(self.me, nil);
        }
    }
    return self.me;
}

- (NSString *)myIdentifier {
    if(!_myIdentifier) {
        _myIdentifier = self.deviceId;
    }
    return _myIdentifier;
}

- (NSString *)handle {
    if(!_handle) {
        if(_me)
            _handle = [NSString stringWithFormat:@"%@ %@", _me.firstName, _me.lastName];
        else
            _handle = [NSString stringWithFormat:@"Anon %06d", (arc4random()%1000000)];
    }
    return _handle;
}

- (NSString *)deviceId {
    static NSString *deviceId = nil;
    if(!deviceId) {
        deviceId = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    }
    return deviceId;
}

- (void)setHandle:(NSString *)handle {
    [[NSUserDefaults standardUserDefaults] setValue:handle forKey:SenderKey];
    _handle = handle;
}

- (CKServerChangeToken *)notificationToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:ServerChangeTokenKey];
    CKServerChangeToken *token = nil;
    if(data) {
        token = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    }
    return token;
}

- (void)setNotificationToken:(CKServerChangeToken *)notificationToken {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:notificationToken];
    [defaults setObject:data forKey:ServerChangeTokenKey];
}

#pragma mark - Channels

/**
 *
 * 1. Channels
 *
 * Let's start with "channels". To create a channel, we save a record to the zone
 * with a RecordType of "channel". Thus searching for channels is querying for this
 * record type. Destroying a channel is simply removing this record, though it should
 * remove the appropriate messages, as well.
 *
 */
- (void)createNewChannel:(NSString *)channelName completion:(void (^)(BNRChatChannel *, NSError *))completion {
    __block BNRChatChannel *channel = [[BNRChatChannel alloc] init];
    channel.name = channelName;

    if([self.channelDelegate respondsToSelector:@selector(cloudStore:shouldCreateChannel:)]) {
        BOOL val = [self.channelDelegate cloudStore:self shouldCreateChannel:channel];
        if(!val)
            return;
    }

    CKRecord *record = [[CKRecord alloc] initWithRecordType:ChannelCreateType];
    record[ChannelNameKey] = channelName;

    [self.publicDB saveRecord:record completionHandler:^(CKRecord *savedRecord, NSError *error){
        LOG_ERROR(@"Creating new channel");

        channel.recordID = savedRecord.recordID;

        if(!savedRecord) {
            channel = nil;
        }

        if(completion) {
            completion(channel, error);
        }
    }];
}

- (void)fetchChannelsWithCompletion:(void (^)(NSArray *, NSError *))completion {

    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:ChannelCreateType predicate:predicate];
    [self.publicDB performQuery:query inZoneWithID:self.publicZone.zoneID completionHandler:^(NSArray *results, NSError *error){
        LOG_ERROR(@"Fetching channels");
        if(results) {
            NSMutableArray *arr = [[NSMutableArray alloc] initWithCapacity:results.count];
            for(CKRecord *record in results) {
                BNRChatChannel *channel = [[BNRChatChannel alloc] init];
                channel.name = [record objectForKey:ChannelNameKey];
                channel.createdDate = record.creationDate;
                channel.recordID = record.recordID;
                [arr addObject:channel];
            }
            // Sort by created date
            self.channels = [arr sortedArrayUsingComparator:^NSComparisonResult(BNRChatChannel *channel1, BNRChatChannel *channel2){
                return [channel1.createdDate compare:channel2.createdDate];
            }]; // property type `copy`
        }
//        completion(self.channels, error);
        [self populateSubscriptionsWithCompletion:completion];
    }];
}

- (void)destroyChannel:(BNRChatChannel *)channel {
    [self unsubscribeFromChannel:channel completion:^(BNRChatChannel *channel, NSError *error){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelName = %@", channel.name];
        CKQuery *query = [[CKQuery alloc] initWithRecordType:ChannelCreateType predicate:predicate];
        [self.publicDB performQuery:query inZoneWithID:self.publicZone.zoneID completionHandler:^(NSArray *results, NSError *error){
            for (CKRecord *record in results) {
                [self.publicDB deleteRecordWithID:record.recordID completionHandler:^(CKRecordID *recordId, NSError *error){
                    LOG_ERROR(@"Deleting channel");
                }];
            }
        }];
    }];


}

- (BNRChatChannel*)channelWithName:(NSString*)name {
    __block BNRChatChannel *ret = nil;
    [self.channels indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
        BNRChatChannel *channel = obj;
        if([channel.name isEqualToString:name]) {
            ret = channel;
            *stop = YES;
            return YES;
        }
        return NO;
    }];
    return ret;
}

#pragma mark - Subscriptions

/**
 *
 * 2. Subscriptions
 *
 * A subscription says "Joe subscribed to channel Blah". The first part of that 
 * is creating a CKSubscription object and registering it with the system.
 * Once that succeeds, we'll stash an info object about our subscription. 
 * This will let people see who is subscribed.
 *
 */


- (CKNotificationInfo *)notificationInfoForChannel:(BNRChatChannel*)channel {
    CKNotificationInfo *note = [[CKNotificationInfo alloc] init];
    note.alertLocalizationKey = @"%@: %@ (in %@)";
    note.alertLocalizationArgs = @[
                                   SenderKey,
                                   MessageTextKey,
                                   ChannelNameKey
                                   ];
    note.shouldBadge = YES;
    note.shouldSendContentAvailable = YES;
    return note;
}

- (void)subscribeToChannel:(BNRChatChannel *)channel completion:(void (^)(BNRChatChannel *, NSError *))completion {
    if(channel.subscribed) {
        if(completion) {
            completion(channel, nil);
        }
        return;
    }

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelName = %@", channel.name];
    CKSubscription *subscription = [[CKSubscription alloc] initWithRecordType:MessageType predicate:predicate options:CKSubscriptionOptionsFiresOnRecordCreation];
    subscription.zoneID = self.publicZone.zoneID;
    subscription.notificationInfo = [self notificationInfoForChannel:channel];

    [self.publicDB saveSubscription:subscription completionHandler:^(CKSubscription *subscription, NSError *error){
        LOG_ERROR(@"subscribing to channel");
        if(subscription) {
            [self recordSubscription:subscription toChannel:channel];
        }
        if(completion) {
            completion(channel, error);
        }
    }];
}

- (void)recordSubscription:(CKSubscription *)subscription toChannel:(BNRChatChannel*)channel {
    CKRecord *record = [[CKRecord alloc] initWithRecordType:SubscriptionType];
    [record setObject:channel.name forKey:ChannelNameKey];
    [record setObject:self.myIdentifier forKey:MyIdentifierKey];
    [record setObject:self.handle forKeyedSubscript:SenderKey];
    [record setObject:self.deviceId forKey:DeviceKey];
    CKReference *channelRef = [[CKReference alloc] initWithRecordID:channel.recordID action:CKReferenceActionDeleteSelf];
    [record setValue:channelRef forKey:ChannelReferenceKey];
    [record setObject:subscription.subscriptionID forKey:SubscriptionKey];

    [self.publicDB saveRecord:record completionHandler:^(CKRecord *record, NSError *error){
        LOG_ERROR(@"recording subscription");
        // This may be the first record a user has created. Let's run the "findMe" logic
        // to ensure that, if we didn't have a user record before, we will now.
        [self findMeWithCompletion:nil];
    }];
}

- (void)populateSubscriptionsWithCompletion:(void(^)(NSArray *, NSError *))completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"device = %@", self.deviceId];
//    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:SubscriptionType predicate:predicate];

    CKQueryOperation *queryOp = [[CKQueryOperation alloc] initWithQuery:query];
    NSMutableArray *subs = [[NSMutableArray alloc] init];
    queryOp.recordFetchedBlock = ^(CKRecord *record) {
        NSString *channelName = [record objectForKey:ChannelNameKey];
        BNRChatChannel *channel = [self channelWithName:channelName];
        channel.subscribed = YES;

        BNRChannelSubscription *sub = [[BNRChannelSubscription alloc] init];
        sub.recordID = record.recordID;
        sub.channel = channel;
        sub.subscription = [record objectForKey:SubscriptionKey];

        [subs addObject:sub];
    };

    queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        LOG_ERROR(@"looking up subscriptions");
        self.subscriptions = [subs copy];
        completion(self.channels, error);
    };

    //    [queryOp start];
#ifdef ONE_SHOT_QUERIES
    [self.publicDB performQuery:query inZoneWithID:self.publicZone.zoneID completionHandler:^(NSArray *results, NSError *error){
        for(CKRecord *record in results) {
            queryOp.recordFetchedBlock(record);
        }
        queryOp.queryCompletionBlock(nil, error);
    }];
#else
    [self.publicDB addOperation:queryOp];
#endif
}

- (BNRChannelSubscription*)subscriptionForChannel:(BNRChatChannel*)channel {
    BNRChannelSubscription *ret = nil;
    for(BNRChannelSubscription *sub in self.subscriptions) {
        BOOL isSame = [sub.channel.name isEqual:channel.name];
        NSLog(@" %@ == %@? %@", sub.channel.name, channel.name, (isSame?@"YES":@"NO"));
        if(isSame) {
            ret = sub;
        }
    }
    return ret;
}

- (void)unsubscribeFromChannel:(BNRChatChannel*)channel completion:(void (^)(BNRChatChannel *, NSError *))completion {
    if(!channel.subscribed) {
        if(completion) {
            completion(channel,nil);
        }
        return;
    }
    channel.subscribed = NO;

    BNRChannelSubscription *sub = [self subscriptionForChannel:channel];
    if(!sub) {
        if(completion) {
            completion(channel,nil);
        }
        return;
    }
    NSMutableArray *arr = [self.subscriptions mutableCopy];
    [arr removeObject:sub];
    self.subscriptions = arr;

    [self.publicDB deleteSubscriptionWithID:sub.subscription completionHandler:^(NSString *subscriptionId, NSError *error){
        LOG_ERROR(@"unsubscribing from channel");
        [self deleteSubscriptionRecord:sub];
        if(completion) {
            completion(channel, error);
        }
    }];
}

- (void)deleteSubscriptionRecord:(BNRChannelSubscription *)channelSubscription {
    [self.publicDB deleteRecordWithID:channelSubscription.recordID completionHandler:^(CKRecordID *id, NSError *error){
        LOG_ERROR(@"removing subscription record");
    }];
}

/**
 *
 * 3. Messages
 *
 * We gotta talk. 
 *
 */

#pragma mark - Messages

- (BNRChatMessage*)messageWithRecord:(CKRecord*)record {
    BNRChatMessage *newMessage = [[BNRChatMessage alloc] init];
    newMessage.message = [record objectForKey:MessageTextKey];
    newMessage.createdDate = record.creationDate;
    newMessage.assetType = [[record objectForKey:AssetTypeKey] integerValue];
    newMessage.senderName = [record objectForKey:SenderKey];
    if(newMessage.assetType != BNRChatMessageAssetTypeNone) {
        newMessage.asset = [record objectForKey:AssetKey];
    }
    newMessage.recordID = record.recordID;
    NSUUID *uuid = [record objectForKey:DeviceKey];
    newMessage.fromThisDevice = [uuid isEqual:self.deviceId];

    return newMessage;
}

- (void)createNewMessageWithText:(NSString *)text assetFileUrl:(NSURL *)assetFileUrl
                       assetType:(BNRChatMessageAssetType)assetType
                         channel:(BNRChatChannel*)channel
                      completion:(void (^)(BNRChatMessage *, NSError *))completion {
    NSParameterAssert(channel);
    NSParameterAssert(text);

    // Create a new CloudKit record of type "message"
    CKRecord *record = [[CKRecord alloc] initWithRecordType:MessageType];

    // Set the basic values
    [record setObject:text forKey:MessageTextKey];
    [record setObject:channel.name forKey:ChannelNameKey];
    [record setObject:self.handle forKey:SenderKey];
    [record setObject:[[UIDevice currentDevice] identifierForVendor].UUIDString forKey:DeviceKey];

    // Make sure the objects delete when the channel record is deleted.
    CKReference *ref = [[CKReference alloc] initWithRecordID:channel.recordID action:CKReferenceActionDeleteSelf];
    [record setObject:ref forKey:ChannelReferenceKey];
    
    // Attach an asset if given one.
    if(assetFileUrl) {
        CKAsset *asset = [[CKAsset alloc] initWithFileURL:assetFileUrl];
        [record setObject:@(assetType) forKey:AssetTypeKey];
        [record setObject:asset forKey:AssetKey];
    }

    BNRChatMessage *message = [self messageWithRecord:record];

    if([self.messageDelegate respondsToSelector:@selector(cloudStore:shouldSendMessage:onChannel:)]) {
        if([self.messageDelegate cloudStore:self shouldSendMessage:message onChannel:channel]) {
            // TODO: call completion
            return;
        }
    }

    [self.publicDB saveRecord:record completionHandler:^(CKRecord *record, NSError *error){
        LOG_ERROR(@"Creating new message");
        if(completion) {
            completion(message, error);
        }
        if(record) {
            if([self.messageDelegate respondsToSelector:@selector(cloudStore:didSendMessage:onChannel:)]) {
                [self.messageDelegate cloudStore:self didSendMessage:message onChannel:channel];
            }
        }
    }];
}

- (void)fetchMessagesForChannel:(BNRChatChannel *)channel completion:(void (^)(NSArray *, NSError *))completion {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channelName = %@", channel.name];
//    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:MessageType predicate:predicate];

    CKQueryOperation *queryOp = [[CKQueryOperation alloc] initWithQuery:query];

    NSMutableArray *arr = [[NSMutableArray alloc] init];

    queryOp.recordFetchedBlock = ^(CKRecord *record) {
        BNRChatMessage *msg = [self messageWithRecord:record];
        [arr addObject:msg];
    };

    queryOp.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        LOG_ERROR(@"fetching messages");
        NSArray *sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(BNRChatMessage*msg1, BNRChatMessage *msg2){
            return [msg1.createdDate compare:msg2.createdDate];
        }];
        completion(sortedArray, error);
    };

#ifdef ONE_SHOT_QUERIES
    [self.publicDB performQuery:query inZoneWithID:self.publicZone.zoneID completionHandler:^(NSArray *results, NSError *error){
        for (CKRecord *record in results) {
            queryOp.recordFetchedBlock(record);
        }
        queryOp.queryCompletionBlock(nil, error);
    }];
#else
    [self.publicDB addOperation:queryOp];
#endif

}

#pragma mark - NSNotification stuff


- (void)markNotesRead {
    CKServerChangeToken *token = self.notificationToken;
    CKFetchNotificationChangesOperation *op = [[CKFetchNotificationChangesOperation alloc] initWithPreviousServerChangeToken:token];

    NSMutableArray *noteIds = [[NSMutableArray alloc] init];
    op.notificationChangedBlock = ^(CKNotification *note) {
        CKNotificationID *noteId = note.notificationID;
        [noteIds addObject:noteId];
    };
    op.fetchNotificationChangesCompletionBlock = ^(CKServerChangeToken *token, NSError *error) {
        LOG_ERROR(@"fetching notifications");
        CKMarkNotificationsReadOperation *mark = [[CKMarkNotificationsReadOperation alloc] initWithNotificationIDsToMarkRead:[noteIds copy]];

        mark.markNotificationsReadCompletionBlock = ^(NSArray *notes, NSError *error){
            LOG_ERROR(@"marking notifications read");
        };
        [mark start];
        self.notificationToken = token;
    };
    [[CKContainer defaultContainer] addOperation:op];

    // set the badge to zero too
    CKModifyBadgeOperation *badgeOp =  [[CKModifyBadgeOperation alloc] initWithBadgeValue:0];
    [[CKContainer defaultContainer] addOperation:badgeOp];
}

- (void)didReceiveNotification:(NSDictionary *)notificationInfo {
    CKNotification *note = [CKQueryNotification notificationFromRemoteNotificationDictionary:notificationInfo];
    if(!note)
        return;

    if([note isKindOfClass:[CKQueryNotification class]]) {
        CKQueryNotification *qNote = (CKQueryNotification*)note;
        [self.publicDB fetchRecordWithID:qNote.recordID completionHandler:^(CKRecord *record, NSError *error){
            BNRChatMessage *msg = [self messageWithRecord:record];
            BNRChatChannel *channel = [self channelWithName:record[@"channelName"]];
            NSLog(@"Notify-> %@ %@  ", note.notificationID.debugDescription, msg.message);
            if([self.messageDelegate respondsToSelector:@selector(cloudStore:didReceiveMessage:onChannel:)]) {

                [self.messageDelegate cloudStore:self didReceiveMessage:msg onChannel:channel];
            } else {
                ;
            }
        }];
    } else {
        NSLog(@"Odd note \"%@\" %@", note.alertBody, note);
    }

//    [self.publicDB fetchRecordWithID:recordId completionHandler:^(CKRecordID *recordId, NSError *error) { }];
}

@end
