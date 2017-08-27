//
//  NTESMeetingControlAttachment.h
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESCustomAttachmentDefines.h"

typedef NS_ENUM(NSInteger, CustomMeetingCommand) {
    CustomMeetingCommandNotifyActorsList     = 1,//主持人通知所有有权限发言的用户列表，聊天室消息，需要携带uids
    CustomMeetingCommandAskForActors         = 2,//参与者询问其他人是否有权限发言，聊天室消息
    CustomMeetingCommandActorReply           = 3,//有发言权限的人反馈，点对点消息，需要携带uids
    CustomMeetingCommandRaiseHand            = 10,//参与者向主持人申请发言权限，点对点消息
    CustomMeetingCommandEnableActor          = 11,//主持人开启参与者的发言请求，点对点消息
    CustomMeetingCommandDisableActor         = 12,//主持人关闭某人发言权限，点对点消息
    CustomMeetingCommandCancelRaiseHand      = 13,//参与者向主持人取消申请发言权限，点对点消息
};

@interface NTESMeetingControlAttachment : NSObject<NIMCustomAttachment>

@property (nonatomic,copy)      NSString *roomID;

@property (nonatomic,assign)    CustomMeetingCommand command;

@property (nonatomic,strong)    NSArray *uids;


@end
