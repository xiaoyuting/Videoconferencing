//
//  NTESMeetingViewController.m
//  NIM
//
//  Created by fenric on 16/4/7.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESMeetingViewController.h"
#import "NTESChatroomSegmentedControl.h"
#import "UIView+NTES.h"
#import "NTESPageView.h"
#import "NTESChatroomViewController.h"
#import "NTESChatroomMemberListViewController.h"
#import "UIImageView+WebCache.h"
#import "UIViewController+NTES.h"
#import "SVProgressHUD.h"
#import "UIImage+NTESColor.h"
#import "NTESMeetingActionView.h"
#import "UIView+Toast.h"
#import "NTESMeetingManager.h"
#import "NTESMeetingActorsView.h"
#import "NSDictionary+NTESJson.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESMeetingRolesManager.h"
#import "NTESDemoService.h"
#import "NTESMeetingNetCallManager.h"
#import "NTESActorSelectView.h"
#import "NIMGlobalMacro.h"
#import "NTESMeetingRolesManager.h"
#import "NTESMeetingWhiteboardViewController.h"
#import <NIMAVChat/NIMAVChat.h>

@interface NTESMeetingViewController ()<NTESMeetingActionViewDataSource,NTESMeetingActionViewDelegate,NIMInputDelegate,NIMChatroomManagerDelegate,NTESMeetingNetCallManagerDelegate,NTESActorSelectViewDelegate,NTESMeetingRolesManagerDelegate,NIMLoginManagerDelegate
>

@property (nonatomic, copy)   NIMChatroom *chatroom;

@property (nonatomic, strong) NTESChatroomViewController *chatroomViewController;

@property (nonatomic, strong) NTESMeetingActionView *actionView;

@property (nonatomic, strong) NTESMeetingActorsView *actorsView;

@property (nonatomic, assign) BOOL keyboradIsShown;

@property (nonatomic, weak)   UIViewController *currentChildViewController;

@property (nonatomic, strong) UIAlertView *actorEnabledAlert;

@property (nonatomic, strong) NTESActorSelectView *actorSelectView;

@property (nonatomic, strong) NTESChatroomMemberListViewController *memberListVC;

@property (nonatomic, strong) NTESMeetingWhiteboardViewController *whiteboardVC;

@property (nonatomic, assign) BOOL isPoped;

@property (nonatomic, assign) BOOL isRemainStdNav;

@property (nonatomic, assign) BOOL readyForFullScreen;



@end

@implementation NTESMeetingViewController

NTES_USE_CLEAR_BAR
NTES_FORBID_INTERACTIVE_POP

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _chatroom = chatroom;
        
    }
    return self;
}

- (void)dealloc{
    [[NIMSDK sharedSDK].chatroomManager exitChatroom:_chatroom.roomId completion:nil];
    [[NIMSDK sharedSDK].chatroomManager removeDelegate:self];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    [[NTESMeetingNetCallManager sharedInstance] leaveMeeting];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupChildViewController];
    [self.view addSubview:self.actorsView];
    [self.view addSubview:self.actionView];
    [self.actionView reloadData];
    self.currentChildViewController = self.whiteboardVC;
    [self revertInputView];
    [self setupBarButtonItem];
    [[NIMSDK sharedSDK].chatroomManager addDelegate:self];
    [[NIMSDK sharedSDK].loginManager addDelegate:self];
    [[NTESMeetingRolesManager sharedInstance] setDelegate:self];
    [[NTESMeetingNetCallManager sharedInstance] joinMeeting:_chatroom.roomId delegate:self];
    

}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent
                                                animated:NO];
    self.chatroomViewController.delegate = self;
    [self.currentChildViewController beginAppearanceTransition:YES animated:animated];
    
    self.actorsView.isFullScreen = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault
                                                animated:NO];
    self.chatroomViewController.delegate = nil; //避免view不再顶层仍受到键盘回调，导致改变状态栏样式。
    [self.currentChildViewController beginAppearanceTransition:NO animated:animated];
    [self revertInputView];
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.alpha = 1;
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.currentChildViewController endAppearanceTransition];
}


- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
    return NO;
}


- (void)setupChildViewController
{
    NSArray *vcs = [self makeChildViewControllers];
    for (UIViewController *vc in vcs) {
        [self addChildViewController:vc];
    }
}

