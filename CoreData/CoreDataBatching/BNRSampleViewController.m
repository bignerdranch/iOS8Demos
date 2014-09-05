//
//  BNRSampleViewController.m
//  CoreDataBatching
//
//  Created by Robert Edwards on 9/3/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRSampleViewController.h"

#import "BNRCoreDataCoordinator.h"
#import "Entity.h"

static void *ProgressObserverContext = &ProgressObserverContext;

@interface BNRSampleViewController ()

@property (strong, nonatomic) BNRCoreDataCoordinator *coreDataCoordinator;

#pragma mark - Fetching Outlets

@property (weak, nonatomic) IBOutlet UISwitch *fetchAcknowledgedSwitch;
@property (weak, nonatomic) IBOutlet UILabel *acknowledgedCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *asyncFetchButton;

#pragma mark - Updating Outlets

@property (weak, nonatomic) IBOutlet UISwitch *updateAcknowledgedSwitch;
@property (weak, nonatomic) IBOutlet UILabel *lastBatchUpdateTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lastManualUpdateTimeLabel;
@property (weak, nonatomic) IBOutlet UIButton *batchUpdateButton;
@property (weak, nonatomic) IBOutlet UIButton *manualUpdateButton;

#pragma mark - Progress Outlets

@property (weak, nonatomic) IBOutlet UIView *progressContainerView;
@property (weak, nonatomic) IBOutlet UILabel *inProgressLabel;

#pragma mark - Asynchronous Progress Properties

@property (strong, nonatomic) NSNumber *lastFetchProgressCountValue;

@end

@implementation BNRSampleViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self toggleProgressVisible:YES withProgressText:@"Inserting Initial Data Set"];
    __weak typeof(self) weakSelf = self;
    [self.coreDataCoordinator insertInitialDataSetWithCompletion:^(BOOL success) {
        [weakSelf toggleProgressVisible:NO withProgressText:nil];
    }];
}

#pragma mark - Actions

- (IBAction)manualUpdateSelected:(id)sender {
    [self toggleProgressVisible:YES withProgressText:@"Manual Update in Progress"];
    BOOL acknowledged = self.updateAcknowledgedSwitch.on;

    [self.coreDataCoordinator manuallyUpdateAllEntitiesAcknowledged:acknowledged withCompletion:^(CGFloat updateDuration) {
        NSLog(@"Non Batch Total: %f", updateDuration);
        self.lastManualUpdateTimeLabel.text = [NSString stringWithFormat:@"Last Time: %f", updateDuration];

        [self toggleProgressVisible:NO withProgressText:nil];
    }];
}

- (IBAction)batchUpdateSelected:(id)sender {
    [self toggleProgressVisible:YES withProgressText:@"Batch Update in Progress"];
    BOOL acknowledged = self.updateAcknowledgedSwitch.on;

    [self.coreDataCoordinator batchUpdateAllEntitiesAcknowledged:acknowledged withCompletion:^(CGFloat updateDuration) {
        NSLog(@"Batch Update (without managed object refresh): %f", updateDuration);
        self.lastBatchUpdateTimeLabel.text = [NSString stringWithFormat:@"Last Time: %f", updateDuration];

        [self toggleProgressVisible:NO withProgressText:nil];
    }];
}

- (IBAction)startAsyncFetch:(id)sender {
    [self toggleProgressVisible:YES withProgressText:@"Async Fetch in Progress"];
    self.lastFetchProgressCountValue = @(0);
    [self refreshFetchProgressLabel];
    BOOL acknowledged = self.fetchAcknowledgedSwitch.on;

    __weak typeof (self) weakSelf = self;
    [self.coreDataCoordinator numberOfAllEntitiesAcknowledged:acknowledged withCompletion:^(NSUInteger count) {
        __strong typeof (weakSelf) strongSelf = weakSelf;
        NSManagedObjectContext *context = [strongSelf.coreDataCoordinator managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:NSStringFromClass(Entity.class)];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"acknowledged == %@", @(acknowledged)];


        NSPersistentStoreAsynchronousFetchResultCompletionBlock resultBlock = ^(NSAsynchronousFetchResult *result) {
            [result.progress removeObserver:strongSelf
                                 forKeyPath:NSStringFromSelector(@selector(completedUnitCount))
                                    context:ProgressObserverContext];

            [result.progress removeObserver:strongSelf
                                 forKeyPath:NSStringFromSelector(@selector(totalUnitCount))
                                    context:ProgressObserverContext];

            dispatch_async(dispatch_get_main_queue(), ^{
                [strongSelf toggleProgressVisible:NO withProgressText:nil];
            });
        };

        NSAsynchronousFetchRequest *asyncFetch = [[NSAsynchronousFetchRequest alloc]
                                                  initWithFetchRequest:fetchRequest
                                                  completionBlock:resultBlock];

        [context performBlock:^{
            NSProgress *progress = [NSProgress progressWithTotalUnitCount:count];
            [progress becomeCurrentWithPendingUnitCount:1];

            NSError *executeError = nil;
            NSAsynchronousFetchResult *result = (NSAsynchronousFetchResult *)[context executeRequest:asyncFetch error:&executeError];

            [result.progress addObserver:strongSelf
                           forKeyPath:NSStringFromSelector(@selector(completedUnitCount))
                              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                              context:ProgressObserverContext];

            [result.progress addObserver:strongSelf
                           forKeyPath:NSStringFromSelector(@selector(totalUnitCount))
                              options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew
                              context:ProgressObserverContext];
            [progress resignCurrent];
        }];

    }];
}

#pragma mark - Asynchronous Progress Reporting

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == ProgressObserverContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(completedUnitCount))]) {
            NSNumber *newValue = [change objectForKey:@"new"];
            if (newValue.integerValue > (self.lastFetchProgressCountValue.integerValue + 10000)) {
                self.lastFetchProgressCountValue = newValue;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self refreshFetchProgressLabel];
                });
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(totalUnitCount))]) {
            NSNumber *newValue = change[@"new"];
            self.lastFetchProgressCountValue = newValue;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self refreshFetchProgressLabel];
            });
        }
    }
}

#pragma mark - Progress Helpers

- (void)toggleProgressVisible:(BOOL)visible withProgressText:(NSString *)text {
    [self toggleUserInteractionEnabled:!visible];
    self.progressContainerView.hidden = !visible;
    self.inProgressLabel.text = text;
}

- (void)toggleUserInteractionEnabled:(BOOL)enabled {
    NSArray *buttons = @[self.batchUpdateButton, self.manualUpdateButton, self.asyncFetchButton];
    [buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        button.enabled = enabled;
    }];

    NSArray *switches = @[self.updateAcknowledgedSwitch, self.fetchAcknowledgedSwitch];
    [switches enumerateObjectsUsingBlock:^(UISwitch *switchObj, NSUInteger idx, BOOL *stop) {
        switchObj.enabled = enabled;
    }];
}

- (void)refreshFetchProgressLabel {
    self.acknowledgedCountLabel.text = [NSString stringWithFormat:@"Fetched: %@ %@",
                                        self.lastFetchProgressCountValue,
                                        (self.fetchAcknowledgedSwitch.on) ? @"acknowledged" : @"unacknowleged"];
}

#pragma mark - Accessor

- (BNRCoreDataCoordinator *)coreDataCoordinator {
    if (!_coreDataCoordinator) {
        _coreDataCoordinator = [[BNRCoreDataCoordinator alloc] init];
    }
    return _coreDataCoordinator;
}

@end
