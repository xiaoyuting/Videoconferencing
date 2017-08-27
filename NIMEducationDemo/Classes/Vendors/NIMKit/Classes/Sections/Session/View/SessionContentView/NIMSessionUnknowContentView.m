//
//  NIMSessionUnknowContentView.h
//  NIMKit
//
//  Created by chris on 15/3/9.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NIMSessionUnknowContentView.h"
#import "NIMAttributedLabel+NIMKit.h"
#import "UIView+NIM.h"
#import "NIMMessageModel.h"
#import "NIMGlobalMacro.h"

@interface NIMSessionUnknowContentView()

@property (nonatomic,strong) UILabel *label;

@end

@implementation NIMSessionUnknowContentView

-(instancetype)initSessionMessageContentView
{
    if (self = [super initSessionMessageContentView]) {
        _label = [[UILabel alloc] initWithFrame:CGRectZero];
        _label.font = [UIFont systemFontOfSize:14.f];
        _label.backgroundColor = [UIColor clearColor];
        _label.userInteractionEnabled = NO;
        [self addSubview:_label];
    }
    return self;
}

- (void)refresh:(NIMMessageModel *)data{
    [super refresh:data];
    NSString *text = NIMKit_Unknow_Message_Tip;
    [self.label setText:text];
    [self.label sizeToFit];
    if (!self.model.message.isOutgoingMsg) {
        self.label.textColor = [UIColor blackColor];
    }else{
        self.label.textColor = [UIColor whiteColor];
    }
}


- (void)layoutSubviews{
    [super layoutSubviews];
    _label.nim_centerX = self.nim_width  * .5f;
    _label.nim_centerY = self.nim_height * .5f;
}

@end
