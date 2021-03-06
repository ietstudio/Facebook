//
//  FacebookHelper.m
//  Pods
//
//  Created by geekgy on 15/5/17.
//
//

#import "FacebookHelper.h"
#import <UIKit/UIKit.h>
#import "IOSSystemUtil.h"

#define PERMISSION_READ         @"Read"
#define PERMISSION_PUBLISH      @"Publish"
#define GRAPH_API_TIMEOUT       5

@implementation FacebookHelper
{
    void (^_loginFunc)(NSString*, NSString*);
    void (^_applinkFunc)(NSDictionary*);
    void (^_requestFunc)(NSDictionary*);
    void (^_inviteBlock)(BOOL);
}

SINGLETON_DEFINITION(FacebookHelper)

#pragma mark - private method

/**
 *  是否已经登陆并授权
 *
 *  @param permissions 权限
 *
 *  @return 权限授权信息
 */
- (NSDictionary*)isGrantedPermissions:(NSArray*)permissions {
    FBSDKAccessToken* accessToken = [FBSDKAccessToken currentAccessToken];
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    for (int i=0; i<[permissions count]; i++) {
        NSString* permission = permissions[i];
        NSNumber* granted = [NSNumber numberWithBool:[accessToken hasGranted:permission]];
        [result setObject:granted forKey:permission];
    }
    return result;
}

/**
 *  申请权限
 *
 *  @param permissions 权限
 *  @param func        回调
 */
- (void)grantPermissions:(NSArray *)permissions :(NSString*)type :(void (^)(BOOL))func {
    FBSDKLoginManager* loginManager = [[FBSDKLoginManager alloc] init];
    void(^block)(FBSDKLoginManagerLoginResult *, NSError *) = ^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        BOOL isSuccess = NO;
        if (error) {
            NSLog(@"facebook login error: %@", error);
        } else {
            if (result.isCancelled) {
                NSLog(@"facebook login cancelled");
            } else {
                NSLog(@"facebook login success");
                isSuccess = YES;
                if (_loginFunc) {
                    NSString* userID        = [self getUserID];
                    NSString* accessToken   = [self getAccessToken];
                    _loginFunc(userID, accessToken);
                }
            }
        }
        func(isSuccess);
    };
    UIViewController *controller = [IOSSystemUtil getInstance].controller;
    if ([type isEqualToString:PERMISSION_READ]) {
        [loginManager logInWithReadPermissions:permissions fromViewController:controller handler:block];
    } else if ([type isEqualToString:PERMISSION_PUBLISH]) {
        [loginManager logInWithPublishPermissions:permissions fromViewController:controller handler:block];
    }
}

/**
 *  检测是否包含权限，如果没有包含，申请权限
 *  注意：申请是申请了，但是是否用户同意了，并没有做判断，应该是如果用户没有同意，
 *  弹出来为什么需要这个申请权限，然后下次在申请授权。
 *  @param permissions  权限列表
 *  @param func         回调函数
 */
- (void)checkPermissions:(NSArray*)permissions :(NSString*)type :(void(^)(BOOL))func {
    assert(permissions && [permissions count]>0);
    NSDictionary* permissionDict = [self isGrantedPermissions:permissions];
    NSMutableArray* needGrantPermissions = [NSMutableArray array];
    NSArray* permissionKeys = [permissionDict allKeys];
    for (int i=0; i<[permissionKeys count]; i++) {
        NSString* permissionKey = permissionKeys[i];
        NSNumber* nsNumber = [permissionDict objectForKey:permissionKey];
        BOOL isGranted = [nsNumber boolValue];
        if (!isGranted) {
            [needGrantPermissions addObject:permissionKey];
        }
    }
    if ([needGrantPermissions count] <= 0) {
        func(true);
    } else {
        [self grantPermissions:needGrantPermissions :type :^(BOOL isSuccess) {
            if (isSuccess) {
                func(true);
            } else {
                func(false);
            }
        }];
    }
}

