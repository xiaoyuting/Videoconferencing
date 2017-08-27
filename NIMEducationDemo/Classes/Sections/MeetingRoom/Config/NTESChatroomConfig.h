//
//  NTESChatroomConfig.h
//  NIM
//
//  Created by chris on 15/12/14.
//  Copyright © 2015年 Netease. All rights reserved.
//

typedef NS_ENUM(NSInteger, NTESMediaButton)
{
    NTESMediaButtonJanKenPon,      //石头剪刀布
};

@interface NTESChatroomConfig : NSObject<NIMSessionConfig>

- (instancetype)initWithChatroom:(NSString *)roomId;

@end
