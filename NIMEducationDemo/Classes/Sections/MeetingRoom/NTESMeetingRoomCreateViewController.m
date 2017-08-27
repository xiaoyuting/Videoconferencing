//
//  NTESMeetingRoomCreateViewController.m
//  NIMEducationDemo
//
//  Created by chris on 16/3/9.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMeetingRoomCreateViewController.h"
#import "NTESCommonTableDelegate.h"
#import "NTESCommonTableData.h"
#import "SVProgressHUD.h"
#import "UIView+Toast.h"
#import "NTESMeetingViewController.h"
#import "NTESMeetingManager.h"
#import "NTESDemoService.h"
#import "NTESTextSettingCell.h"
#import "NTESMeetingRolesManager.h"
#import <NIMAVChat/NIMAVChat.h>

#define NTESMeetingRoomNameMaxLength  20

@interface NTESMeetingRoomCreateViewController ()

@property (nonatomic,strong) NTESCommonTableDelegate *delegator;

@property (nonatomic,copy  ) NSArray                 *data;

@property (nonatomic,copy  ) NSString                *roomName;

@end

@implementation NTESMeetingRoomCreateViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpNav];
    __weak typeof(self) wself = self;
    [self buildData];
    self.delegator = [[NTESCommonTableDelegate alloc] initWithTableData:^NSArray *{
        return wself.data;
    }];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = UIColorFromRGB(0xe3e6ea);
    self.tableView.separatorStyle  = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate   = self.delegator;
    self.tableView.dataSource = self.delegator;
    [self.tableView reloadData];
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        for (UIView *subView in cell.subviews) {
            if ([subView isKindOfClass:[UITextField class]]) {
                [subView becomeFirstResponder];
                break;
            }
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTextFieldChanged:) name:UITextFieldTextDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [SVProgressHUD dismiss];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.titleTextAttributes =@{
                                                                   NSForegroundColorAttributeName:[UIColor blackColor]};
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setUpNav{
    self.navigationItem.title = @"创建房间";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"完成" style:UIBarButtonItemStyleDone target:self action:@selector(onDone:)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor blackColor];
}

- (void)onDone:(id)sender{
    [self.view endEditing:YES];
    
    if ([self validate]) {
        [self requestChatRoom];
    }
}

- (BOOL)validate
{
    if (!self.roomName.length) {
        [self.view makeToast:@"房间名称不能为空" duration:2.0 position:CSToastPositionCenter];
        return NO;
    }
    if (self.roomName.length > NTESMeetingRoomNameMaxLength) {
        [self.view makeToast:@"房间名称过长" duration:2.0 position:CSToastPositionCenter];
        return NO;
    }
    return YES;
}

- (void)buildData{
    NSArray *data = @[
                      @{
                          HeaderTitle:@"房间名称",
                          RowContent :@[
                                  @{
                                      Title         : @"输入房间名称",
                                      ExtraInfo     : self.roomName.length? self.roomName : @"",
                                      CellClass     : @"NTESTextSettingCell",
                                      RowHeight     : @(50),
                                      },
                                  ],
                          FooterTitle:@""
                          },
                      ];
    self.data = [NTESCommonTableSection sectionsWithData:data];
}


- (void)requestChatRoom
{
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    
    [[NTESDemoService sharedService] requestChatRoom:self.roomName
                                          completion:^(NSError *error, NSString *meetingRoomID)
    {
        [SVProgressHUD dismiss];
        if (!error){
            [self reserveNetCallMeeting:meetingRoomID];
        }
        else
        {
            [wself.view makeToast:@"创建聊天室失败，请重试" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}


- (void)reserveNetCallMeeting:(NSString *)roomId
{
    NIMNetCallMeeting *meeting = [[NIMNetCallMeeting alloc] init];
    meeting.name = roomId;
    meeting.type = NIMNetCallTypeVideo;
    meeting.ext = @"test extend meeting messge";
    
    [SVProgressHUD show];
    
    [[NIMAVChatSDK sharedSDK].netCallManager reserveMeeting:meeting completion:^(NIMNetCallMeeting *meeting, NSError *error) {
        [SVProgressHUD dismiss];
        if (!error) {
            [self enterChatRoom:roomId];
        }
        else {
            [self.view makeToast:@"分配视频会议失败，请重试" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)enterChatRoom:(NSString *)roomId
{
    NIMChatroomEnterRequest *request = [[NIMChatroomEnterRequest alloc] init];
    request.roomId = roomId;
    [SVProgressHUD show];
    
    __weak typeof(self) wself = self;

    [[NIMSDK sharedSDK].chatroomManager enterChatroom:request completion:^(NSError *error, NIMChatroom *room, NIMChatroomMember *me) {
        [SVProgressHUD dismiss];
        if (!error) {
            [[NTESMeetingManager sharedInstance] cacheMyInfo:me roomId:request.roomId];
            [[NTESMeetingRolesManager sharedInstance] startNewMeeting:me withChatroom:room newCreated:YES];
            NTESMeetingViewController *vc = [[NTESMeetingViewController alloc] initWithChatroom:room];
            [wself.navigationController pushViewController:vc animated:YES];
        }
        else
        {
            [wself.view makeToast:@"进入会议失败，请重试" duration:2.0 position:CSToastPositionCenter];
        }
    }];
    
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([string isEqualToString:@"\n"]) {
        [self onDone:nil];
    }
    // 如果是删除键
    if ([string length] == 0 && range.length > 0)
    {
        return YES;
    }
    NSString *genString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (genString.length > NTESMeetingRoomNameMaxLength) {
        return NO;
    }
    return YES;
}


- (void)onTextFieldChanged:(NSNotification *)notification{
    UITextField *textField = notification.object;
    self.roomName = textField.text;
}


#pragma mark - 旋转处理 (iOS7)
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self.tableView reloadData];
}

@end
