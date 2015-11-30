//
//  LoginViewController.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import "IPMessagingManager.h"

@interface LoginViewController ()
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self login];
}


-(NSString *) generateUserNameWithLength: (int) len {
    
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex:arc4random_uniform((unsigned int)[letters length])]];
    }
    
    return randomString;
}

-(void) login  {
    [[IPMessagingManager sharedManager] loginWithIdentity:[self generateUserNameWithLength:5]];
    [[IPMessagingManager sharedManager] presentRootViewController];
}

@end