#pragma mark - NTESMeetingActionViewDataSource

- (NSInteger)numberOfPages
{
    return self.childViewControllers.count;
}

- (UIView *)viewInPage:(NSInteger)index
{
    UIView *view = self.childViewControllers[index].view;
    return view;
}

- (CGFloat)actorsViewHeight
{
    return self.actorsView.height;
}

#pragma mark - NTESMeetingActionViewDelegate

- (void)onSegmentControlChanged:(NTESChatroomSegmentedControl *)control
{
    UIViewController *lastChild = self.currentChildViewController;
    UIViewController *child = self.childViewControllers[self.actionView.segmentedControl.selectedSegmentIndex];
    
    if ([child isKindOfClass:[NTESChatroomMemberListViewController class]]) {
        self.actionView.unreadRedTip.hidden = YES;
    }
    
    [lastChild beginAppearanceTransition:NO animated:YES];
    [child beginAppearanceTransition:YES animated:YES];
    [self.actionView.pageView scrollToPage:self.actionView.segmentedControl.selectedSegmentIndex];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentChildViewController = child;
        [lastChild endAppearanceTransition];
        [child endAppearanceTransition];
        [self revertInputView];
    });
}

- (void)onTouchActionBackground:(UITapGestureRecognizer *)gesture
{
    CGPoint point  = [gesture locationInView:self.actorsView];
    UIView *view = [self.actorsView hitTest:point withEvent:nil];
    if (view) {
        self.navigationController.navigationBarHidden = !self.navigationController.navigationBarHidden;
    }
    if ([view isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *)view;
        [control sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    [self.chatroomViewController.sessionInputView endEditing:YES];
}

#pragma mark - Get

- (CGFloat)meetingActorsViewHeight
{
    return NIMKit_UIScreenWidth * 220.f / 320.f;
}

- (NTESMeetingActorsView *)actorsView{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_actorsView) {
        _actorsView = [[NTESMeetingActorsView alloc] initWithFrame:CGRectMake(0, 0, self.view.width,self.meetingActorsViewHeight)];
        _actorsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _actorsView;
}

- (NTESMeetingActionView *)actionView
{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_actionView) {
        _actionView = [[NTESMeetingActionView alloc] initWithDataSource:self];
        _actionView.frame = self.view.bounds;
        _actionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _actionView.delegate = self;
        _actionView.unreadRedTip.hidden = YES;
    }
    return _actionView;
}


#pragma mark - NIMInputDelegate
- (void)showInputView
{
    self.keyboradIsShown = YES;
}

- (void)hideInputView
{
    self.keyboradIsShown = NO;
}

#pragma mark - NIMChatroomManagerDelegate
- (void)chatroom:(NSString *)roomId beKicked:(NIMChatroomKickReason)reason
{
    if ([roomId isEqualToString:self.chatroom.roomId]) {
        
        NSString *toast;
        
        if ([_chatroom.creator isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
            toast = @"教学已结束";
        }
        else {
            switch (reason) {
                case NIMChatroomKickReasonByManager:
                    toast = @"你已被老师请出房间";
                    break;
                case NIMChatroomKickReasonInvalidRoom:
                    toast = @"老师已经结束了教学";
                    break;
                case NIMChatroomKickReasonByConflictLogin:
                    toast = @"你已被自己踢出了房间";
                    break;
                default:
                    toast = @"你已被踢出了房间";
                    break;
            }
        }
        
        
        DDLogInfo(@"chatroom be kicked, roomId:%@  rease:%zd",roomId,reason);
        
        //判断 当前页面是document列表的情况
        if ([self.navigationController.visibleViewController isKindOfClass:[NTESDocumentViewController class]]) {
            [self.navigationController.visibleViewController.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
            NSUInteger index = [self.navigationController.viewControllers indexOfObject:self.navigationController.visibleViewController]-2;
            [self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:index] animated:YES];
        }
        else if(self.actorsView.isFullScreen)//正在全屏 先退出全屏
        {
            [self.presentedViewController.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
            self.actorsView.showFullScreenBtn = NO;
            [self pop];
        }
        else{
            [self.view.window makeToast:toast duration:2.0 position:CSToastPositionCenter];
            [self pop];
        }
    }
}

- (void)onLogin:(NIMLoginStep)step
{
    if (step == NIMLoginStepLoginOK) {
        if (![[NTESMeetingNetCallManager sharedInstance] isInMeeting]) {
            [self.view makeToast:@"登录成功，重新进入房间"];
            [[NTESMeetingNetCallManager sharedInstance] joinMeeting:_chatroom.roomId delegate:self];
        }
    }
}

- (void)chatroom:(NSString *)roomId connectionStateChanged:(NIMChatroomConnectionState)state;
{
    DDLogInfo(@"chatroom connectionStateChanged roomId : %@  state:%zd",roomId,state);
    if(state==NIMChatroomConnectionStateEnterOK)
    {
        [self requestChatRoomInfo];
    }
}

#pragma mark - NTESMeetingNetCallManagerDelegate
- (void)onJoinMeetingFailed:(NSString *)name error:(NSError *)error
{
    [self.view.window makeToast:@"无法加入视频，退出房间" duration:3.0 position:CSToastPositionCenter];

    if ([[[NTESMeetingRolesManager sharedInstance] myRole] isManager]) {
        [self requestCloseChatRoom];
    }
    
    __weak typeof(self) wself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [wself pop];
    });
}

- (void)onMeetingConntectStatus:(BOOL)connected
{
    DDLogInfo(@"Meeting %@ ...", connected ? @"connected" : @"disconnected");
    if (connected) {
    }
    else {
        [self.view.window makeToast:@"音视频服务连接异常" duration:2.0 position:CSToastPositionCenter];
        [self.actorsView stopLocalPreview];
    }
}

#pragma mark - NTESMeetingRolesManagerDelegate

- (void)meetingRolesUpdate
{
    [self.actorsView updateActors];
    [self.memberListVC refresh];
    [self.whiteboardVC checkPermission];
    [self setupBarButtonItem];
}

- (void)meetingVolumesUpdate
{
    [self.memberListVC refresh];
}

- (void)chatroomMembersUpdated:(NSArray *)members entered:(BOOL)entered
{
    [self.memberListVC updateMembers:members entered:entered];
}

- (void)meetingMemberRaiseHand
{
    if (self.actionView.segmentedControl.selectedSegmentIndex != 2) {
        self.actionView.unreadRedTip.hidden = NO;
    }
}

- (void)meetingActorBeenEnabled
{
    if (!self.actorSelectView) {
        _isRemainStdNav = YES;
        self.actorSelectView = [[NTESActorSelectView alloc] initWithFrame:self.view.bounds];
        self.actorSelectView.delegate = self;
        [self.actorSelectView setUserInteractionEnabled:YES];
        [self.view addSubview:self.actorSelectView];
    }
}

- (void)meetingActorBeenDisabled
{
    [self removeActorSelectView];
        
    [self.view.window makeToast:@"你已被老师取消互动" duration:2.0 position:CSToastPositionCenter];
}

- (void)meetingActorsNumberExceedMax
{
    [self.view makeToast:@"互动人数已满" duration:1 position:CSToastPositionCenter];
}

-(void)meetingRolesShowFullScreen:(NSString*)notifyExt
{
    if ([self showFullScreenBtn:notifyExt]) {
        self.actorsView.showFullScreenBtn = YES;
    }
    else
    {
        self.actorsView.showFullScreenBtn = NO;
    }
}
#pragma mark - NTESActorSelectViewDelegate
- (void)onSelectedAudio:(BOOL)audioOn video:(BOOL)videoOn whiteboard:(BOOL)whiteboardOn
{    
    [self removeActorSelectView];
    _isRemainStdNav = NO;

    if (audioOn) {
        [[NTESMeetingRolesManager sharedInstance] setMyAudio:YES];
    }
    
    if (videoOn) {
        [[NTESMeetingRolesManager sharedInstance] setMyVideo:YES];
    }
    
    if (whiteboardOn) {
        [[NTESMeetingRolesManager sharedInstance] setMyWhiteBoard:YES];
    }    
}

#pragma mark - Private
- (NSArray *)makeChildViewControllers{
    self.chatroomViewController = [[NTESChatroomViewController alloc] initWithChatroom:self.chatroom];
    self.chatroomViewController.delegate = self;
    self.memberListVC = [[NTESChatroomMemberListViewController alloc] initWithChatroom:self.chatroom];
    self.whiteboardVC = [[NTESMeetingWhiteboardViewController alloc] initWithChatroom:self.chatroom];
    
        return @[self.whiteboardVC,self.chatroomViewController,self.memberListVC];
}

-(BOOL)showFullScreenBtn:(NSString * )jsonString
{
    if(jsonString)
    {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *err;
        
        NSDictionary *dic = [NSJSONSerialization  JSONObjectWithData:jsonData
                             
                                                            options:NSJSONReadingAllowFragments
                             
                                                              error:&err];
        
        if ([dic objectForKey:@"fullScreenType"])
        {
            if([[dic objectForKey:@"fullScreenType"]integerValue] == 1)
            {
                return YES;
            }
        }
        return NO;
    }
    
    return NO;
}
- (void)revertInputView
{
    UIView *inputView  = self.chatroomViewController.sessionInputView;
    UIView *revertView;
    if ([self.currentChildViewController isKindOfClass:[NTESChatroomViewController class]]) {
        revertView = self.view;
    }else{
        revertView = self.chatroomViewController.view;
    }
    CGFloat height = revertView.height;
    [revertView addSubview:inputView];
    inputView.bottom = height;
}

- (void)setupBarButtonItem
{
    //根据用户角色判断导航栏rightBarButtonItem显示 老师右边三个btn
    if ([[[NTESMeetingRolesManager sharedInstance] myRole] isManager]) {
        [self refreshTecNavBar];
    }
    //学生端 互动前2个btn 互动后4个btn
    else
    {
        [self refreshStdNavBar];
    }
    
    //显示左边leftBarButtonItem
    UIView * leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 200, 30)];
    //左边返回button
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton setImage:[UIImage imageNamed:@"chatroom_back_normal"] forState:UIControlStateNormal];
    [leftButton setImage:[UIImage imageNamed:@"chatroom_back_selected"] forState:UIControlStateHighlighted];
    [leftButton addTarget:self action:@selector(onBack:) forControlEvents:UIControlEventTouchUpInside];
    [leftButton sizeToFit];
    
    //房间号label
    NSString * string =  [NSString stringWithFormat:@"房间：%@", _chatroom.roomId];
    CGRect rectTitle = [string boundingRectWithSize:CGSizeMake(999, 30)
                                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}
                                                                   context:nil];


    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(40, 0, rectTitle.size.width+20, 30)];
    title.font = [UIFont systemFontOfSize:12];
    title.textColor = [UIColor whiteColor];
    title.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    title.text = string;
    title.textAlignment = NSTextAlignmentCenter;

    title.layer.cornerRadius = 15;
    title.layer.masksToBounds = YES;
    [leftView addSubview:leftButton];
    [leftView addSubview:title];
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithCustomView:leftView];
    self.navigationItem.leftItemsSupplementBackButton = NO;
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    NSMutableArray *arrayItems=[NSMutableArray array];
    [arrayItems addObject:negativeSpacer];
    [arrayItems addObject:leftItem];
    negativeSpacer.width = -7;

    self.navigationItem.leftBarButtonItems = arrayItems;
}
-(void)refreshTecNavBar
{
    CGFloat btnWidth = 30;
    CGFloat btnHeight = 30;
    CGFloat btnMargin = 7;

    UIView * rightView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 3*btnMargin+3*btnWidth, 30)];
    NTESMeetingRole *myRole = [[NTESMeetingRolesManager sharedInstance] myRole];
    NSString *audioImage = myRole.audioOn ? @"chatroom_audio_on" : @"chatroom_audio_off";
    NSString *audioImageSelected = myRole.audioOn ? @"chatroom_audio_selected" : @"chatroom_audio_off_selected";

    NSString *videoImage = myRole.videoOn ? @"chatroom_video_on" : @"chatroom_video_off";
    NSString *videoImageSelected = myRole.audioOn ? @"chatroom_video_selected" : @"chatroom_video_off_selected";
    

    //音频按钮
    UIButton *audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
    audioButton.frame = CGRectMake(3*btnMargin+2*btnWidth, 0, btnWidth, btnHeight);
    [audioButton setImage:[UIImage imageNamed:audioImage] forState:UIControlStateNormal];
    [audioButton setImage:[UIImage imageNamed:audioImageSelected] forState:UIControlStateHighlighted];
    [audioButton addTarget:self action:@selector(onSelfAudioPressed:) forControlEvents:UIControlEventTouchUpInside];
    //视频按钮
    UIButton *videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
    videoButton.frame = CGRectMake(2*btnMargin+btnWidth, 0, btnWidth, btnHeight);
    [videoButton setImage:[UIImage imageNamed:videoImage] forState:UIControlStateNormal];
    [videoButton setImage:[UIImage imageNamed:videoImageSelected] forState:UIControlStateHighlighted];
    [videoButton addTarget:self action:@selector(onSelfVideoPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [rightView addSubview:audioButton];
    [rightView addSubview:videoButton];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightView];
    UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    NSMutableArray *arrayItems=[NSMutableArray array];
    [arrayItems addObject:negativeSpacer];
    [arrayItems addObject:rightItem];
    negativeSpacer.width = -btnMargin;
    self.navigationItem.rightBarButtonItems = arrayItems;

}
-(void)refreshStdNavBar
{
    NTESMeetingRole *myRole = [[NTESMeetingRolesManager sharedInstance] myRole];
    NSString *audioImage = myRole.audioOn ? @"chatroom_audio_on" : @"chatroom_audio_off";
    NSString *videoImage = myRole.videoOn ? @"chatroom_video_on" : @"chatroom_video_off";
    NSString *audioImageSelected = myRole.audioOn ? @"chatroom_audio_selected" : @"chatroom_audio_off_selected";
    NSString *videoImageSelected = myRole.audioOn ? @"chatroom_video_selected" : @"chatroom_video_off_selected";
    CGFloat btnWidth = 30;
    CGFloat btnHeight = 30;
    CGFloat btnMargin = 7;
    if (myRole.isActor&&!_isRemainStdNav) {  //有发言权限，变成3个按钮
        UIView * rightView = [[UIView alloc]initWithFrame:CGRectMake(0, 0,4*(btnWidth+btnMargin), btnHeight)];
        //视频按钮
        UIButton *videoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        videoButton.frame = CGRectMake(2*btnMargin+btnWidth, 0, btnWidth, btnHeight);
        [videoButton setImage:[UIImage imageNamed:videoImage] forState:UIControlStateNormal];
        [videoButton setImage:[UIImage imageNamed:videoImageSelected] forState:UIControlStateHighlighted];
        [videoButton addTarget:self action:@selector(onSelfVideoPressed:) forControlEvents:UIControlEventTouchUpInside];
        //音频按钮
        UIButton *audioButton = [UIButton buttonWithType:UIButtonTypeCustom];
        audioButton.frame = CGRectMake(3*btnMargin+2*btnWidth, 0, btnWidth, btnHeight);
        [audioButton setImage:[UIImage imageNamed:audioImage] forState:UIControlStateNormal];
        [audioButton setImage:[UIImage imageNamed:audioImageSelected] forState:UIControlStateHighlighted];
        [audioButton addTarget:self action:@selector(onSelfAudioPressed:) forControlEvents:UIControlEventTouchUpInside];
        //结束按钮
        UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        cancelButton.frame = CGRectMake(4*btnMargin+3*btnWidth, 0, btnWidth, btnHeight);
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"chatroom_interaction_bottom"] forState:UIControlStateNormal];
        [cancelButton setBackgroundImage:[UIImage imageNamed:@"chatroom_interaction_bottom_selected"] forState:UIControlStateHighlighted];

        cancelButton.titleLabel.font = [UIFont systemFontOfSize:11];
        [cancelButton setTitle:@"结束" forState:UIControlStateNormal];
        [cancelButton addTarget:self action:@selector(onCancelInteraction:) forControlEvents:UIControlEventTouchUpInside];
        cancelButton.tag = 10001;

        [rightView addSubview:audioButton];
        [rightView addSubview:videoButton];
        [rightView addSubview:cancelButton];

        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightView];
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        NSMutableArray *arrayItems=[NSMutableArray array];
        [arrayItems addObject:negativeSpacer];
        [arrayItems addObject:rightItem];
        negativeSpacer.width = -btnMargin;
        self.navigationItem.rightBarButtonItems = arrayItems;

    }
    else
    {
        UIView * rightView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 2*(btnWidth+btnMargin), btnHeight)];
        //互动按钮
        UIButton *raiseHandButton = [UIButton buttonWithType:UIButtonTypeCustom];
        raiseHandButton.frame = CGRectMake(btnWidth+2*btnMargin, 0, btnWidth, btnHeight);
            
        if (!myRole.isRaisingHand) {
            [raiseHandButton setImage:[UIImage imageNamed:@"chatroom_interaction"] forState:UIControlStateNormal];
            [raiseHandButton setImage:[UIImage imageNamed:@"chatroom_interaction_selected"] forState:UIControlStateHighlighted];
        }
        else{
            [raiseHandButton setBackgroundImage:[UIImage imageNamed:@"chatroom_interaction_bottom"] forState:UIControlStateNormal];
            [raiseHandButton setBackgroundImage:[UIImage imageNamed:@"chatroom_interaction_bottom_selected"] forState:UIControlStateHighlighted];
            raiseHandButton.titleLabel.font = [UIFont systemFontOfSize:11];
            [raiseHandButton setTitle:@"取消" forState:UIControlStateNormal];
        }
        
        [raiseHandButton addTarget:self action:@selector(onRaiseHandPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [rightView addSubview:raiseHandButton];
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];

        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightView];

        NSMutableArray *arrayItems=[NSMutableArray array];
        [arrayItems addObject:negativeSpacer];
        [arrayItems addObject:rightItem];
        negativeSpacer.width = -btnMargin;
        self.navigationItem.rightBarButtonItems = arrayItems;
    }
}

