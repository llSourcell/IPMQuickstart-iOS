//
//  ChannelViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "ViewController.h"
#import "MessageTableViewCell.h"
#import "MemberTypingTableViewCell.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, TMChannelDelegate, UITextFieldDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableOrderedSet *messages;
@property (weak, nonatomic) IBOutlet UITextField *messageInput;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardAdjustmentConstraint;
@property (nonatomic, strong) NSMutableArray *typingUsers;
@end

@implementation ViewController

#pragma mark - View lifecycle methods

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    self.messages = [[NSMutableOrderedSet alloc] init];
    self.typingUsers = [NSMutableArray array];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.hidesBackButton = YES;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 88.0f;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.channel) {
        self.channel.delegate = self;
        [self loadMessages];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:self.view.window];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidShow:)
                                                     name:UIKeyboardDidShowNotification
                                                   object:self.view.window];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:self.view.window];
        
        [self.messageInput becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.channel) {
        self.channel.delegate = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)setChannel:(TMChannel *)channel {
    _channel = channel;
    self.channel.delegate = self;

    [self loadMessages];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger count = self.messages.count;
    if (self.typingUsers.count > 0) {
        count++;
    }
    return count;
}

- (NSString *)typingUsersString {
    NSArray *typingUsers = [self.typingUsers copy];
    
    NSMutableString *ret = [NSMutableString string];

    for (int ndx=0; ndx < typingUsers.count; ndx++) {
        TMMember *member = (TMMember *)typingUsers[ndx];
        if (ndx > 0 && ndx < typingUsers.count - 1) {
            [ret appendString:@", "];
        } else if (ndx > 0 && ndx == typingUsers.count - 1) {
            [ret appendString:@" and "];
        }
        [ret appendString:member.identity];
    }
    
    return [NSString stringWithFormat:@"%@ %@ typing...", ret, typingUsers.count > 1 ? @"are" : @"is"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    
    if (self.typingUsers.count > 0 && indexPath.row == self.messages.count) {
        NSString *message = [self typingUsersString];
        MemberTypingTableViewCell *typingCell = [tableView dequeueReusableCellWithIdentifier:@"typing"];

        typingCell.typingLabel.text = message;
        [typingCell layoutIfNeeded];
        
        cell = typingCell;
    } else {
        MessageTableViewCell *messageCell = [tableView dequeueReusableCellWithIdentifier:@"message"];
        TMMessage *message = self.messages[indexPath.row];
        
        messageCell.authorLabel.text = message.author;
        messageCell.dateLabel.text = message.timestamp;
        messageCell.bodyLabel.text = message.body;
        [messageCell layoutIfNeeded];
        
        cell = messageCell;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}
- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *actions = [NSMutableArray array];
    return actions;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    [self.channel typing];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length == 0) {
        [self.view endEditing:YES];
    } else {
        TMMessage *message = [self.channel.messages createMessageWithBody:textField.text];
        textField.text = @"";
        [self.channel.messages sendMessage:message
                                completion:^(TMResultEnum result) {
                                    if (result == TMResultFailure) {
                                    }
                                }];
    }
    return YES;
}

#pragma mark - Internal methods




- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary* userInfo = [notification userInfo];
    CGFloat keyboardHeight = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    
    self.keyboardAdjustmentConstraint.constant = keyboardHeight;
    [self.view setNeedsLayout];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    [self scrollToBottomMessage];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.keyboardAdjustmentConstraint.constant = 0;
    [self.view setNeedsLayout];
}

- (void)loadMessages {
    [self.messages removeAllObjects];
    [self addMessages:self.channel.messages.allObjects];
}

- (void)addMessages:(NSArray<TMMessage *> *)messages {
    [self.messages addObjectsFromArray:messages];
    [self sortMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.messages.count > 0) {
            [self scrollToBottomMessage];
        }
    });
}

- (void)removeMessages:(NSArray<TMMessage *> *)messages {
    [self.messages removeObjectsInArray:messages];
    [self sortMessages];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        if (self.messages.count > 0) {
            [self scrollToBottomMessage];
        }
    });
}

- (void)scrollToBottomMessage {
    if (self.messages.count == 0) {
        return;
    }
    
    NSIndexPath *bottomMessageIndex = [NSIndexPath indexPathForRow:[self.tableView numberOfRowsInSection:0] - 1
                                                         inSection:0];
    [self.tableView scrollToRowAtIndexPath:bottomMessageIndex
                          atScrollPosition:UITableViewScrollPositionBottom
                                  animated:NO];
}

- (void)sortMessages {
    [self.messages sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"timestamp"
                                                                      ascending:YES]]];
}

- (TMMessage *)messageForIndexPath:(nonnull NSIndexPath *)indexPath {
    return self.messages[indexPath.row];
}

#pragma mark - TMChannelDelegate

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
           channelChanged:(TMChannel *)channel {
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
           channelDeleted:(TMChannel *)channel {
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
     channelHistoryLoaded:(TMChannel *)channel {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
             memberJoined:(TMMember *)member {
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
            memberChanged:(TMMember *)member {

}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
               memberLeft:(TMMember *)member {
   
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
             messageAdded:(TMMessage *)message {
    [self addMessages:@[message]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
           messageDeleted:(TMMessage *)message {
    [self removeMessages:@[message]];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
                  channel:(TMChannel *)channel
           messageChanged:(TMMessage *)message {
    [self.tableView reloadData];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
   typingStartedOnChannel:(TMChannel *)channel
                   member:(TMMember *)member {
    [self.typingUsers addObject:member];
    [self.tableView reloadData];
    [self scrollToBottomMessage];
}

- (void)ipMessagingClient:(TwilioIPMessagingClient *)client
     typingEndedOnChannel:(TMChannel *)channel
                   member:(TMMember *)member {
    [self.typingUsers removeObject:member];
    [self.tableView reloadData];
    [self scrollToBottomMessage];
}

@end
