//
//  NTESMeetingMessageHandler.m
//  NIMEducationDemo
//
//  Created by fenric on 16/4/17.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMeetingMessageHandler.h"
#import "NTESMeetingControlAttachment.h"
#import "NSDictionary+NTESJson.h"
#import "NTESSessionMsgConverter.h"

@interface NTESMeetingMessageHandler()<NIMChatManagerDelegate, NIMSystemNotificationManagerDelegate>

@property(nonatomic, strong) NIMChatroom *chatroom;

@property(nonatomic, weak) id<NTESMeetingMessageHandlerDelegate> delegate;

@end

@implementation NTESMeetingMessageHandler

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom delegate:(id<NTESMeetingMessageHandlerDelegate>)delegate
{
    if (self = [super init]) {
        _chatroom = chatroom;
        _delegate = delegate;
        [[NIMSDK sharedSDK].chatManager addDelegate:self];
        [[NIMSDK sharedSDK].systemNotificationManager addDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [[NIMSDK sharedSDK].chatManager removeDelegate:self];
    [[NIMSDK sharedSDK].systemNotificationManager removeDelegate:self];
}

#pragma mark - NIMChatManagerDelegate

- (void)onRecvMessages:(NSArray *)messages
{
    for (NIMMessage *message in messages) {
        if (message.session.sessionType == NIMSessionTypeChatroom) {
            
            if(message.messageType == NIMMessageTypeCustom) {
                [self dealCustomMessage:message];
            }
            else if (message.messageType == NIMMessageTypeNotification) {
                [self dealNotificationMessage:message];
            }
        }
    }
}


- (void)dealCustomMessage:(NIMMessage *)message
{
    NIMCustomObject *object = message.messageObject;
    
    //只处理会议控制自定义消息
    if (![object.attachment isKindOfClass:[NTESMeetingControlAttachment class]]) {
        return;
    }
    
    NTESMeetingControlAttachment *attachment  = (NTESMeetingControlAttachment *)object.attachment;
    
    if ([attachment.roomID isEqualToString:_chatroom.roomId]) {
        [self onMeetingCommand:attachment from:message.from];
    }
    else {
        DDLogInfo(@"Receive chatroom command from another meeting %@, drop it.", attachment.roomID);
    }
}

- (void)dealNotificationMessage:(NIMMessage *)message
{
    NIMNotificationObject *object = message.messageObject;
    
    if (object.notificationType != NIMNotificationTypeChatroom) {
        return;
    }
    
    NIMChatroomNotificationContent *content = (NIMChatroomNotificationContent *)object.content;

    switch (content.eventType) {
        case NIMChatroomEventTypeEnter:
            [_delegate onMembersEnterRoom:content.targets];
            break;
        case NIMChatroomEventTypeExit:
            [_delegate onMembersExitRoom:content.targets];
            break;
        case NIMChatroomEventTypeInfoUpdated:
            [_delegate onMembersShowFullScreen:content.notifyExt];
            break;
        default:
            break;
    }
}

- (void)onReceiveCustomSystemNotification:(NIMCustomSystemNotification *)notification
{
    if (notification.receiverType == NIMSessionTypeP2P) {
        NSString *content = notification.content;
        NSData *jsonData = [content dataUsingEncoding:NSUTF8StringEncoding];
        if (jsonData) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                 options:0
                                                                   error:nil];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                if ([dict jsonInteger:CMType] == CustomMessageTypeMeetingControl) {
                    NSDictionary *data = [dict jsonDict:CMData];
                    
                    NTESMeetingControlAttachment *attachment = [[NTESMeetingControlAttachment alloc] init];
                    attachment.roomID = [data jsonString:CMRoomID];
                    attachment.command = [data jsonInteger:CMCommand];
                    attachment.uids = [data jsonArray:CMUIDs];
                    
                    if ([attachment.roomID isEqualToString:_chatroom.roomId]) {
                        [self onMeetingCommand:attachment from:notification.sender];
                    }
                    else {
                        DDLogInfo(@"Receive p2p command from another meeting %@, drop it.", attachment.roomID);
                    }
                }
            }
        }
    }
}

- (void)onMeetingCommand:(NTESMeetingControlAttachment *)attachment from:(NSString *)user
{
    if (![attachment.roomID isEqualToString:_chatroom.roomId]) {
        return;
    }
    DDLogInfo(@"Receive meeting command from %@, attachment [ %@ ]", user, attachment);
    
    [_delegate onReceiveMeetingCommand:attachment from:user];
}

- (void)sendMeetingP2PCommand:(NTESMeetingControlAttachment *)attachment
                           to:(NSString *)uid
{
    attachment.roomID = _chatroom.roomId;
    
    DDLogInfo(@"Send meeting p2p command to %@, attachment [ %@ ]", uid, attachment);
    
    NSString *content = [attachment encodeAttachment];
    
    NIMCustomSystemNotification *notification = [[NIMCustomSystemNotification alloc] initWithContent:content];
    notification.sendToOnlineUsersOnly = YES;
    NIMCustomSystemNotificationSetting *setting = [[NIMCustomSystemNotificationSetting alloc] init];
    setting.shouldBeCounted = NO;
    setting.apnsEnabled = NO;
    notification.setting = setting;
    [[NIMSDK sharedSDK].systemNotificationManager sendCustomNotification:notification
                                                               toSession:[NIMSession session:uid type:NIMSessionTypeP2P]
                                                              completion:^(NSError *error) {
                                                                    if (error) {
                                                                        DDLogInfo(@"sendMeetingP2PCommand error:%zd",error.code);
                                                                    }
                                                                }];
}

- (void)sendMeetingBroadcastCommand:(NTESMeetingControlAttachment *)attachment
{
    attachment.roomID = _chatroom.roomId;
    
    DDLogInfo(@"Send meeting broadcast command, attachment [ %@ ]", attachment);

    NIMMessage *message = [NTESSessionMsgConverter msgWithMeetingControlAttachment:attachment];
    
    [[NIMSDK sharedSDK].chatManager sendMessage:message
                                      toSession:[NIMSession session:_chatroom.roomId type:NIMSessionTypeChatroom]
                                          error:nil];
}

@end