#pragma mark - public method

- (void)openFacebookPage:(NSString *)installUrl :(NSString *)url {
    if(![[UIApplication sharedApplication] openURL:[NSURL URLWithString:installUrl]])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

- (void)setLoginFunc:(void (^)(NSString *, NSString *))func {
    _loginFunc = func;
}

- (void)setAppLinkFunc:(void (^)(NSDictionary *))func {
    _applinkFunc = func;
}

- (BOOL)isLogin {
    FBSDKAccessToken* accessToken = [FBSDKAccessToken currentAccessToken];
    if (accessToken == nil) {
        return NO;
    }
    return YES;
}

- (void)login {
    [self checkPermissions:@[@"public_profile", @"email"] :PERMISSION_READ :^(BOOL isSuccess) {
        NSLog(@"login %@", isSuccess?@"SUCCESS":@"FAILED");
    }];
}

- (NSString *)getUserID {
    FBSDKAccessToken* accessToken = [FBSDKAccessToken currentAccessToken];
    return accessToken.userID;
}

- (NSString *)getAccessToken {
    FBSDKAccessToken* accessToken = [FBSDKAccessToken currentAccessToken];
    return accessToken.tokenString;
}

- (void)logout {
    [FBSDKAccessToken setCurrentAccessToken:nil];
    [FBSDKProfile setCurrentProfile:nil];
}

- (void)getUserProfileWithId:(NSString *)fid andPicSize:(int)picSize cb:(void (^)(NSDictionary *))func {
    fid = fid == nil ? @"me" : fid;
    [self checkPermissions:@[@"public_profile"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(nil);
            return;
        }
        NSString* graphPath = [NSString stringWithFormat:@"/%@?fields=id,name,picture.height(%d).width(%d),email", fid, picSize, picSize];
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
            func(result);
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)getInvitableFriendsWithInviteToken:(NSArray *)inviteTokens picSize:(int)picSize cb:(void (^)(NSDictionary *))func {
    [self checkPermissions:@[@"user_friends"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(nil);
            return;
        }
        NSString* graphPath = [NSString stringWithFormat:@"/me/invitable_friends?limit=5000&fields=name,picture.width(%d).height(%d)", picSize, picSize];
        if (inviteTokens != nil && [inviteTokens count] > 0) {
            NSString* inviteTokensStr = [inviteTokens componentsJoinedByString:@"','"];
            graphPath = [NSString stringWithFormat:@"%@&excluded_ids=['%@']", graphPath, inviteTokensStr];
        }
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
            func(result);
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)getFriendsWithPicSize:(int)picSize cb:(void (^)(NSDictionary *))func {
    [self checkPermissions:@[@"user_friends"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(nil);
            return;
        }
        NSString *graphPath = [NSString stringWithFormat:@"/me/friends?fields=id,name,picture.width(%d).height(%d)", picSize, picSize];
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
            func(result);
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)confirmRequest:(NSArray *)fidOrTokens withTitle:(NSString *)title withMsg:(NSString *)msg cb:(void (^)(NSDictionary *))func {
    [self checkPermissions:@[@"public_profile"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(nil);
            return;
        }
        FBSDKGameRequestContent *gameRequestContent = [[FBSDKGameRequestContent alloc] init];
        gameRequestContent.title = title;
        gameRequestContent.message = msg;
        gameRequestContent.recipients = fidOrTokens;
        
        FBSDKGameRequestDialog* gameRequestDialog = [[FBSDKGameRequestDialog alloc] init];
        gameRequestDialog.content = gameRequestContent;
        gameRequestDialog.delegate = self;
        gameRequestDialog.frictionlessRequestsEnabled = YES;
        [gameRequestDialog show];
        
        _requestFunc = func;
    }];
}

- (void)queryRequest:(void (^)(NSDictionary *))func {
    [self checkPermissions:@[@"public_profile"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(nil);
            return;
        }
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:@"/me/apprequests?fields=id,message,from,created_time"
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
            func(result);
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)acceptRequest:(NSString *)requestId cb:(void (^)(BOOL))func {
    [self checkPermissions:@[@"public_profile"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(NO);
            return;
        }
        NSString* graphPath = [NSString stringWithFormat:@"/%@", requestId];
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:nil
                                      HTTPMethod:@"DELETE"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            BOOL ret = NO;
            if (error) {
                NSLog(@"%@", error);
            } else {
                ret = [[result objectForKey:@"success"] boolValue];
            }
            func(ret);
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)shareName:(NSString *)name description:(NSString *)description imageUrl:(NSString *)imageUrl contentUrl:(NSString *)contentUrl caption:(NSString *)caption :(void (^)(BOOL))func {
    [self checkPermissions:@[@"publish_actions"] :PERMISSION_PUBLISH :^(BOOL result) {
        if (!result) {
            func(NO);
            return;
        }
        NSString* graphPath = @"/me/feed";
        NSMutableDictionary* param = [NSMutableDictionary dictionary];
        [param setValue:contentUrl forKey:@"link"];
        [param setValue:imageUrl forKey:@"picture"];
        [param setValue:name forKey:@"name"];
        [param setValue:description forKey:@"description"];
        [param setValue:caption forKey:@"caption"];
        FBSDKGraphRequest* request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:param
                                      HTTPMethod:@"POST"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            BOOL ret = NO;
            if (error) {
                NSLog(@"%@", error);
            } else {
                ret = YES;
            }
            func(ret);
        }];
    }];
}

- (void)setScore:(int)score {
    [self checkPermissions:@[@"publish_actions"] :PERMISSION_PUBLISH :^(BOOL result) {
        if (!result) {
            return;
        }
        NSString* graphPath = @"/me/scores";
        NSDictionary* param = @{@"score":[NSNumber numberWithInt:score]};
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:param
                                      HTTPMethod:@"POST"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            }
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)getScoreWithId:(NSString *)fid cb:(void (^)(int))func {
    [self checkPermissions:@[@"user_friends"] :PERMISSION_READ :^(BOOL result) {
        if (!result) {
            func(-1);
            return;
        }
        NSString* graphPath = [NSString stringWithFormat:@"/%@/scores?fields=score,application,user", fid];
        FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                      initWithGraphPath:graphPath
                                      parameters:nil
                                      HTTPMethod:@"GET"];
        [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                              id result,
                                              NSError *error) {
            int level = -1;
            if (error) {
                NSLog(@"%@", error);
            } else {
                NSArray* dataArr = result[@"data"];
                if ([dataArr count] >= 1) {
                    NSDictionary* data = dataArr[0];
                    level = [data[@"score"] intValue];
                }
            }
            func(level);
        }].timeout = GRAPH_API_TIMEOUT;
    }];
}

- (void)inviteFriendsWithLink:(NSString *)linkUrl andImg:(NSString *)imgUrl withBlock:(void (^)(BOOL))block {
    _inviteBlock = block;
    FBSDKAppInviteContent *content =[[FBSDKAppInviteContent alloc] init];
    content.appLinkURL = [NSURL URLWithString:linkUrl];
    //optionally set previewImageURL
    if (imgUrl && imgUrl.length > 0) {
        content.appInvitePreviewImageURL = [NSURL URLWithString:imgUrl];
    }
    // Present the dialog. Assumes self is a view controller
    // which implements the protocol `FBSDKAppInviteDialogDelegate`.
    [FBSDKAppInviteDialog showWithContent:content delegate:self];
}

#pragma mark - FBSDKGameRequestDialogDelegate

- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didCompleteWithResults:(NSDictionary *)results {
    _requestFunc(results);
}

- (void)gameRequestDialog:(FBSDKGameRequestDialog *)gameRequestDialog didFailWithError:(NSError *)error {
    _requestFunc(nil);
}

- (void)gameRequestDialogDidCancel:(FBSDKGameRequestDialog *)gameRequestDialog {
    _requestFunc(nil);
}

#pragma mark - FBSDKAppInviteDialogDelegate

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didCompleteWithResults:(NSDictionary *)results {
    NSLog(@"appInviteDialog:didCompleteWithResults%@", results);
    if (!results) {
        _inviteBlock(NO);
        return;
    }
    NSString* completionGesture = [results objectForKey:@"completionGesture"];
    if ([completionGesture isEqualToString:@"cancel"]) {
        _inviteBlock(NO);
    } else {
        _inviteBlock(YES);
    }
}

- (void)appInviteDialog:(FBSDKAppInviteDialog *)appInviteDialog didFailWithError:(NSError *)error {
    NSLog(@"appInviteDialog:didFailWithError%@", error);
    _inviteBlock(NO);
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#if DEBUG
    [FBSDKSettings enableLoggingBehavior:FBSDKLoggingBehaviorAppEvents];
#endif
    [FBSDKProfile enableUpdatesOnAccessTokenChange:YES];
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                    didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    BFURL* parsedUrl = [BFURL URLWithInboundURL:url sourceApplication:sourceApplication];
    NSDictionary* appLinkData = [parsedUrl appLinkData];
    if (appLinkData && _applinkFunc) {
        _applinkFunc(appLinkData);
    }
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    
}

#pragma mark - AnalyticDelegate

- (void)setAccoutInfo:(NSDictionary *)dict {
    
}

- (void)onEvent:(NSString *)eventId {
    [FBSDKAppEvents logEvent:eventId];
}

- (void)onEvent:(NSString *)eventId Label:(NSString *)label {
    NSDictionary *params = @{@"key" : label};
    [FBSDKAppEvents logEvent:eventId parameters:params];
}

- (void)onEvent:(NSString *)eventId eventData:(NSDictionary *)userInfo {
    [FBSDKAppEvents logEvent:eventId parameters:userInfo];
}

- (void)setLevel:(int)level {
    NSDictionary *params = @{FBSDKAppEventParameterNameLevel : [NSString stringWithFormat:@"%d", level]};
    [FBSDKAppEvents logEvent:FBSDKAppEventNameAchievedLevel parameters:params];
}

- (void)charge:(NSString *)name :(double)cash :(double)coin :(int)type {
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    [parameters setObject:[NSNumber numberWithDouble:coin] forKey:@"coin"];
    [parameters setObject:[NSString stringWithFormat:@"%d", type] forKey:@"type"];
    [FBSDKAppEvents logPurchase:cash currency:@"USD" parameters:parameters];
    
    NSDictionary *params = @{@"chips" : @(coin)};
    [FBSDKAppEvents logEvent:@"Buy Chips" valueToSum:true parameters:params];
}

- (void)charge:(SKPaymentTransaction *)transaction {
    
}

- (void)reward:(double)coin :(int)type {
    NSDictionary *params = @{@"chips" : @(coin)};
    [FBSDKAppEvents logEvent:@"Reward Chips" valueToSum:true parameters:params];
}

- (void)purchase:(NSString *)name :(int)amount :(double)coin {
    
}

- (void)use:(NSString *)name :(int)amount :(double)coin {
    NSDictionary *params = @{@"chips" : @(coin)};
    [FBSDKAppEvents logEvent:@"Spent Chips" valueToSum:true parameters:params];
}

- (void)missionStart:(NSString *)missionId {
    [self onEvent:@"Mission Start" Label:missionId];
}

- (void)missionSuccess:(NSString *)missionId {
    NSDictionary *params = @{@"result" : @(1)};
    [self onEvent:@"Mission Ended" eventData:params];
}

- (void)missionFailed:(NSString *)missionId because:(NSString *)reason {
    NSDictionary *params = @{@"result" : @(0), @"reason" : reason};
    [self onEvent:@"Mission Ended" eventData:params];
}

- (NSString *)getName {
    return @"Facebook";
}

@end
