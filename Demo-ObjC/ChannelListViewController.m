//
//  ChannelListViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "ChannelListViewController.h"
#import "ChannelTableViewCell.h"
#import "ViewController.h"
#import "IPMessagingManager.h"

@interface ChannelListViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) TMChannels *channelsList;
@property (nonatomic, strong) NSMutableOrderedSet *channels;
@end

@implementation ChannelListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    TwilioIPMessagingClient *client = [[IPMessagingManager sharedManager] client];
    if (client) {
        [self populateChannels];
    }
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"viewChannel"]) {
        ViewController *vc = segue.destinationViewController;
        vc.channel = sender;
    }
}

#pragma mark - Demo helpers

- (void)populateChannels {
    self.channelsList = nil;
    self.channels = nil;
    [self.tableView reloadData];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[IPMessagingManager sharedManager] client] channelsListWithCompletion:^(TMResultEnum result, TMChannels *channelsList) {
            if (result == TMResultSuccess) {
                self.channelsList = channelsList;
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self.channelsList loadChannelsWithCompletion:^(TMResultEnum result) {
                        if (result == TMResultSuccess) {
                            self.channels = [[NSMutableOrderedSet alloc] init];
                            [self.channels addObjectsFromArray:[self.channelsList allObjects]];
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                
                                BOOL isMatch = false;
                                
                                //OPTION 1
                                //find a channel match
                                for (TMChannel *chan in self.channels) {
                                    if([chan.friendlyName  isEqual: @"general"]) {
                                        isMatch = true;
                                        //join it
                                        [self joinChannel:chan];
                                        [self performSegueWithIdentifier:@"viewChannel" sender:chan];
                                        [self.tableView reloadData];
                                    }
                                }
                                
                                //OPTION 2
                                //if no match, empty the list of channels and create a new channel
                                
                                if(isMatch == false) {
                                    NSLog(@"No matching channel found");
                                    [self.channelsList createChannelWithFriendlyName:@"general"
                                                                                type:TMChannelTypePublic
                                                                          completion:^(TMResultEnum result, TMChannel *channel) {
                                                                              if (result == TMResultSuccess) {
                                                                                  NSLog(@"Channel created!");
                                                                                  [self joinChannel:channel];
                                                                                  [self performSegueWithIdentifier:@"viewChannel" sender:channel];
                                                                                  [self.tableView reloadData];
                                                                              }
                                                                          }];
                                }
                                
                            });
                        }
                    }];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"IP Messaging Demo" message:@"Failed to load channels." preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [self presentViewController:alert animated:YES completion:nil];
                    
                    self.channelsList = nil;
                    [self.channels removeAllObjects];
                    
                    [self.tableView reloadData];
                });
            }
        }];
    });
}



- (void)joinChannel:(TMChannel *)channel {
    [channel joinWithCompletion:^(TMResultEnum result) {
        NSLog(@"Channel joined!");
    }];
}



#pragma mark - UITableViewDataSource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"loading"];
    [cell layoutIfNeeded];
    return cell;
}



@end