//
//  NTESChatroomMemberCell.m
//  NIM
//
//  Created by chris on 15/12/18.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomMemberCell.h"
#import "NIMAvatarImageView.h"
#import "UIView+NTES.h"
#import "UIView+Toast.h"
#import "NTESDataManager.h"
#import "NTESMeetingRolesManager.h"
#import "UIAlertView+NTESBlock.h"

@interface NTESChatroomMemberCell()

@property (nonatomic, strong) NIMAvatarImageView *avatarImageView;

@property (nonatomic, strong) UIImageView *roleImageView;

@property (nonatomic, strong) UIButton *selfAudioButton;

@property (nonatomic, strong) UIButton *selfVideoButton;

@property (nonatomic, strong) UIButton *selfWhiteboardButton;

@property (nonatomic, strong) UIButton *meetingRoleButton;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, strong) UIImageView *volumeImageView;

@property (nonatomic, strong) UILabel *meetingRoleLabel;


@end

@implementation NTESChatroomMemberCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addSubview:self.avatarImageView];
        [self addSubview:self.volumeImageView];
        [self addSubview:self.roleImageView];
        [self addSubview:self.meetingRoleButton];
        [self addSubview:self.meetingRoleLabel];
    }
    return self;
}

- (void)refresh:(NIMChatroomMember *)member{
    self.userId =member.userId;
    [self.avatarImageView nim_setImageWithURL:[NSURL URLWithString:member.roomAvatar] placeholderImage:[NTESDataManager sharedInstance].defaultUserAvatar];
    self.textLabel.text = member.roomNickname;
    [self.textLabel sizeToFit];
    [self refreshRole:member];
}

- (void)refreshRole:(NIMChatroomMember *)member
{
    NTESMeetingRole *meetingRole = [[NTESMeetingRolesManager sharedInstance] memberRole:member];
    
    self.textLabel.textColor = meetingRole.isJoined ? [UIColor blackColor] : [UIColor grayColor];
    switch (member.type) {
        case NIMChatroomMemberTypeCreator:
            self.roleImageView.hidden = NO;
            self.roleImageView.image = [UIImage imageNamed:@"meeting_manager"];

            break;
            
        default:
            self.roleImageView.hidden = YES;
            break;
    }
    
    
    BOOL selfIsManager = [NTESMeetingRolesManager sharedInstance].myRole.isManager;
    
    //表示自己
    if ([member.userId isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]&&selfIsManager) {
        [self.meetingRoleButton setHidden:YES];
        [self.meetingRoleLabel setHidden:NO];
    }
    else {
        //老师
        if (selfIsManager) {
            NTESMeetingRole *role = [[NTESMeetingRolesManager sharedInstance] role:member.userId];
            [self.meetingRoleLabel setHidden:YES];
            
            if (role.isActor) {
                self.meetingRoleButton.hidden = NO;
                self.meetingRoleButton.backgroundColor = UIColorFromRGB(0x1e77f9);
                [self.meetingRoleButton setTitle:@"结束互动" forState:UIControlStateNormal];
            }
            else if (role.isRaisingHand) {
                self.meetingRoleButton.hidden = NO;
                self.meetingRoleButton.backgroundColor = UIColorFromRGB(0x7dd21f);
                [self.meetingRoleButton setTitle:@"允许互动" forState:UIControlStateNormal];

            }
            else {
                self.meetingRoleButton.hidden = YES;
            }
        }
        //学生
        else {
            NTESMeetingRole *role = [[NTESMeetingRolesManager sharedInstance] role:member.userId];
            self.meetingRoleButton.hidden = YES;
            if (role.isActor) {
                
                self.meetingRoleLabel.hidden = NO;
                [self.meetingRoleLabel setText:@"互动中"];
            }
            else {
                self.meetingRoleLabel.hidden = YES;

            }
        }
        
    }
    
    
    NSString *volumeImageName = [NSString stringWithFormat:@"volume%@", @(meetingRole.audioVolume)];
    
    [self.volumeImageView setImage:[UIImage imageNamed:volumeImageName]];
    
    
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGFloat spacing = 10.f;
    self.roleImageView.left      = spacing;
    self.roleImageView.centerY   = self.height * .5f;
    self.roleImageView.width     = 20;
    self.roleImageView.height    = 20;

    self.avatarImageView.left    = self.roleImageView.right + spacing;
    self.avatarImageView.centerY = self.height * .5f;
    self.volumeImageView.center = self.avatarImageView.center;
    self.textLabel.left          = self.avatarImageView.right + spacing;
    self.textLabel.centerY       = self.height * .5f;
    
    spacing = 15.f;
    
    self.meetingRoleButton.right   = self.right - spacing;
    self.meetingRoleButton.centerY   = self.height * .5f;
    
    self.meetingRoleLabel.right   = self.right - spacing;
    self.meetingRoleLabel.centerY   = self.height * .5f;
}


