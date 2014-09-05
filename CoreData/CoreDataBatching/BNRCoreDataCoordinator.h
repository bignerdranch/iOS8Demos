//
//  BNRCoreDataCoordinator.h
//  CoreDataBatching
//
//  Created by Robert Edwards on 8/27/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface BNRCoreDataCoordinator : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

#pragma mark - Initial Insert
- (void)insertInitialDataSetWithCompletion:(void (^)(BOOL success))completion;

#pragma mark - Count Fetching
- (void)numberOfAllEntitiesAcknowledged:(BOOL)acknowleged
                         withCompletion:(void (^)(NSUInteger count))completion;

#pragma mark - Updating
- (void)manuallyUpdateAllEntitiesAcknowledged:(BOOL)acknowledged
                               withCompletion:(void (^)(CGFloat updateDuration))completion;

- (void)batchUpdateAllEntitiesAcknowledged:(BOOL)acknowledged
                            withCompletion:(void (^)(CGFloat updateDuration))completion;

- (void)batchUpdateAllEntitiesAcknowledged:(BOOL)acknowledged
                   refreshObjectsInContext:(BOOL)refreshMOC
                            withCompletion:(void (^)(CGFloat updateDuration))completion;

@end
