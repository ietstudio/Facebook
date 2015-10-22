//
//  IETViewController.m
//  Facebook
//
//  Created by gaoyang on 08/26/2015.
//  Copyright (c) 2015 gaoyang. All rights reserved.
//

#import "IETViewController.h"
#import "IOSFacebookHelper.h"

@interface IETViewController ()

@end

@implementation IETViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)login:(id)sender {
    [[IOSFacebookHelper getInstance] login];
}
- (IBAction)logout:(id)sender {
    [[IOSFacebookHelper getInstance] logout];
}
- (IBAction)isLogin:(id)sender {
    BOOL isLogin = [[IOSFacebookHelper getInstance] isLogin];
    NSLog(@"%@", isLogin?@"SUCCESS":@"FAILED");
}
- (IBAction)share:(id)sender {
    [[IOSFacebookHelper getInstance] shareName:@"name"
                                   description:@"desc"
                                      imageUrl:@"http://www.baidu.com/aaa.png"
                                    contentUrl:@"http://www.baidu.com/aaa.png"
                                       caption:@"http://www.baidu.com"
                                              :^(BOOL result) {
                                                  NSLog(@"%@", result?@"SUCCESS":@"FAILED");
    }];
}
- (IBAction)getInvitableFriends:(id)sender {
    [[IOSFacebookHelper getInstance] getInvitableFriends:@[] :^(NSDictionary *friends) {
        NSLog(@"%@", friends);
    }];
}
- (IBAction)getFriends:(id)sender {
    [[IOSFacebookHelper getInstance] getFriends:^(NSDictionary *friends) {
        NSLog(@"%@", friends);
    }];
}
- (IBAction)getLevel:(id)sender {
    [[IOSFacebookHelper getInstance] getLevel:@"1582428892009015" :^(int level) {
        NSLog(@"%d", level);
    }];
}
- (IBAction)setLevel:(id)sender {
    [[IOSFacebookHelper getInstance] setLevel:10];
}
- (IBAction)getAccessToken:(id)sender {
    NSLog(@"%@", [[IOSFacebookHelper getInstance] getAccessToken]);
}
- (IBAction)getUserProfile:(id)sender {
    [[IOSFacebookHelper getInstance] getUserProfile:^(NSDictionary *dict) {
        NSLog(@"%@", dict);
    }];
}
- (IBAction)setAppLinkFunc:(id)sender {
    [[IOSFacebookHelper getInstance] setAppLinkFunc:^(NSDictionary *dict) {
        NSLog(@"%@", dict);
    }];
}
- (IBAction)confirmRequest:(id)sender {
    [[IOSFacebookHelper getInstance] confirmRequest:@[@"AVn_i1V1KzO-fD5Af-fxYzgJ-e-BWaNoyYn52qLBzSryBB3HGGArBwlL1sKQIJf-D0HDkOkYso3mONB38I7qsAZnbdcT5zTvztwDfOiRWdVdEg"]
                                          withTitle:@"title"
                                            withMsg:@"msg"
                                                   :^(NSDictionary *result) {
                                                       NSLog(@"%@", result);
                                                   }];
}
- (IBAction)quertRequest:(id)sender {
    [[IOSFacebookHelper getInstance] queryRequest:^(NSDictionary *requests) {
        NSLog(@"%@", requests);
    }];
}
- (IBAction)acceptRequest:(id)sender {
    [[IOSFacebookHelper getInstance] acceptRequest:@"" :^(BOOL result) {
        NSLog(@"%@", result?@"SUCCESS":@"FAILED");
    }];
}
- (IBAction)setLoginFunc:(id)sender {
    [[IOSFacebookHelper getInstance] setLoginFunc:^(NSString *userId, NSString *token) {
        NSLog(@"%@, %@", userId, token);
    }];
}
- (IBAction)getUserId:(id)sender {
    NSString* userId = [[IOSFacebookHelper getInstance] getUserID];
    NSLog(@"%@", userId);
}

@end
