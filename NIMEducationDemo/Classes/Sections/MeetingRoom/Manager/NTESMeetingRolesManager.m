//
//  NTESMeetingRolesManager.m
//  NIMEducationDemo
//
//  Created by fenric on 16/4/17.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMeetingRolesManager.h"
#import "NTESMeetingRole.h"
#import "NTESMeetingMessageHandler.h"
#import "NTESSessionMsgConverter.h"
#import "NTESMeetingControlAttachment.h"
#import "NTESTimerHolder.h"
#import <NIMAVChat/NIMAVChat.h>
#import "NSDictionary+NTESJson.h"


@interface NTESMeetingRolesManager()<NTESMeetingMessageHandlerDelegate, NTESTimerHolderDelegate>

@property(nonatomic, strong) NIMChatroom *chatroom;

@property(nonatomic, strong) NSMutableDictionary *meetingRoles;

@property(nonatomic, strong) NTESMeetingMessageHandler *messageHandler;

@property(nonatomic, assign) BOOL receivedRolesFromManager;

@property(nonatomic, strong) NSMutableArray *pendingJoinUsers;

@end

@implementation NTESMeetingRolesManager

- (void)startNewMeeting:(NIMChatroomMember *)me
           withChatroom:(NIMChatroom *)chatroom
             newCreated:(BOOL)newCreated
{
    _meetingRoles = [[NSMutableDictionary alloc] initWithCapacity:1];
    _chatroom = chatroom;
    
    [self addNewRole:me.userId asActor:(me.type == NIMChatroomMemberTypeCreator)];
    
    _messageHandler = [[NTESMeetingMessageHandler alloc] initWithChatroom:chatroom delegate:self];
    
    _receivedRolesFromManager = NO;
    
    _pendingJoinUsers = [NSMutableArray array];
    
    if ([self myRole].isManager && (!newCreated)) {
        [self sendAskForActors];
    }
    
    if (!newCreated) {
        NTESTimerHolder *timerHolder = [[NTESTimerHolder alloc] init];
        [timerHolder startTimer:2 delegate:self repeats:NO];
    }
}

- (BOOL)kick:(NSString *)user
{
    if ([self role:user]) {
        [_meetingRoles removeObjectForKey:user];
        [self notifyMeetingRolesUpdate];
        return YES;
    }
    else {
        return NO;
    }
}

- (NTESMeetingRole *)role:(NSString *)user
{
    return [_meetingRoles objectForKey:user];
}

- (NTESMeetingRole *)memberRole:(NIMChatroomMember *)member
{
    NTESMeetingRole *role = [self role:member.userId];
    if (!role) {
        role = [self addNewRole:member.userId asActor:NO];
    }
    return role;
}

- (NTESMeetingRole *)myRole
{
    NSString *myUid = [[NIMSDK sharedSDK].loginManager currentAccount];
    
    return [self role:myUid];

}

- (void)setMyVideo:(BOOL)on
{
    NTESMeetingRole *role = [self myRole];
    
    if ([[NIMAVChatSDK sharedSDK].netCallManager setCameraDisable:!on]) {
        role.videoOn = on;
    }
    
    [self notifyMeetingRolesUpdate];
}


- (void)setMyAudio:(BOOL)on
{
    NTESMeetingRole *role = [self myRole];
        
    if ([[NIMAVChatSDK sharedSDK].netCallManager setMute:!on]) {
        role.audioOn = on;
    }
    
    [self notifyMeetingRolesUpdate];
}

- (void)setMyWhiteBoard:(BOOL)on
{
    NTESMeetingRole *role = [self myRole];
    role.whiteboardOn = on;
    [self notifyMeetingRolesUpdate];
}

- (NSArray *)allActors
{
    NSMutableArray *actors;
    for (NTESMeetingRole *role in _meetingRoles.allValues) {
        
        NSString *actor = role.uid;
        if (role.isActor) {
            if (!actors) {
                actors = [[NSMutableArray alloc] initWithObjects:actor, nil];
            }
            else {
                
                [actors addObject:actor];
            }
        }
    }
    return actors;
}

-(BOOL)isActorMemberReachFour
{
    //遍历判断互动人数是否大于4人
    int isActorCount = 0;
    for (NTESMeetingRole *role in _meetingRoles.allValues) {
        if (role.isActor) {
            isActorCount++;
        }
    }
    if (isActorCount>=4) {
        return YES;
    }
    else
        return NO;
}

