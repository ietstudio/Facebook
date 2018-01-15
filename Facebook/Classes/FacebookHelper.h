//
//  FacebookHelper.h
//  Pods
//
//  Created by geekgy on 15/5/17.
//
//

#import <Foundation/Foundation.h>
#import <Bolts/Bolts.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "Macros.h"
#import "AnalyticDelegate.h"

@interface FacebookHelper : NSObject <UIApplicationDelegate, AnalyticDelegate, FBSDKGameRequestDialogDelegate, FBSDKAppInviteDialogDelegate>

SINGLETON_DECLARE(FacebookHelper)

/**
 *  打开facebook主页
 *
 *  @param installUrl   主页
 *  @param url          主页url
 */
- (void)openFacebookPage:(NSString*)installUrl :(NSString*)url;

/**
 *  设置Login回调
 *
 *  @param func         回调函数
 */
- (void)setLoginFunc:(void (^)(NSString* userId, NSString* token))func;

/**
 *  设置AppLink回调
 *
 *  @param func         回调函数
 */
- (void)setAppLinkFunc:(void (^)(NSDictionary *dict))func;

/**
 *  检测是否已经登陆
 *
 *  @return 是否已登陆
 */
- (BOOL)isLogin;

/**
 *  开始登陆
 */
- (void)login;

/**
 *  登出
 */
- (void)logout;

/**
 *  获取用户ID
 */
- (NSString*)getUserID;

/**
 *  获取accesstoken
 */
- (NSString*)getAccessToken;

/**
 获取用户信息，注意，登陆成功以后，用户信息同步是异步的

 @param fid             用户id
 @param picSize         头像大小
 @param func            回调函数
 */
- (void)getUserProfileWithId:(NSString*)fid andPicSize:(int)picSize cb:(void(^)(NSDictionary* dict))func;

/**
 *  获取可邀请的好友
 *
 *  @param inviteTokens 排除的token
 *  @param func         回调block
 */
- (void)getInvitableFriendsWithInviteToken:(NSArray*)inviteTokens picSize:(int)picSize cb:(void(^)(NSDictionary* friends))func;

/**
 *  获取游戏中的好友
 *
 *  @param func         回调block
 */
- (void)getFriendsWithPicSize:(int)picSize cb:(void(^)(NSDictionary* friends))func;

/**
 *  发送Request
 *
 *  @param fidOrTokens fid活着InviteToken
 *  @param title       标题（可选）
 *  @param msg         消息内容
 *  @param func        回调block
 */
- (void)confirmRequest:(NSArray*)fidOrTokens withTitle:(NSString*)title withMsg:(NSString*)msg cb:(void(^)(NSDictionary* result))func;

/**
 *  查询收到的Request
 *
 *  @param func         回调函数
 */
- (void)queryRequest:(void(^)(NSDictionary* requests))func;

/**
 *  删除request
 *
 *  @param requestId    requestId
 *  @param func         回调函数
 */
- (void)acceptRequest:(NSString*)requestId cb:(void(^)(BOOL result))func;

/**
 *  分享
 *
 *  @param name        标题
 *  @param description 描述
 *  @param imageUrl    图片url
 *  @param contentUrl  内容url
 */
- (void)shareName:(NSString*)name description:(NSString*)description imageUrl:(NSString*)imageUrl contentUrl:(NSString*)contentUrl caption:(NSString*)caption :(void(^)(BOOL result))func;

/**
 *  设置玩家分数
 *
 *  @param score 等级
 */
- (void)setScore:(int)score;

/**
 *  获取好友等级
 *
 *  @param fid          玩家fid
 *  @param func         回调函数
 */
- (void)getScoreWithId:(NSString*)fid cb:(void(^)(int score))func;

/**
 邀请好友

 @param linkUrl         deepLink
 @param imgUrl          图片Url
 @param block           回调函数
 */
- (void)inviteFriendsWithLink:(NSString*)linkUrl andImg:(NSString*)imgUrl withBlock:(void(^)(BOOL result))block;

@end
