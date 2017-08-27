//
//  NTESBundleSetting.h
//  NIM
//
//  Created by chris on 15/7/1.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NIMSDK/NIMSDK.h>

#import <NIMAVChat/NIMAVChat.h>


//部分API提供了额外的选项，如删除消息会有是否删除会话的选项,为了测试方便提供配置参数
//上层开发只需要按照策划需求选择一种适合自己项目的选项即可，这个设置只是为了方便测试不同的case下API的正确性

@interface NTESBundleSetting : NSObject

+ (instancetype)sharedConfig;

- (BOOL)serverRecordAudio;                          //服务器录制语音

- (BOOL)serverRecordVideo;                          //服务器录制视频

- (NIMNetCallVideoCrop)videochatVideoCrop;          //视频画面裁剪比例

- (UIViewContentMode)videochatRemoteVideoContentMode; //对端画面的填充模式

- (BOOL)videochatAutoRotateRemoteVideo;             //自动旋转视频聊天远端画面

- (NIMNetCallVideoQuality)preferredVideoQuality;    //期望的视频发送清晰度

- (BOOL)startWithBackCamera;                        //使用后置摄像头开始视频通话

- (NIMNetCallVideoCodec)perferredVideoEncoder;      //期望的视频编码器

- (NIMNetCallVideoCodec)perferredVideoDecoder;      //期望的视频解码器

- (NSUInteger)videoMaxEncodeKbps;                   //最大发送视频编码码率

- (NSUInteger)localRecordVideoKbps;                 //本地录制视频码率

- (BOOL)autoDeactivateAudioSession;                 //自动结束AudioSession

- (BOOL)audioDenoise;                               //降噪开关

- (BOOL)voiceDetect;                                //语音检测开关

- (BOOL)preferHDAudio;                              //期望高清语音

- (NIMAVChatScene)scene;                            //音视频场景设置

- (BOOL)serverRecordWhiteboardData;                 //服务器录制白板数据

- (BOOL)testerToolUI;                               //打开测试者菜单

- (BOOL)provideLocalProcess;                        //视频前处理

- (NSInteger)beautifyType;                          //美颜类型

@end