- (void)changeRaiseHand
{
    NTESMeetingRole *myRole = [self myRole];
    myRole.isRaisingHand = !myRole.isRaisingHand;
    [self sendRaiseHand:myRole.isRaisingHand];
    [self notifyMeetingRolesUpdate];
    [self sendActorsListBroadcast];
}

- (void)changeMemberActorRole:(NSString *)user;
{
    NTESMeetingRole *role = [self role:user];
    
    if (!role) {
        role = [self addNewRole:user asActor:NO];
    }
    
    //判断互动人数是否达到4人，若达到弹出toast 互动人数已满
    if (!role.isActor && [self exceedMaxActorsNumber]) {
        [self notifyMeetingActorsNumberExceedMax];
        DDLogError(@"Error setting member %@ to actor: Exceeds max actors number.", user);
        return;
    }
    
    role.isActor = !role.isActor;
    role.isRaisingHand = NO;
    [self notifyMeetingRolesUpdate];
    [self sendControlActor:role.isActor to:user];
    [self sendActorsListBroadcast];
    
}

- (void)updateMeetingUser:(NSString *)user isJoined:(BOOL)joined
{
    NTESMeetingRole *role = [self role:user];
    
    if (!role) {
        role = [self addNewRole:user asActor:NO];
    }
    
    if (role.isJoined != joined) {
        role.isJoined = joined;
        DDLogInfo(@"Set user %@ joined:%zd", role.uid, role.isJoined);
        if (!joined) {
            if (![user isEqualToString:_chatroom.creator]) {
                role.isActor = NO;
            }
        }
        [self notifyMeetingRolesUpdate];
    }
}

- (void)updateVolumes:(NSDictionary<NSString *, NSNumber *> *)volumes
{
    for (NSString *meetingUser in _meetingRoles.allKeys) {
        NSNumber *volumeNumber = [volumes objectForKey:meetingUser];
        UInt16 volume = volumeNumber ? volumeNumber.shortValue : 0;
        NTESMeetingRole *role = [self role:meetingUser];
        role.audioVolume = volume;
    }
    [self notifyMeetingVolumesUpdate];
}

#pragma mark - NTESMeetingMessageHandlerDelegate
- (void)onMembersEnterRoom:(NSArray *)members
{
    [self notifyChatroomMembersUpdate:members entered:YES];
    BOOL sendNotify = NO;
    BOOL managerEnterRoom = NO;
    
    for (NIMChatroomNotificationMember *member in members) {
        if ([self myRole].isManager) {
            if (![member.userId isEqualToString:[self myRole].uid]) {
                [_messageHandler sendMeetingP2PCommand:[self actorsListAttachment] to:member.userId];
                sendNotify = YES;
            }
        }
        else {
            if ([member.userId isEqualToString:_chatroom.creator]) {
                managerEnterRoom = YES;
            }
        }
    }
    if (sendNotify) {
        [self notifyMeetingRolesUpdate];
    }
    if (managerEnterRoom && [self myRole].isRaisingHand) {
        [self sendRaiseHand:YES];
    }
}

- (void)onMembersExitRoom:(NSArray *)members
{
    [self notifyChatroomMembersUpdate:members entered:NO];

    if ([self myRole].isManager) {
        BOOL needNotify = NO;
        for (NIMChatroomNotificationMember *member in members) {
            NTESMeetingRole *role = [self role:member.userId];
            if (role.isActor) {
                role.isActor = NO;
                needNotify = YES;
            }
        }
        if (needNotify) {
            [self sendActorsListBroadcast];
        }
    }
    else {
        for (NIMChatroomNotificationMember *member in members) {
            if ([member.userId isEqualToString:_chatroom.creator]) {
                [self myRole].isRaisingHand = NO;
            }
        }
    }
    [self notifyMeetingRolesUpdate];
}

