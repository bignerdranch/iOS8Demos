//
//  BNRCoreDataCoordinator.m
//  CoreDataBatching
//
//  Created by Robert Edwards on 8/27/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRCoreDataCoordinator.h"

#import "Entity.h"
#import "BNRTimeBlock.h"

static NSUInteger const BNRCoreDataBatchingInitialSize = 250000;

@interface BNRCoreDataCoordinator()

@end

@implementation BNRCoreDataCoordinator

@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

#pragma mark - Batch Updating

- (void)batchUpdateAllEntitiesAcknowledged:(BOOL)acknowledged withCompletion:(void (^)(CGFloat))completion {
    [self batchUpdateAllEntitiesAcknowledged:acknowledged refreshObjectsInContext:NO withCompletion:completion];
}

- (void)batchUpdateAllEntitiesAcknowledged:(BOOL)acknowledged
                   refreshObjectsInContext:(BOOL)refreshMOC withCompletion:(void (^)(CGFloat))completion {

    [_managedObjectContext performBlock:^{

        __block NSError *batchError = nil;
        __block NSBatchUpdateResult *batchResult = nil;
        CGFloat batchUpdateTime = BNRTimeBlock(^{
            NSBatchUpdateRequest *batchRequest = [[NSBatchUpdateRequest alloc] initWithEntityName:NSStringFromClass(Entity.class)];
            batchRequest.propertiesToUpdate = @{@"acknowledged" : @(acknowledged)};
            batchRequest.predicate = [NSPredicate predicateWithFormat:@"acknowledged == %@", @(!acknowledged)];
            batchRequest.affectedStores = _managedObjectContext.persistentStoreCoordinator.persistentStores;
            batchRequest.resultType = (refreshMOC) ? NSUpdatedObjectIDsResultType : NSUpdatedObjectsCountResultType;
            batchResult = (NSBatchUpdateResult *)[_managedObjectContext executeRequest:batchRequest error:&batchError];
            NSAssert(!batchError, @"Batch update failed.");
        });
        NSLog(@"Batch Update Duration: %f", batchUpdateTime);

        if (refreshMOC) {
            CGFloat managedObjectRefreshDuration = BNRTimeBlock(^{
                NSArray *objectIDs = batchResult.result;
                [objectIDs enumerateObjectsUsingBlock:^(NSManagedObjectID *objID, NSUInteger idx, BOOL *stop) {
                    NSError *existingObjError = nil;
                    NSManagedObject *obj = [_managedObjectContext existingObjectWithID:objID error:&existingObjError];
                    if (![obj isFault] && !existingObjError) {
                        [_managedObjectContext refreshObject:obj mergeChanges:YES];
                    }
                }];
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Refreshing objects in managed object context took: %f", managedObjectRefreshDuration);
                completion(batchUpdateTime + managedObjectRefreshDuration);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"%@ objects updated", batchResult.result);
                completion(batchUpdateTime);
            });
        }

    }];
}

#pragma mark - Manual Updating

- (void)manuallyUpdateAllEntitiesAcknowledged:(BOOL)acknowledged withCompletion:(void (^)(CGFloat))completion {
    __weak typeof (self) weakSelf = self;
    [_managedObjectContext performBlock:^{
        __strong typeof (weakSelf) strongSelf = weakSelf;

        CGFloat nonBatchUpdate = BNRTimeBlock(^{
            NSArray *items = [strongSelf allEntitiesAcknowledged:!acknowledged];
            [items makeObjectsPerformSelector:@selector(setAcknowledged:) withObject:@(acknowledged)];
        });

        CGFloat nonBatchSave = BNRTimeBlock(^{
            [strongSelf saveContext];
        });

        NSLog(@"Non Batch Update: %f", nonBatchUpdate);
        NSLog(@"Non Batch Save: %f", nonBatchSave);

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nonBatchUpdate + nonBatchSave);
        });
    }];
}

#pragma mark - Fetching

- (void)numberOfAllEntitiesAcknowledged:(BOOL)acknowledged withCompletion:(void (^)(NSUInteger))completion {
    __weak typeof (self) weakSelf = self;
    [_managedObjectContext performBlock:^{
        NSUInteger count = [weakSelf numberOfAllEntitiesAcknowledged:acknowledged];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(count);
        });
    }];
}

- (NSArray *)allEntitiesAcknowledged:(BOOL)acknowledged {
    NSError *fetchError = nil;
    NSArray *objects = [_managedObjectContext executeFetchRequest:[self fetchRequestForItemsAcknowledged:acknowledged] error:&fetchError];
    NSAssert(!fetchError, @"Fetch failed");
    return objects;
}

- (NSUInteger)numberOfAllEntitiesAcknowledged:(BOOL)acknowledged {
    NSError *fetchError = nil;
    NSFetchRequest *fetch = [self fetchRequestForItemsAcknowledged:acknowledged];
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetch error:&fetchError];
    NSAssert(!fetchError, @"Fetch failed");
    return count;
}

- (NSUInteger)numberOfAllEntities {
    NSError *fetchError = nil;
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(Entity.class)];
    NSUInteger count = [_managedObjectContext countForFetchRequest:request error:&fetchError];
    NSAssert(!fetchError, @"Fetch failed");
    return count;
}

- (NSFetchRequest *)fetchRequestForItemsAcknowledged:(BOOL)acknowledged {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(Entity.class)];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"acknowledged==%@", @(acknowledged)];
    return fetchRequest;
}

#pragma mark - Saving

- (BOOL)saveContext {
    BOOL success = YES;
    NSError *saveError = nil;
    if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&saveError]) {
        success = NO;
        NSLog(@"Saving failed with error: %@", saveError);
    }
    return success;
}

#pragma mark - Initial Insertion

- (void)insertInitialDataSetWithCompletion:(void (^)(BOOL))completion {
    __weak typeof(self) weakSelf = self;
    [self.managedObjectContext performBlock:^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        NSUInteger count = [strongSelf numberOfAllEntities];
        for (NSUInteger index = count; index < BNRCoreDataBatchingInitialSize; index++) {
            Entity *newEntity = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(Entity.class)
                                                              inManagedObjectContext:_managedObjectContext];
            newEntity.title = [NSString stringWithFormat:@"%ld: Entity", (long)index + 1];
            newEntity.acknowledged = @(NO);
            NSLog(@"Inserted %ld of %ld", (long)index + 1, (long)BNRCoreDataBatchingInitialSize);
        }
        BOOL success = [strongSelf saveContext];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(success);
        });
    }];
}

#pragma mark - Accessors

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _managedObjectContext.mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyStoreTrumpMergePolicyType];
        _managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _managedObjectContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataBatching" withExtension:@"momd"];
        NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        NSURL *documentsDir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *storeURL = [documentsDir URLByAppendingPathComponent:@"store.sqlite"];

        NSError *addingStoreError = nil;
        NSDictionary *storeOptions = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                       NSInferMappingModelAutomaticallyOption: @(YES)};
        NSPersistentStore *store = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                             configuration:nil
                                                                                       URL:storeURL
                                                                                   options:storeOptions
                                                                                     error:&addingStoreError];
        if (!store || addingStoreError) {
            NSLog(@"Big problems man: %@", addingStoreError);
        }
    }
    return _persistentStoreCoordinator;
}

@end
