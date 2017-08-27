//
//  NTESMeetingMessageHandler.h
//  NIMEducationDemo
//
//  Created by fenric on 16/4/17.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NTESMeetingControlAttachment;

@protocol NTESMeetingMessageHandlerDelegate <NSObject>

- (void)onMembersEnterRoom:(NSArray *)members;

- (void)onMembersExitRoom:(NSArray *)members;

- (void)onMembersShowFullScreen:(NSString *)notifyExt;

- (void)onReceiveMeetingCommand:(NTESMeetingControlAttachment *)attachment from:(NSString *)userId;

@end


@interface NTESMeetingMessageHandler : NSObject

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom delegate:(id<NTESMeetingMessageHandlerDelegate>)delegate;

- (void)sendMeetingP2PCommand:(NTESMeetingControlAttachment *)attachment
                           to:(NSString *)uid;

- (void)sendMeetingBroadcastCommand:(NTESMeetingControlAttachment *)attachment;


@end
