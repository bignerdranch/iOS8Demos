//
//  BNRChannelChatViewController.m
//  Fatchat
//
//  Created by Steve Sparks on 8/22/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import "BNRChannelChatViewController.h"
#import "BNRCloudStore.h"
#import "BNRChatChannel.h"
#import "BNRChatMessage.h"
#import "BNRChatMessageCell.h"
#import "BNRAutoFlexibleTextCell.h"
#import <CloudKit/CloudKit.h>
#import "UITableViewCell+BNRAdditions.h"

@interface BNRChannelChatViewController()<UIAlertViewDelegate, UITextFieldDelegate, BNRCloudStoreMessageDelegate>
@property (strong, nonatomic) NSArray *messages;
@property (strong, nonatomic) UITextField *messageTextField;
@property (weak, nonatomic) UIBarButtonItem *sendButton;
@end

@implementation BNRChannelChatViewController

- (instancetype)initWithChannel:(BNRChatChannel *)channel {
    self = [super init];
    if(self) {
        self.channel = channel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshData)];

    self.navigationItem.rightBarButtonItem = refreshButton;

    self.navigationController.toolbarHidden = NO;

    [self refreshDataWithCompletion:^{
            [self scrollToBottom];
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!self.channel.subscribed) {
        [[BNRCloudStore sharedStore] subscribeToChannel:self.channel completion:^(BNRChatChannel *channel, NSError *error){
            if(error) {
                NSLog(@"Error %@", error.localizedDescription);
            } else {
                self.channel.subscribed = YES;
            }
            [self refreshData];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [BNRCloudStore sharedStore].messageDelegate = self;
    self.messageTextField.frame = CGRectMake(0, 0, self.view.frame.size.width-120, 30);
    self.messageTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.messageTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.messageTextField.autocorrectionType = UITextAutocorrectionTypeNo;

    self.messageTextField.delegate = self;
    UIBarButtonItem *textFieldButton = [[UIBarButtonItem alloc] initWithCustomView:self.messageTextField];
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendMessage:)];
    self.sendButton = sendButton;
    UIBarButtonItem *handleButton = [[UIBarButtonItem alloc] initWithTitle:@"Me" style:UIBarButtonItemStylePlain target:self action:@selector(promptForNewHandle)];


    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

    self.navigationController.toolbar.items = @[
                                                leftSpace,
                                                handleButton,
                                                textFieldButton,
                                                sendButton,
                                                rightSpace
                                                ];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[BNRCloudStore sharedStore] unsubscribeFromChannel:self.channel completion:^(BNRChatChannel *channel, NSError *error){
        if(error) {
            NSLog(@"Error %@", error.localizedDescription);
        }
        self.channel.subscribed = NO;
        [self refreshData];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [BNRCloudStore sharedStore].messageDelegate = nil;
}

- (UITextField *)messageTextField {
    if(!_messageTextField) {
        _messageTextField = [[UITextField alloc] init];
        _messageTextField.borderStyle = UITextBorderStyleRoundedRect;
    }
    return _messageTextField;
}


#pragma mark - utilities

- (void)scrollToBottom {
    if(!self.messages.count)
        return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(self.messages.count-1) inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    });

}

- (void)asyncReload {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.title = self.channel.name;
        self.navigationItem.prompt = self.channel.subscribed?@"Subscribed":nil;
        [self.tableView reloadData];
    });
}

- (void)refreshData {
    [self refreshDataWithCompletion:nil];
}

- (void)refreshDataWithCompletion:(void(^)(void))completion {
    BNRCloudStore *store = [BNRCloudStore sharedStore];

    [self asyncReload];

    [store fetchMessagesForChannel:self.channel completion:^(NSArray *messages, NSError *error){
        self.messages = messages;
        [self asyncReload];
        if(completion)
            completion();
    }];
}

- (IBAction)sendMessage:(UIBarButtonItem *)sender {
    NSString *text = self.messageTextField.text;
    if(text.length) {
        self.messageTextField.text = nil;
        sender.enabled = NO;
        [[BNRCloudStore sharedStore] createNewMessageWithText:text assetFileUrl:nil assetType:BNRChatMessageAssetTypeNone channel:self.channel completion:^(BNRChatMessage *msg, NSError *err){
            self.messages = [self.messages arrayByAddingObject:msg];
            [self asyncReload];
            [self scrollToBottom];
            sender.enabled = YES;
        }];
    }
}

- (void)promptForNewHandle {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"New Handle" message:@"Who will you be?" delegate:self cancelButtonTitle:@"Nevermind" otherButtonTitles:@"Rename Me", nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alertView show];
    dispatch_async(dispatch_get_main_queue(), ^{
        [alertView textFieldAtIndex:0].text = [BNRCloudStore sharedStore].handle;
    });
}

#pragma mark - UITableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    BNRAutoFlexibleTextCell *mCell = [tableView dequeueReusableCellWithIdentifier:@"BNRAutoFlexibleTextCell"];
    if(!mCell) {
        mCell = [BNRAutoFlexibleTextCell bnr_instantiateCellFromNib];
    }
    BNRChatMessage *msg = self.messages[indexPath.row];
    mCell.titleLabel.text = msg.senderName;
    mCell.descriptionLabel.text = msg.message;
    cell = mCell;

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(buttonIndex) {
        NSString *text = [alertView textFieldAtIndex:0].text;
        if([alertView.title isEqualToString:@"New Message"]) {
            [[BNRCloudStore sharedStore] createNewMessageWithText:text assetFileUrl:nil assetType:BNRChatMessageAssetTypeNone channel:self.channel completion:^(BNRChatMessage *msg, NSError *err){
                self.messages = [self.messages arrayByAddingObject:msg];
                [self asyncReload];
            }];
        } else {
            [[BNRCloudStore sharedStore] setHandle:text];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForFooterInSection:(NSInteger)section {
    return 2;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 1)];
    v.backgroundColor = [UIColor lightGrayColor];
    return v;
}

#pragma mark - UITextFieldDelegate

//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//    UIBarButtonItem *textFieldButton = [[UIBarButtonItem alloc] initWithCustomView:self.messageTextField];
//    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(sendMessage:)];
//    self.sendButton = sendButton;
//    UIBarButtonItem *handleButton = [[UIBarButtonItem alloc] initWithTitle:@"Me" style:UIBarButtonItemStylePlain target:self action:@selector(promptForNewHandle)];
//
//
//    UIBarButtonItem *leftSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//    UIBarButtonItem *rightSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
//
//    UIToolbar *t = [[UIToolbar alloc] init];
//    t.items = @[
//                leftSpace,
//                handleButton,
//                textFieldButton,
//                sendButton,
//                rightSpace
//                ];
//    textField.inputAccessoryView = t;
//    [self.messageTextField becomeFirstResponder];
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if(textField.text.length) {
        [self sendMessage:nil];
    }
    return YES;
}

#pragma mark - BNRCloudStoreMessageDelegate

- (void)cloudStore:(BNRCloudStore *)store didReceiveMessage:(BNRChatMessage *)message onChannel:(BNRChatChannel *)channel {
    
    if(![self.channel isEqual:channel]) {
        return; // not for us
    } else {
        NSInteger idx = [self.messages indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            BNRChatMessage *testMsg = obj;
            return [testMsg.recordID isEqual:message.recordID];
        }];

        if(idx==NSNotFound) {
            self.messages = [self.messages arrayByAddingObject:message];
            [self asyncReload];
            [self scrollToBottom];
        }
    }
}

@end


