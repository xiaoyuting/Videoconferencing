//
//  NTESCustomAttachmentDefines.h
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#ifndef NIM_NTESCustomAttachmentTypes_h
#define NIM_NTESCustomAttachmentTypes_h

typedef NS_ENUM(NSInteger,NTESCustomMessageType){
    CustomMessageTypeJanKenPon      = 1, //剪子石头布
    CustomMessageTypeSnapchat       = 2, //阅后即焚
    CustomMessageTypeChartlet       = 3, //贴图表情
    CustomMessageTypeWhiteboard     = 4,  //白板会话
    CustomMessageTypeMeetingControl = 10, //多人会议控制
};


#define CMType          @"type"
#define CMData          @"data"
#define CMValue         @"value"
#define CMFlag          @"flag"
#define CMURL           @"url"
#define CMMD5           @"md5"
#define CMFIRE          @"fired"    //阅后即焚消息是否被焚毁
#define CMCatalog       @"catalog"  //贴图类别
#define CMChartlet      @"chartlet" //贴图表情ID

#define CMCommand       @"command"
#define CMRoomID        @"room_id"  //聊天室id
#define CMUIDs          @"uids"     //用户列表

#endif


@protocol NTESCustomAttachmentInfo <NSObject>

@optional

- (NSString *)cellContent:(NIMMessage *)message;

- (CGSize)contentSize:(NIMMessage *)message cellWidth:(CGFloat)width;

- (UIEdgeInsets)contentViewInsets:(NIMMessage *)message;

- (NSString *)formatedMessage;

- (UIImage *)showCoverImage;

- (void)setShowCoverImage:(UIImage *)image;

@end
