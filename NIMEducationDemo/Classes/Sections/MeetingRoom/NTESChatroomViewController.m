//
//  NTESChatroomViewController.m
//  NIM
//
//  Created by chris on 15/12/11.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomViewController.h"
#import "NTESChatroomConfig.h"
#import "NTESJanKenPonAttachment.h"
#import "NTESSessionMsgConverter.h"
#import "NTESMeetingManager.h"
#import "NTESMeetingControlAttachment.h"

@interface NTESChatroomViewController ()<NIMInputDelegate>

@property (nonatomic,strong) NTESChatroomConfig *config;

@property (nonatomic,strong) NIMChatroom *chatroom;

@end

@implementation NTESChatroomViewController

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom
{
    self = [super initWithSession:[NIMSession session:chatroom.roomId type:NIMSessionTypeChatroom]];
    if (self) {
        _chatroom = chatroom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.layoutManager.delegate = self;
    
    //去掉刷新
    [self.refreshControl removeFromSuperview];
    [self.refreshControl removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];

}

- (id<NIMSessionConfig>)sessionConfig{
    return self.config;
}


- (void)onTapMediaItem:(NIMMediaItem *)item
{
    switch (item.tag) {
        case NTESMediaButtonJanKenPon:
        {
            NTESJanKenPonAttachment *attachment = [[NTESJanKenPonAttachment alloc] init];
            attachment.value = arc4random() % 3 + 1;
            [self sendMessage:[NTESSessionMsgConverter msgWithJenKenPon:attachment]];
            break;
        }
        default:
            break;
    }
}

- (void)sendMessage:(NIMMessage *)message
{
    NIMChatroomMember *member = [[NTESMeetingManager sharedInstance] myInfo:self.chatroom.roomId];
    message.remoteExt = @{@"type":@(member.type)};
    [super sendMessage:message];
}

#pragma mark - NIMInputDelegate
- (void)showInputView
{
    if ([self.delegate respondsToSelector:@selector(showInputView)]) {
        [self.delegate showInputView];
    }
}


- (void)hideInputView
{
    if ([self.delegate respondsToSelector:@selector(hideInputView)]) {
        [self.delegate hideInputView];
    }
}


#pragma mark -  filter messages
- (void)onRecvMessages:(NSArray *)messages
{
    NSMutableArray *filteredMessages = [NSMutableArray arrayWithArray:messages];
    for (NIMMessage *message in messages) {
        if ([self isMeetingControlMessage:message]) {
            [filteredMessages removeObject:message];
        }
    }
    [super onRecvMessages:filteredMessages];
}

- (void)willSendMessage:(NIMMessage *)message
{
    if (![self isMeetingControlMessage:message]) {
        [super willSendMessage:message];
    }
}

-(void)sendMessage:(NIMMessage *)message progress:(CGFloat)progress
{
    if (![self isMeetingControlMessage:message]) {
        [super sendMessage:message progress:progress];
    }
}


- (void)sendMessage:(NIMMessage *)message didCompleteWithError:(NSError *)error
{
    if (![self isMeetingControlMessage:message]) {
        [super sendMessage:message didCompleteWithError:error];
    }
}



#pragma mark - Get
- (NTESChatroomConfig *)config{
    if (!_config) {
        _config = [[NTESChatroomConfig alloc] initWithChatroom:self.chatroom.roomId];
    }
    return _config;
}

#pragma mark - private

- (BOOL)isMeetingControlMessage:(NIMMessage *)message
{
    if (message.session.sessionType == NIMSessionTypeChatroom) {
        if(message.messageType == NIMMessageTypeCustom) {
            NIMCustomObject *object = message.messageObject;
            if ([object.attachment isKindOfClass:[NTESMeetingControlAttachment class]]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
