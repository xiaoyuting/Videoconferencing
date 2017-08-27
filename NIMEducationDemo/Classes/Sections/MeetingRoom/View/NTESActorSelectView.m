//
//  NTESActorSelectView.m
//  NIMEducationDemo
//
//  Created by fenric on 16/4/28.
//  Copyright © 2016年 Netease. All rights reserved.
//
#import "NTESActorSelectView.h"
#import "UIView+NTES.h"
#import "NTESMeetingRolesManager.h"

#define NTESActorSelectLabelTextSize 12
#define NTESActorSelectLabelTextColor 0x333333

@interface NTESActorSelectView ()

@property (nonatomic, strong) UIView *backView;

@property (nonatomic ,strong) UILabel *hintLabel;

@property (nonatomic ,strong) UIButton *audioButton;

@property (nonatomic ,strong) UIButton *videoButton;

@property (nonatomic ,strong) UIButton *whiteboardButton;

@property (nonatomic ,strong) UIView *line;

@property (nonatomic, strong) UIButton *okButton;



@end


@implementation NTESActorSelectView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4f]];
        
        self.backView = [[UIView alloc] init];
        [self.backView setBackgroundColor:[UIColor whiteColor]];
        self.backView.layer.cornerRadius = 5.f;
        [self addSubview:self.backView];
        
        self.hintLabel = [[UILabel alloc] init];
        
        NTESMeetingRole *myRole = [[NTESMeetingRolesManager sharedInstance] myRole];
        
        BOOL isRaisingHand = myRole.isRaisingHand;
        
        NSString *text;
        if (isRaisingHand) {
            text = @"老师已通过你的互动申请，\n请选择互动方式";
        }
        else {
            text = @"老师开通了你的互动权限，\n请选择互动方式：";
        }
        self.hintLabel.text = text;
        self.hintLabel.font = [UIFont systemFontOfSize:NTESActorSelectLabelTextSize];
        self.hintLabel.textAlignment = NSTextAlignmentCenter;
        self.hintLabel.numberOfLines = 2;
        [self.hintLabel sizeToFit];
        
        [self.backView addSubview:self.hintLabel];
        
        self.audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.audioButton setImage:[UIImage imageNamed:@"meeting_selected"] forState:UIControlStateNormal];
        [self.audioButton setImage:[UIImage imageNamed:@"meeting_not_selected"] forState:UIControlStateSelected];

        [self.audioButton setTitle:@"语音互动" forState:UIControlStateNormal];
        [self.audioButton setTitleColor:UIColorFromRGB(NTESActorSelectLabelTextColor) forState:UIControlStateNormal];
        self.audioButton.titleLabel.font = [UIFont systemFontOfSize:NTESActorSelectLabelTextSize];
        
        CGFloat spacing = 5;
        self.audioButton.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
        [self.audioButton sizeToFit];
        
        [self.audioButton addTarget:self action:@selector(audioPressed) forControlEvents:UIControlEventTouchUpInside];
        
        [self.backView addSubview:self.audioButton];
        
        self.videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.videoButton setImage:[UIImage imageNamed:@"meeting_selected"] forState:UIControlStateNormal];
        [self.videoButton setImage:[UIImage imageNamed:@"meeting_not_selected"] forState:UIControlStateSelected];
        
        [self.videoButton setTitle:@"视频互动" forState:UIControlStateNormal];
        [self.videoButton setTitleColor:UIColorFromRGB(NTESActorSelectLabelTextColor) forState:UIControlStateNormal];
        self.videoButton.titleLabel.font = [UIFont systemFontOfSize:NTESActorSelectLabelTextSize];
        
        self.videoButton.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
        [self.videoButton sizeToFit];
        
        [self.videoButton addTarget:self action:@selector(videoPressed) forControlEvents:UIControlEventTouchUpInside];

        [self.backView addSubview:self.videoButton];
        
        
        self.whiteboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.whiteboardButton.enabled = NO;
        [self.whiteboardButton setImage:[UIImage imageNamed:@"meeting_selected"] forState:UIControlStateNormal];
//        [self.whiteboardButton setImage:[UIImage imageNamed:@"meeting_selected"] forState:UIControlStateSelected];
        
        [self.whiteboardButton setTitle:@"白板互动(常开)" forState:UIControlStateNormal];
        [self.whiteboardButton setTitleColor:UIColorFromRGB(NTESActorSelectLabelTextColor) forState:UIControlStateNormal];
        self.whiteboardButton.titleLabel.font = [UIFont systemFontOfSize:NTESActorSelectLabelTextSize];
        
        self.whiteboardButton.titleEdgeInsets = UIEdgeInsetsMake(0, spacing, 0, 0);
        [self.whiteboardButton sizeToFit];
        
        [self.whiteboardButton addTarget:self action:@selector(whiteboardPressed) forControlEvents:UIControlEventTouchUpInside];
        
        [self.backView addSubview:self.whiteboardButton];
        
        self.line = [[UIView alloc] init];
        self.line.backgroundColor = [UIColor grayColor];
        
        [self.backView addSubview:self.self.line];

        
        self.okButton = [[UIButton alloc] init];
        [self.okButton setTitle:@"确定" forState:UIControlStateNormal];
        [self.okButton setTitleColor:UIColorFromRGB(NTESActorSelectLabelTextColor) forState:UIControlStateNormal];
        [self.okButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        self.okButton.titleLabel.font = [UIFont systemFontOfSize:17];
        [self.okButton sizeToFit];
        [self.okButton addTarget:self action:@selector(okPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.backView addSubview:self.okButton];
        
    }
    return self;
}


- (void)layoutSubviews
{
    self.backView.width = 280;
    self.backView.height = 135.f;
    self.backView.centerX = self.width * .5f;
    self.backView.centerY = self.height * .5f;
    
    self.hintLabel.top = 20.f;
    self.hintLabel.centerX = self.backView.width * .5f;
    
    self.audioButton.top = self.hintLabel.bottom + 15.f;
    self.audioButton.left  = 5;
    self.audioButton.width =80;
    
    self.videoButton.top = self.audioButton.top;
    self.videoButton.left  = self.audioButton.right;
    self.videoButton.width = self.audioButton.width;

    self.whiteboardButton.top = self.audioButton.top;
    self.whiteboardButton.left  = self.videoButton.right;
    self.whiteboardButton.width = self.audioButton.width+30;

    self.line.top = self.videoButton.bottom + 22.f;
    self.line.height = .5f;
    self.line.width = self.backView.width;
    
    self.okButton.top = self.line.bottom;
    self.okButton.width = self.backView.width;
    self.okButton.height = self.backView.height - self.line.bottom;

}

- (void)audioPressed
{
    self.audioButton.selected = !self.audioButton.selected;
}

- (void)videoPressed
{
    self.videoButton.selected = !self.videoButton.selected;
}

- (void)whiteboardPressed
{
    self.whiteboardButton.selected = !self.whiteboardButton.selected;
}

- (void)okPressed
{
    if (_delegate) {
        [_delegate onSelectedAudio:!self.audioButton.selected video:!self.videoButton.selected whiteboard:YES];
    }
}


@end
