//
//  BNRChannelSettingsViewController.m
//  Fatchat
//
//  Created by Steve Sparks on 8/25/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRChannelSettingsViewController.h"
#import "BNRCloudStore.h"

@interface BNRChannelSettingsViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userHandleLabel;
@property (weak, nonatomic) IBOutlet UITextField *channelNameLabel;

@end

@implementation BNRChannelSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)deleteAllMessagesTapped:(id)sender {
}

- (void)viewWillDisappear:(BOOL)animated {
    if(self.userHandleLabel.text.length)
        [[BNRCloudStore sharedStore] setHandle:self.userHandleLabel.text];
}

@end
