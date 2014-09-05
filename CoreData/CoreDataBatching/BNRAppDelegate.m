//
//  BNRAppDelegate.m
//  CoreDataBatching
//
//  Created by Robert Edwards on 8/26/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRAppDelegate.h"

#import "BNRSampleViewController.h"

@interface BNRAppDelegate ()

@end

@implementation BNRAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    BNRSampleViewController *vc = [BNRSampleViewController new];
    self.window.rootViewController = vc;

    [self.window makeKeyAndVisible];
    return YES;
}

@end