- (void)onReceiveMeetingCommand:(NTESMeetingControlAttachment *)attachment from:(NSString *)userId
{
    switch (attachment.command) {
        case CustomMeetingCommandNotifyActorsList:
            if (![self myRole].isManager) {
                [self updateRolesFromManager:attachment.uids];
            }
            break;
        case CustomMeetingCommandAskForActors:
            [self reportActor:userId];
            break;
        case CustomMeetingCommandActorReply:
            if ([self myRole].isManager) {
                [self recoverActor:userId];
            }
            else if (!_receivedRolesFromManager) {
                [self recoverActor:userId];
            }
            break;
    
        case CustomMeetingCommandRaiseHand:
            if ([self myRole].isManager) {
                [self dealRaiseHandRequest:YES from:userId];
            }
            break;
            
        case CustomMeetingCommandCancelRaiseHand:
            if ([self myRole].isManager) {
                [self dealRaiseHandRequest:NO from:userId];
            }
            break;
            
        case CustomMeetingCommandEnableActor:
            [self changeToActor];
            break;
            
        case CustomMeetingCommandDisableActor:
            [self changeToViewer:YES];
            break;
            
        default:
            break;
    }
}

-(void)onMembersShowFullScreen:(NSString*)notifyExt
{
    [self notifyMeetingRolesShowFullScreen:notifyExt];
}

#pragma mark - NTESTimerHolder
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    if ([self myRole].isManager) {
        [self sendActorsListBroadcast];
    }
    else if (!_receivedRolesFromManager) {
        [self sendAskForActors];
    }
}


#pragma mark - private

- (NTESMeetingRole *)addNewRole:(NSString *)uid asActor:(BOOL)actor
{
    DDLogInfo(@"Add new role : %@, is actor : %@", uid, actor ? @"YES" : @"NO");
    NTESMeetingRole *newRole = [[NTESMeetingRole alloc] init];
    
    newRole.uid = uid;
    newRole.isManager = [self isManager:uid];
    newRole.isActor = newRole.isManager ? YES : actor; //主持人默认都是actor
    newRole.audioOn = actor;
    newRole.videoOn = actor;
    newRole.whiteboardOn = actor;
    
    if ([self.pendingJoinUsers containsObject:uid]) {
        newRole.isJoined = YES;
        DDLogInfo(@"Set pending user %@ joined.", newRole.uid);
        [self.pendingJoinUsers removeObject:uid];
    }
    
    [_meetingRoles setObject:newRole forKey:uid];
    
    [self notifyMeetingRolesUpdate];
    
    return newRole;
}


- (void)changeToActor
{
    if (![self myRole].isActor) {
        [self notifyMeetingActorBeenEnabled];
        [self myRole].isActor = YES;
        [self myRole].isRaisingHand = NO;
        [self myRole].audioOn = NO;
        [self myRole].videoOn = NO;
        [self myRole].whiteboardOn = NO;
        
        [[NIMAVChatSDK sharedSDK].netCallManager setMeetingRole:YES];
        [[NIMAVChatSDK sharedSDK].netCallManager setMute:![self myRole].audioOn];
        [[NIMAVChatSDK sharedSDK].netCallManager setCameraDisable:![self myRole].videoOn];
        
        [self notifyMeetingRolesUpdate];
    }
}

- (void)changeToViewer:(BOOL)cancelRaiseHand
{
    if ([self myRole].isActor) {
        [[NIMAVChatSDK sharedSDK].netCallManager setMeetingRole:NO];
        [self myRole].isActor = NO;
        [self notifyMeetingActorBeenDisabled];
    }
    
    if (cancelRaiseHand) {
        [self myRole].isRaisingHand = NO;
    }
    [self myRole].audioOn = NO;
    [self myRole].videoOn = NO;
    [self myRole].whiteboardOn = NO;
    [self notifyMeetingRolesUpdate];

}

- (void)reportActor:(NSString *)user
{
    if ([self myRole].isActor) {
        [self sendReportActor:user];
    }
}

- (void)updateRolesFromManager:(NSArray *)actorsMember
{
    _receivedRolesFromManager = YES;
    
    if ([actorsMember containsObject:[self myRole].uid]) {
        [self changeToActor];
    }
    else {
        [self changeToViewer:NO];
    }
    
    for (NTESMeetingRole *role in _meetingRoles.allValues) {
        role.isActor = NO;
    }
    
    for (NSString *actorId in actorsMember) {
        NTESMeetingRole *role = [self role:actorId];
        if (!role) {
            [self addNewRole:actorId asActor:YES];
        }
        else {
            role.isActor = YES;
        }
    }
    
    [self notifyMeetingRolesUpdate];
}

