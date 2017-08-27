//
//  NTESAppDelegate.m
//  NIMEducationDemo
//
//  Created by chris on 16/2/24.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESAppDelegate.h"
#import "NTESLoginViewController.h"
#import "NTESDemoConfig.h"
#import "NTESCustomAttachmentDecoder.h"
#import "NTESLoginManager.h"
#import "NTESEnterRoomViewController.h"
#import "NTESDataManager.h"
#import "NTESPageContext.h"
#import "NTESLogManager.h"

@interface NTESAppDelegate ()<NIMLoginManagerDelegate>

@end

@implementation NTESAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    
    //appkey是应用的标识，不同应用之间的数据（用户、消息、群组等）是完全隔离的。
    //如需打网易云信Demo包，请勿修改appkey，开发自己的应用时，请替换为自己的appkey.
    //并请对应更换Demo代码中的获取好友列表、个人信息等网易云信SDK未提供的接口。
    NSString *appKey = [[NTESDemoConfig sharedConfig] appKey];
    NSString *cerName= [[NTESDemoConfig sharedConfig] apnsCername];
    [[NIMSDK sharedSDK] registerWithAppID:appKey
                                  cerName:cerName];
    [NIMCustomObject registerCustomDecoder:[NTESCustomAttachmentDecoder new]];
    [[NIMKit sharedKit] setProvider:[NTESDataManager sharedInstance]];
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    
    [[NTESLogManager sharedManager] start];
    
    DDLogInfo(@"SDK Info: %@", [NIMSDKConfig sharedConfig]);
    
    [self setupMainViewController];
    
    return YES;
}

- (void)setupMainViewController
{
    NTESLoginData *data = [[NTESLoginManager sharedManager] currentNTESLoginData];
    NSString *account = [data account];
    NSString *token = [data token];
    if ([account length] && [token length])
    {
        [[[NIMSDK sharedSDK] loginManager] autoLogin:account
                                               token:token];
        [[NTESServiceManager sharedManager] start];
    }
    [[NTESPageContext sharedInstance] setupMainViewController];
}




@end