- (void)onBack:(id)sender
{
    NTESMeetingRole *myRole = [[NTESMeetingRolesManager sharedInstance] myRole];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"确定退出直播吗？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"退出", nil];
    [alert showAlertWithCompletionHandler:^(NSInteger index) {
        switch (index) {
            case 1:{
                if (myRole.isManager ) {
                    [self requestCloseChatRoom];
                }
                [self pop];
                break;
            }
                
            default:
                break;
        }
    }];
}
-(void)onCancelInteraction:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"确定退出互动么？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"退出", nil];
    [alert showAlertWithCompletionHandler:^(NSInteger index) {
        switch (index) {
            case 1:{
                [self onRaiseHandPressed:sender];
                break;
            }
                
            default:
                break;
        }
    }];
}

- (void)onRaiseHandPressed:(id)sender
{
    UIButton *btn = (UIButton*)sender;
    NTESMeetingRole *myRole = [[NTESMeetingRolesManager sharedInstance] myRole];
    if (btn.tag == 10001) {
        [[NIMAVChatSDK sharedSDK].netCallManager setMeetingRole:NO];
        myRole.isActor = NO;
        myRole.isRaisingHand = YES;
        myRole.videoOn = NO;
        myRole.audioOn = NO;
        myRole.whiteboardOn = NO;
    }
    [[NTESMeetingRolesManager sharedInstance] changeRaiseHand];
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

- (void)requestCloseChatRoom
{
    [SVProgressHUD show];
    __weak typeof(self) wself = self;
    
    [[NTESDemoService sharedService] closeChatRoom:_chatroom.roomId creator:_chatroom.creator completion:^(NSError *error, NSString *roomId) {
        [SVProgressHUD dismiss];
        if (error) {
            [wself.view makeToast:@"结束房间失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)requestChatRoomInfo
{
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomInfo:_chatroom.roomId completion:^(NSError * _Nullable error, NIMChatroom * _Nullable chatroom) {
        if (!error) {
            if([wself showFullScreenBtn:chatroom.ext])
            {
                wself.actorsView.showFullScreenBtn = YES;
            }
        }
        else
        {
            [wself.view makeToast:@"获取聊天室信息失败" duration:2.0 position:CSToastPositionCenter];
        }
    }];
}


- (void)removeActorSelectView
{
    if (self.actorSelectView) {
        [self.actorSelectView removeFromSuperview];
        self.actorSelectView = nil;
    }
}

- (void)pop
{
    if (!self.isPoped) {
        self.isPoped = YES;
       [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - Rotate supportedInterfaceOrientations
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
