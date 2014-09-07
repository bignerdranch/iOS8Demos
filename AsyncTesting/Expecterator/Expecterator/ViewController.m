//
//  ViewController.m
//  Expecterator
//
//  Created by Sean McCune (BNR) on 8/29/14.
//  Copyright (c) 2014 BNR. All rights reserved.
//

#import "ViewController.h"
#import "BNRPageloader.h"

@interface ViewController ()

@end

@implementation ViewController
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)webRequestButtonTap:(id)sender {
    
    BNRPageloader *pageLoader = [[BNRPageloader alloc] init];

    [pageLoader requestUrl:@"http://bignerdranch.com"
         completionHandler:^(NSString *page) {
             NSLog(@"%@", page);
         }];
}


@end
