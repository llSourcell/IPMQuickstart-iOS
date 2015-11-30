//
//  IPMessagingManager.m
//  Twilio IP Messaging Demo
//
//  Copyright (c) 2015 Twilio. All rights reserved.
//

#import "AppDelegate.h"
#import "IPMessagingManager.h"

@interface IPMessagingManager()
@property (nonatomic, strong) TwilioIPMessagingClient *client;

@property (nonatomic, strong) NSData *lastToken;
@property (nonatomic, strong) NSDictionary *lastNotification;
@end

@implementation IPMessagingManager

+ (instancetype)sharedManager {
    static IPMessagingManager *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (void)presentRootViewController {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if ([[IPMessagingManager sharedManager] hasIdentity]) {
        [[IPMessagingManager sharedManager] loginWithStoredIdentity];
        appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    } else {
        appDelegate.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"login"];
    }
}

- (BOOL)hasIdentity {
    return ([self storedIdentity] && [self storedIdentity].length > 0);
}

- (BOOL)loginWithStoredIdentity {
    if ([self hasIdentity]) {
        return [self loginWithIdentity:[self storedIdentity]];
    } else {
        return NO;
    }
}

- (BOOL)loginWithIdentity:(NSString *)identity {
    if (self.client) {
        [self logout];
    }
    
    [self storeIdentity:identity];
    
    NSString *token = [self tokenForIdentity:identity];
    self.client = [TwilioIPMessagingClient ipMessagingClientWithToken:token
                                                             delegate:nil];
    
    return YES;
}

- (void)logout {
    [self storeIdentity:nil];
    [self.client shutdown];
    self.client = nil;
}

- (void)updatePushToken:(NSData *)token {
    self.lastToken = token;
    [self updateIpMessagingClient];
}

- (void)receivedNotification:(NSDictionary *)notification {
    self.lastNotification = notification;
    [self updateIpMessagingClient];
}

#pragma mark Push functionality

- (void)setIpMessagingClient:(TwilioIPMessagingClient *)ipMessagingClient {
    [self updateIpMessagingClient];
}

- (void)updateIpMessagingClient {
    if (self.lastToken) {
        [self.client registerWithToken:self.lastToken];
        self.lastToken = nil;
    }
    
    if (self.lastNotification) {
        [self.client handleNotification:self.lastNotification];
        self.lastNotification = nil;
    }
}

#pragma mark Internal helpers

- (NSString *)tokenForIdentity:(NSString *)identity {
    NSString *identifierForVendor = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *credential_sid = nil; // optional, but if you have created a credential it will start with CR...
    NSString *urlString = [NSString stringWithFormat:@"https://your-web-app.com/token?device=%@", identifierForVendor];
    if (credential_sid) {
        urlString = [urlString stringByAppendingFormat:@"&credential_sid=%@", credential_sid];
    }
    return [NSString stringWithContentsOfURL:[NSURL URLWithString:urlString] encoding:NSUTF8StringEncoding error:nil];
}

- (void)storeIdentity:(NSString *)identity {
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUserDefaults standardUserDefaults] setObject:identity forKey:@"identity"];
}

- (NSString *)storedIdentity {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"identity"];
}

@end
