//
//  NTESMeetingRTSManager.h
//  NIMEducationDemo
//
//  Created by fenric on 16/10/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESService.h"


@protocol NTESMeetingRTSManagerDelegate <NSObject>

- (void)onReserve:(NSString *)name result:(NSError *)result;

- (void)onJoin:(NSString *)name result:(NSError *)result;

- (void)onLeft:(NSString *)name error:(NSError *)error;

- (void)onUserJoined:(NSString *)uid conference:(NSString *)name;

- (void)onUserLeft:(NSString *)uid conference:(NSString *)name;

@end

@protocol NTESMeetingRTSDataHandler <NSObject>

- (void)handleReceivedData:(NSData *)data sender:(NSString *)sender;

@end

@interface NTESMeetingRTSManager : NTESService

@property (nonatomic, weak) id<NTESMeetingRTSManagerDelegate> delegate;

@property (nonatomic, weak) id <NTESMeetingRTSDataHandler> dataHandler;

- (NSError *)reserveConference:(NSString *)name;

- (NSError *)joinConference:(NSString *)name;

- (void)leaveCurrentConference;

- (BOOL)sendRTSData:(NSData *)data toUser:(NSString *)uid;

- (BOOL)isJoined;

@end
