//
//  ExpecteratorTests.m
//  ExpecteratorTests
//
//  Created by Sean McCune (BNR) on 8/29/14.
//  Copyright (c) 2014 BNR. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "BNRPageloader.h"

@interface ExpecteratorTests : XCTestCase

@property (strong, nonatomic) BNRPageloader *pageLoader;

@end

@implementation ExpecteratorTests

- (void)setUp {
    [super setUp];
    self.pageLoader = [[BNRPageloader alloc] init];
}

- (void)tearDown {
    self.pageLoader = nil;
    [super tearDown];
}

- (void)testAsyncTheOldWay
{
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:5.0];
    __block BOOL responseHasArrived = NO;
    
    [self.pageLoader requestUrl:@"http://bignerdranch.com"
              completionHandler:^(NSString *page) {
                  
                  NSLog(@"The web page is %ld bytes long.", page.length);
                  responseHasArrived = YES;
                  XCTAssert(page.length > 0);
              }];
    
    while (responseHasArrived == NO && ([timeoutDate timeIntervalSinceNow] > 0)) {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, YES);
    }
    
    if (responseHasArrived == NO) {
        XCTFail(@"Test timed out");
    }
}

- (void)testDownloadingAGoodWebPage
{
    XCTestExpectation *expectation =
        [self expectationWithDescription:@"High Expectations"];

    [self.pageLoader requestUrl:@"http://bignerdranch.com"
              completionHandler:^(NSString *page) {
                  
                  NSLog(@"The web page is %ld bytes long.", page.length);
                  XCTAssert(page.length > 0);
                  [expectation fulfill];
              }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

- (void)testDownloadingABadWebPage
{
    XCTestExpectation *expectation =
    [self expectationWithDescription:@"Low Expectations"];
    
    [self.pageLoader requestUrl:@"http://nonexistentpage.snarfle"
              completionHandler:^(NSString *page) {
                  
                  NSLog(@"The web page is %ld bytes long.", page.length);
                  XCTAssert(page.length > 0);
                  [expectation fulfill];
              }];
    
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError *error) {
        if (error) {
            NSLog(@"Timeout Error: %@", error);
        }
    }];
}

@end
