//
//  NTESMeetingRole.h
//  NIMEducationDemo
//
//  Created by fenric on 16/4/17.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NTESMeetingRole : NSObject

@property(nonatomic, copy)   NSString  *uid;

@property(nonatomic, assign) BOOL isManager;  //会议管理者

@property(nonatomic, assign) BOOL isJoined;   //已经加入音视频会议

@property(nonatomic, assign) BOOL isRaisingHand;  //已举手

@property(nonatomic, assign) BOOL isActor;    //有发言权限

@property(nonatomic, assign) BOOL audioOn;    //开启声音

@property(nonatomic, assign) BOOL videoOn;    //开启画面

@property(nonatomic, assign) BOOL whiteboardOn; //开启白板绘制

@property(nonatomic, assign) UInt16 audioVolume; //声音音量


@end
