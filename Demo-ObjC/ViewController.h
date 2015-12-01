//
//  ChannelViewController.h
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <TwilioIPMessagingClient/TwilioIPMessagingClient.h>

@interface ViewController : UIViewController
@property (nonatomic, strong) TWMChannel *channel;
@end
