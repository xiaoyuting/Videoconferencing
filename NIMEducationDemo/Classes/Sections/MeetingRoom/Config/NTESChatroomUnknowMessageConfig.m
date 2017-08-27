//
//  NTESChatroomKnowMessageConfig.m
//  NIMEducationDemo
//
//  Created by chris on 16/3/10.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomUnknowMessageConfig.h"
#import "NIMAttributedLabel+NIMKit.h"
#import "NIMGlobalMacro.h"

@interface NTESChatroomUnknowMessageConfig ()

@property (nonatomic, strong) NIMAttributedLabel *label;

@end

@implementation NTESChatroomUnknowMessageConfig

- (CGSize)contentSize:(CGFloat)cellWidth
{
    NSString *text = NIMKit_Unknow_Message_Tip;
    [self.label nim_setText:text];
    CGFloat msgBubbleMaxWidth    = (cellWidth - 130);
    CGFloat bubbleLeftToContent  = 15;
    CGFloat contentRightToBubble = 0;
    CGFloat msgContentMaxWidth = (msgBubbleMaxWidth - contentRightToBubble - bubbleLeftToContent);
    return [self.label sizeThatFits:CGSizeMake(msgContentMaxWidth, CGFLOAT_MAX)];
}

- (NSString *)cellContent
{
    return @"NTESChatroomUnknowContentView";
}

- (UIEdgeInsets)contentViewInsets
{
    return UIEdgeInsetsMake(20,15,10,0);
}

- (NIMAttributedLabel *)label
{
    if (!_label) {
        _label = [[NIMAttributedLabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont systemFontOfSize:Chatroom_Message_Font_Size];
    }
    return _label;
}

@end