- (BOOL)recoverActor:(NSString *)user
{
    NTESMeetingRole *role = [self role:user];
    
    if (!role) {
        
        role = [self addNewRole:user asActor:NO];
        
        if (![self exceedMaxActorsNumber]) {
            role.isActor = YES;
            [self notifyMeetingRolesUpdate];
        }
        else {
            DDLogError(@"Error setting member %@ to actor: Exceeds max actors number.", user);
        }
        return YES;
    }
    return NO;
}

- (NTESMeetingControlAttachment *)actorsListAttachment
{
    NTESMeetingControlAttachment *attachment = [[NTESMeetingControlAttachment alloc] init];
    attachment.command = CustomMeetingCommandNotifyActorsList;
    attachment.uids = [self allActors];
    return attachment;
}

- (void)dealRaiseHandRequest:(BOOL)raise from:(NSString *)user
{
    NTESMeetingRole *role = [self role:user];
    
    if (!role) {
        role = [self addNewRole:user asActor:NO];
    }
    else {
        role.isActor = NO;
    }
    
    role.isRaisingHand = raise;

    [self notifyMeetingRolesUpdate];
    if (raise) {
        [self notifyMeetingMemberRaiseHand];
    }
}

- (void)notifyMeetingRolesShowFullScreen:(NSString*)notifyExt
{
    if (self.delegate) {
        [self.delegate meetingRolesShowFullScreen:notifyExt];
    }

}
- (void)notifyMeetingRolesUpdate
{
    if (self.delegate) {
        [self.delegate meetingRolesUpdate];
    }
}

- (void)notifyMeetingMemberRaiseHand
{
    if (self.delegate) {
        [self.delegate meetingMemberRaiseHand];
    }
}

- (void)notifyMeetingActorBeenDisabled
{
    if (self.delegate) {
        [self.delegate meetingActorBeenDisabled];
    }
}

- (void)notifyMeetingActorBeenEnabled
{
    if (self.delegate) {
        [self.delegate meetingActorBeenEnabled];
    }
}

- (void)notifyMeetingActorsNumberExceedMax
{
    if (self.delegate) {
        [self.delegate meetingActorsNumberExceedMax];
    }
}

- (void)notifyMeetingVolumesUpdate
{
    if (self.delegate) {
        [self.delegate meetingVolumesUpdate];
    }
}

- (void)notifyChatroomMembersUpdate:(NSArray *)members entered:(BOOL)entered
{
    if (self.delegate) {
        [self.delegate chatroomMembersUpdated:members entered:entered];
    }
}

- (BOOL)exceedMaxActorsNumber
{
    return [self allActors].count >= 4;
}

- (BOOL)isManager:(NSString *)uid
{
    return [uid isEqualToString: _chatroom.creator];
}

#pragma mark - send message
- (void)sendRaiseHand:(BOOL)raiseOrCancel
{
    NTESMeetingControlAttachment *attachment = [[NTESMeetingControlAttachment alloc] init];
    attachment.command = raiseOrCancel ? CustomMeetingCommandRaiseHand : CustomMeetingCommandCancelRaiseHand;
    
    [_messageHandler sendMeetingP2PCommand:attachment to:_chatroom.creator];
}

- (void)sendControlActor:(BOOL)enable to:(NSString *)uid
{
    NTESMeetingControlAttachment *attachment = [[NTESMeetingControlAttachment alloc] init];
    attachment.command = enable ? CustomMeetingCommandEnableActor : CustomMeetingCommandDisableActor;
    
    [_messageHandler sendMeetingP2PCommand:attachment to:uid];
}

- (void)sendActorsListBroadcast
{
    [_messageHandler sendMeetingBroadcastCommand:[self actorsListAttachment]];
}

- (void)sendAskForActors
{
    NTESMeetingControlAttachment *attachment = [[NTESMeetingControlAttachment alloc] init];
    attachment.command = CustomMeetingCommandAskForActors;
    
        [_messageHandler sendMeetingBroadcastCommand:attachment];
    }

- (void)sendReportActor:(NSString *)user
{
    NTESMeetingControlAttachment *attachment = [[NTESMeetingControlAttachment alloc] init];
    attachment.command = CustomMeetingCommandActorReply;
    attachment.uids = [NSArray arrayWithObjects:[[NIMSDK sharedSDK].loginManager currentAccount], nil];
    [_messageHandler sendMeetingP2PCommand:attachment to:user];
}

@end
