//
//  IETViewController.m
//  Facebook
//
//  Created by gaoyang on 08/26/2015.
//  Copyright (c) 2015 gaoyang. All rights reserved.
//

#import "IETViewController.h"
#import "FacebookHelper.h"

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
    [[FacebookHelper getInstance] login];
}
- (IBAction)logout:(id)sender {
    [[FacebookHelper getInstance] logout];
}
- (IBAction)isLogin:(id)sender {
    BOOL isLogin = [[FacebookHelper getInstance] isLogin];
    NSLog(@"%@", isLogin?@"SUCCESS":@"FAILED");
}
- (IBAction)share:(id)sender {
    [[FacebookHelper getInstance] shareName:@"name"
                                   description:@"desc"
                                      imageUrl:@"http://www.baidu.com/aaa.png"
                                    contentUrl:@"http://www.baidu.com/aaa.png"
                                       caption:@"http://www.baidu.com"
                                              :^(BOOL result) {
                                                  NSLog(@"%@", result?@"SUCCESS":@"FAILED");
    }];
}
- (IBAction)getInvitableFriends:(id)sender {
    [[FacebookHelper getInstance] getInvitableFriends:@[] :^(NSDictionary *friends) {
        NSLog(@"%@", friends);
    }];
}
- (IBAction)getFriends:(id)sender {
    [[FacebookHelper getInstance] getFriends:^(NSDictionary *friends) {
        NSLog(@"%@", friends);
    }];
}
- (IBAction)getLevel:(id)sender {
    [[FacebookHelper getInstance] getLevel:@"1582428892009015" :^(int level) {
        NSLog(@"%d", level);
    }];
}
- (IBAction)setLevel:(id)sender {
    [[FacebookHelper getInstance] setLevel:10];
}
- (IBAction)getAccessToken:(id)sender {
    NSLog(@"%@", [[FacebookHelper getInstance] getAccessToken]);
}
- (IBAction)getUserProfile:(id)sender {
    [[FacebookHelper getInstance] getUserProfile:^(NSDictionary *dict) {
        NSLog(@"%@", dict);
    }];
}
- (IBAction)setAppLinkFunc:(id)sender {
    [[FacebookHelper getInstance] setAppLinkFunc:^(NSDictionary *dict) {
        NSLog(@"%@", dict);
    }];
}
- (IBAction)confirmRequest:(id)sender {
    [[FacebookHelper getInstance] confirmRequest:@[@"AVn_i1V1KzO-fD5Af-fxYzgJ-e-BWaNoyYn52qLBzSryBB3HGGArBwlL1sKQIJf-D0HDkOkYso3mONB38I7qsAZnbdcT5zTvztwDfOiRWdVdEg"]
                                          withTitle:@"title"
                                            withMsg:@"msg"
                                                   :^(NSDictionary *result) {
                                                       NSLog(@"%@", result);
                                                   }];
}
- (IBAction)quertRequest:(id)sender {
    [[FacebookHelper getInstance] queryRequest:^(NSDictionary *requests) {
        NSLog(@"%@", requests);
    }];
}
- (IBAction)acceptRequest:(id)sender {
    [[FacebookHelper getInstance] acceptRequest:@"" :^(BOOL result) {
        NSLog(@"%@", result?@"SUCCESS":@"FAILED");
    }];
}
- (IBAction)setLoginFunc:(id)sender {
    [[FacebookHelper getInstance] setLoginFunc:^(NSString *userId, NSString *token) {
        NSLog(@"%@, %@", userId, token);
    }];
}
- (IBAction)getUserId:(id)sender {
    NSString* userId = [[FacebookHelper getInstance] getUserID];
    NSLog(@"%@", userId);
}

@end
