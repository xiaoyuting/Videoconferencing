//
//  NTESMeetingRTSManager.m
//  NIMEducationDemo
//
//  Created by fenric on 16/10/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMeetingRTSManager.h"
#import <NIMAVChat/NIMAVChat.h>
#import "NTESBundleSetting.h"

#define NTESRTSConferenceManager [NIMAVChatSDK sharedSDK].rtsConferenceManager

@interface NTESMeetingRTSManager()<NIMRTSConferenceManagerDelegate>

@property (nonatomic, strong) NIMRTSConference  *currentConference;

@end

@implementation NTESMeetingRTSManager

- (instancetype) init {
    if (self = [super init]) {
        [NTESRTSConferenceManager addDelegate:self];
    }
    return self;
}

- (void)dealloc
{
    [self leaveCurrentConference];
    [NTESRTSConferenceManager removeDelegate:self];
}

- (NSError *)reserveConference:(NSString *)name
{
    NIMRTSConference *conference = [[NIMRTSConference alloc] init];
    conference.name = name;
    conference.ext = @"test extend rts conference messge";
    return [NTESRTSConferenceManager reserveConference:conference];
}

- (NSError *)joinConference:(NSString *)name
{
    [self leaveCurrentConference];
    
    NIMRTSConference *conference = [[NIMRTSConference alloc] init];
    conference.name = name;
    conference.serverRecording = [[NTESBundleSetting sharedConfig] serverRecordWhiteboardData];
    __weak typeof (self) wself = self;
    conference.dataHandler = ^(NIMRTSConferenceData *data) {
        [wself handleReceivedData:data];
    };
    NSError *result = [NTESRTSConferenceManager joinConference:conference];
    
    return result;
}

- (void)leaveCurrentConference
{
    if (_currentConference) {
        NSError *result = [NTESRTSConferenceManager leaveConference:_currentConference];
        DDLogInfo(@"leave current conference %@ result %@", _currentConference.name, result);
        _currentConference = nil;
    }
}

- (BOOL)sendRTSData:(NSData *)data toUser:(NSString *)uid
{
    BOOL accepted;
    
    if (_currentConference) {
        NIMRTSConferenceData *conferenceData = [[NIMRTSConferenceData alloc] init];
        conferenceData.conference = _currentConference;
        conferenceData.data = data;
        conferenceData.uid = uid;
        accepted = [NTESRTSConferenceManager sendRTSData:conferenceData];
    }
    
    return accepted;
}

- (BOOL)isJoined
{
    return _currentConference != nil;
}


- (void)handleReceivedData:(NIMRTSConferenceData *)data
{
    if (_dataHandler) {
        [_dataHandler handleReceivedData:data.data sender:data.uid];
    }
}


#pragma mark - NIMRTSConferenceManagerDelegate

- (void)onReserveConference:(NIMRTSConference *)conference
                     result:(NSError *)result
{
    DDLogInfo(@"Reserve conference %@ result:%@", conference.name, result);
    
    //本demo使用聊天室id作为了多人实时会话的名称，保证了其唯一性，如果分配时发现已经存在了，认为是该聊天室的主播之前分配的，可以直接使用
    if (result.code == NIMRemoteErrorCodeExist) {
        result = nil;
    }
    
    if (_delegate) {
        [_delegate onReserve:conference.name result:result];
    }
    
}

- (void)onJoinConference:(NIMRTSConference *)conference
                  result:(NSError *)result
{
    DDLogInfo(@"Join conference %@ result:%@", conference.name, result);
    
    if (nil == result || nil == _currentConference) {
        _currentConference = conference;
    }
    
    if (_delegate) {
        [_delegate onJoin:conference.name result:result];
    }

}

- (void)onLeftConference:(NIMRTSConference *)conference
                   error:(NSError *)error
{
    DDLogInfo(@"Left conference %@ error:%@", conference.name, error);
    if ([_currentConference.name isEqualToString:conference.name]) {
        _currentConference = nil;
        
        if (_delegate) {
            [_delegate onLeft:conference.name error:error];
        }
    }
}

- (void)onUserJoined:(NSString *)uid
          conference:(NIMRTSConference *)conference
{
    DDLogInfo(@"User %@ joined conference %@", uid, conference.name);
    if ([_currentConference.name isEqualToString:conference.name]) {
        
        if (_delegate) {
            [_delegate onUserJoined:uid conference:conference.name];
        }
    }

}

- (void)onUserLeft:(NSString *)uid
        conference:(NIMRTSConference *)conference
            reason:(NIMRTSConferenceUserLeaveReason)reason
{
    DDLogInfo(@"User %@ left conference %@ for %zd", uid, conference.name, reason);
    
    if ([_currentConference.name isEqualToString:conference.name]) {
        if (_delegate) {
            [_delegate onUserLeft:uid conference:conference.name];
        }
    }
}

@end