#pragma mark - Get
- (NIMAvatarImageView *)avatarImageView{
    if (!_avatarImageView) {
        _avatarImageView = [[NIMAvatarImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
    }
    return _avatarImageView;
}

- (UIImageView *)volumeImageView
{
    if (!_volumeImageView) {
        _volumeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        [_volumeImageView setImage:[UIImage imageNamed:@"volume5"]];
    }
    return _volumeImageView;
}

- (UIImageView *)roleImageView
{
    if (!_roleImageView) {
        _roleImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    }
    return _roleImageView;
}

- (UIButton *)selfAudioButton
{
    if (!_selfAudioButton) {
        _selfAudioButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_selfAudioButton addTarget:self action:@selector(onSelfAudioPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selfAudioButton;
}

- (UIButton *)selfVideoButton
{
    if (!_selfVideoButton) {
        _selfVideoButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_selfVideoButton addTarget:self action:@selector(onSelfVideoPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selfVideoButton;
}

- (UIButton *)selfWhiteboardButton
{
    if (!_selfWhiteboardButton) {
        _selfWhiteboardButton = [[UIButton alloc] initWithFrame:CGRectZero];
        [_selfWhiteboardButton addTarget:self action:@selector(onSelfWhiteboardPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _selfWhiteboardButton;
}


- (UIButton *)meetingRoleButton
{
    if (!_meetingRoleButton) {
        _meetingRoleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 75.f, 30.f)];
        _meetingRoleButton.titleLabel.font = [UIFont systemFontOfSize:13];
        _meetingRoleButton.titleLabel.textColor = UIColorFromRGB(0xffffff);
        [_meetingRoleButton addTarget:self action:@selector(onMeetingRolePressed:) forControlEvents:UIControlEventTouchUpInside];
        _meetingRoleButton.layer.cornerRadius = 5.f;
    }
    return _meetingRoleButton;
}

-(UILabel *)meetingRoleLabel
{
    if (!_meetingRoleLabel) {
        _meetingRoleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 75.f, 30.f)];
        _meetingRoleLabel.font = [UIFont systemFontOfSize:13];
        _meetingRoleLabel.textAlignment = NSTextAlignmentCenter;
        _meetingRoleLabel.textColor = UIColorFromRGB(0x333333);
    }
    return _meetingRoleLabel;

}
- (void)onSelfVideoPressed:(id)sender
{
    BOOL videoIsOn = [NTESMeetingRolesManager sharedInstance].myRole.videoOn;
    
    [[NTESMeetingRolesManager sharedInstance] setMyVideo:!videoIsOn];
}

- (void)onSelfAudioPressed:(id)sender
{
    BOOL audioIsOn = [NTESMeetingRolesManager sharedInstance].myRole.audioOn;

    [[NTESMeetingRolesManager sharedInstance] setMyAudio:!audioIsOn];
}

- (void)onSelfWhiteboardPressed:(id)sender
{
    BOOL whiteboardIsOn = [NTESMeetingRolesManager sharedInstance].myRole.whiteboardOn;
    
    [[NTESMeetingRolesManager sharedInstance] setMyWhiteBoard:!whiteboardIsOn];

}

- (void)onMeetingRolePressed:(id)sender
{
    NTESMeetingRole *role = [[NTESMeetingRolesManager sharedInstance] role:_userId];
    if (role.isActor) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"确定撤销该用户的互动权限？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert showAlertWithCompletionHandler:^(NSInteger index) {
            switch (index) {
                case 1:{
                    [[NTESMeetingRolesManager sharedInstance] changeMemberActorRole:_userId];
                    break;
                }
                default:
                    break;
            }
        }];
    }
    else {
        [[NTESMeetingRolesManager sharedInstance] changeMemberActorRole:_userId];
    }
}


@end
