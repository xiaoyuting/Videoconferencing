//
//  NTESMeetingWhiteboardViewController.m
//  NIMEducationDemo
//
//  Created by fenric on 16/10/25.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMeetingWhiteboardViewController.h"
#import "UIView+NTES.h"
#import "NTESMeetingRolesManager.h"
#import "NTESColorSelectView.h"
#import "NTESMeetingRTSManager.h"
#import "UIView+Toast.h"
#import "NTESWhiteboardCommand.h"
#import "NTESWhiteboardCmdHandler.h"
#import "NTESWhiteboardLines.h"
#import "NTESWhiteboardDrawView.h"
#import "NTESDocumentViewController.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESDocumentShareInfo.h"
#import "NTESDocumentHandler.h"
#import "UIImageView+WebCache.h"
#import "NTESDocDownloadManager.h"


@interface NTESMeetingWhiteboardViewController ()<NTESColorSelectViewDelegate, NTESMeetingRTSManagerDelegate, NTESWhiteboardCmdHandlerDelegate, NIMLoginManagerDelegate,NTESDocumentHandlerDelegate>
{
    BOOL _isManager;
    NSString *_name;
    NSString *_managerUid;
    int _myDrawColorRGB;
    BOOL _isJoined;
}

@property (nonatomic, strong) NTESWhiteboardDrawView *drawView;

@property (nonatomic, strong) UIView *controlPannel;

@property (nonatomic, strong) UIButton *clearAllButton;

@property (nonatomic, strong) UIButton *cancelLineButton;

@property (nonatomic, strong) UIButton *colorSelectButton;

@property (nonatomic, strong) UIButton *openDocumentButton;

@property (nonatomic, strong) NTESColorSelectView *colorSelectView;

@property (nonatomic, strong) UILabel *hintLabel;

@property (nonatomic, strong) NTESWhiteboardCmdHandler *cmdHander;

@property (nonatomic, strong) NTESDocumentHandler *docHander;

@property (nonatomic, strong) NTESWhiteboardLines *lines;

@property (nonatomic, strong) NSArray *colors;

@property (nonatomic, strong) NSString *myUid;

@property (nonatomic, strong) UIView *laserView;

@property (nonatomic, strong) UIImageView *docView;

@property (nonatomic, strong) NIMDocTranscodingInfo *docInfo;

@property (nonatomic, strong) UIButton *previousButton;

@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) UILabel *pageNumLabel;

@property (nonatomic, strong) UILabel *imgloadLabel;

@property (nonatomic, strong) UIButton *closeDocButton;

@property (nonatomic) int currentPage;

@property (nonatomic, strong) NSMutableDictionary *docInfoDic;

@end

@implementation NTESMeetingWhiteboardViewController

- (instancetype)initWithChatroom:(NIMChatroom *)room
{
    if (self = [super init]) {
        _name = room.roomId;
        _managerUid = room.creator;
        _cmdHander = [[NTESWhiteboardCmdHandler alloc] initWithDelegate:self];
        _docHander = [[NTESDocumentHandler alloc]initWithDelegate:self];
        [[NTESMeetingRTSManager sharedInstance] setDataHandler:_cmdHander];
        _colors = @[@(0x000000), @(0xd1021c), @(0xfddc01), @(0x7dd21f), @(0x228bf7), @(0x9b0df5)];
        if([NTESMeetingRolesManager sharedInstance].myRole.isManager){
        _myDrawColorRGB = [_colors[0] intValue];
        }
        else
        {
         _myDrawColorRGB = [_colors[4] intValue];
        }
        _lines = [[NTESWhiteboardLines alloc] init];
        
        _myUid = [[NIMSDK sharedSDK].loginManager currentAccount];
        
        _docInfoDic = [NSMutableDictionary dictionary];

    }
    return self;
}

- (void)dealloc
{
    [[NTESMeetingRTSManager sharedInstance] leaveCurrentConference];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NIMSDK sharedSDK].loginManager addDelegate:self];
    _isManager = [NTESMeetingRolesManager sharedInstance].myRole.isManager;
    [[NTESMeetingRTSManager sharedInstance] setDelegate:self];
    
    NSError *error;
    if (_isManager) {
        error = [[NTESMeetingRTSManager sharedInstance] reserveConference:_name];
    }
    else {
        error = [[NTESMeetingRTSManager sharedInstance] joinConference:_name];
    }
    
    if (error) {
        DDLogError(@"Error %zd reserve/join rts conference: %@", error.code, _name);
    }
    
    [self initUI];
}

- (void)initUI
{
    self.view.backgroundColor = UIColorFromRGB(0xedf1f5);
    [self.view addSubview:self.docView];

    [self.view addSubview:self.drawView];
    
    [self.view addSubview:self.controlPannel];
    
    [self.view addSubview:self.colorSelectView];
    [self.drawView addSubview:self.laserView];
    [self.docView setHidden:YES];
    [self.laserView setHidden:YES];
    
    [self.colorSelectView setHidden:YES];

    [self.controlPannel addSubview:self.cancelLineButton];
    [self.controlPannel addSubview:self.colorSelectButton];
    [self.controlPannel addSubview:self.pageNumLabel];
    [self.pageNumLabel setHidden:YES];

    if (_isManager) {
        [self.controlPannel addSubview:self.clearAllButton];
        [self.controlPannel addSubview:self.openDocumentButton];
        [self.controlPannel addSubview:self.previousButton];
        [self.controlPannel addSubview:self.nextButton];
        [self.drawView addSubview:self.closeDocButton];
        [self.drawView addSubview:self.imgloadLabel];
        [self.nextButton setHidden:YES];
        [self.previousButton setHidden:YES];
        [self.closeDocButton setHidden:YES];
        [self.imgloadLabel setHidden:YES];
    }
    else {
        [self.controlPannel addSubview:self.hintLabel];
    }
    
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self checkPermission];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat spacing = 15.f;

    self.controlPannel.width = self.view.width + 2.f;
    self.controlPannel.height = 50.f;
    self.controlPannel.left = - 1.f;
    self.controlPannel.bottom = self.view.bottom + 1.f;
    
    self.colorSelectButton.left = spacing;
    self.colorSelectButton.bottom = self.controlPannel.height - 7.f;
    

    self.cancelLineButton.left = self.colorSelectButton.right + spacing;
    self.cancelLineButton.bottom = self.colorSelectButton.bottom;

    self.clearAllButton.left = self.cancelLineButton.right + spacing;
    self.clearAllButton.bottom = self.cancelLineButton.bottom;

    self.openDocumentButton.left = self.clearAllButton.right + spacing;
    self.openDocumentButton.bottom = self.clearAllButton.bottom;

    
    self.colorSelectView.width = 34.f;
    self.colorSelectView.height = self.colorSelectView.width * _colors.count;
    self.colorSelectView.centerX = self.colorSelectButton.centerX;
    self.colorSelectView.bottom = self.controlPannel.top - 3.5f ;
    //小屏适配
    if (self.colorSelectView.height > self.view.height - self.controlPannel.height) {
        self.colorSelectView.height = self.view.height - self.controlPannel.height;
        self.colorSelectView.bottom = self.controlPannel.top;
    }

    
    self.hintLabel.left = self.cancelLineButton.right + spacing / 2.f;
    self.hintLabel.centerY = self.controlPannel.height / 2.f;
    
    
    CGFloat drawViewWidth = self.view.width - spacing;
    CGFloat drawViewHeight = self.view.height - self.controlPannel.height - spacing;
    
    if (drawViewHeight > drawViewWidth * 3.f / 4.f) {
        drawViewHeight = drawViewWidth * 3.f / 4.f;
    }
    else {
        drawViewWidth = drawViewHeight * 4.f / 3.f;
    }
    
    self.drawView.width = drawViewWidth;
    self.drawView.height = drawViewHeight;
    
    self.drawView.left = (self.view.width - self.drawView.width) / 2.f;
    self.drawView.top = self.view.top + (self.view.height - self.controlPannel.height - self.drawView.height) / 2.f;
    
    self.docView.width = drawViewWidth;
    self.docView.height = drawViewHeight;
    
    self.docView.left = self.drawView.left;
    self.docView.top = self.drawView.top;
    
    self.nextButton.right = self.view.width - 10.f;
    self.nextButton.centerY = self.colorSelectButton.centerY;
    
    if (_isManager) {
        self.pageNumLabel.right = self.nextButton.left - 5.f;
        self.pageNumLabel.centerY = self.colorSelectButton.centerY;
    }
    else
    {
        self.pageNumLabel.right = self.view.width - 15.f;
        self.pageNumLabel.centerY = self.colorSelectButton.centerY;
    }
    

    self.previousButton.right = self.pageNumLabel.left - 5.f;
    self.previousButton.centerY = self.colorSelectButton.centerY;

    self.closeDocButton.right = self.drawView.width - 5.f;
    self.closeDocButton.top = 5.f;
    
    self.imgloadLabel.width = drawViewWidth;
    self.imgloadLabel.height = drawViewHeight;
    self.imgloadLabel.centerX = self.drawView.width / 2.f;
    self.imgloadLabel.centerY = self.drawView.height / 2.f;
    

}


- (void)checkPermission
{
    if ([NTESMeetingRolesManager sharedInstance].myRole.whiteboardOn && _isJoined) {
        self.hintLabel.hidden = YES;
        [self.colorSelectButton setBackgroundColor:UIColorFromRGB(_myDrawColorRGB)];
        self.colorSelectButton.enabled = YES;
        self.cancelLineButton.enabled = YES;
        self.clearAllButton.enabled = YES;
    }
    else {
        self.hintLabel.hidden = NO;
        [self.colorSelectButton setBackgroundColor:[UIColor clearColor]];
        self.colorSelectButton.enabled = NO;
        self.cancelLineButton.enabled = NO;
        self.clearAllButton.enabled = NO;
        self.colorSelectView.hidden = YES;

    }
}

- (UIView *)drawView
{
    if (!_drawView) {
        _drawView = [[NTESWhiteboardDrawView alloc] initWithFrame:CGRectZero];
        _drawView.backgroundColor = [UIColor whiteColor];
        _drawView.layer.borderWidth = 1;
        _drawView.layer.borderColor = UIColorFromRGB(0xd7dade).CGColor;

        _drawView.dataSource = _lines;
    }
    return _drawView;
}

- (UIView *)laserView
{
    if (!_laserView) {
        _laserView = [[UIView alloc]initWithFrame:CGRectZero];
        _laserView.width = 7;
        _laserView.height = 7;
        _laserView.backgroundColor = [UIColor redColor];
        _laserView.layer.cornerRadius = 3.5;
        _laserView.layer.masksToBounds = YES;
    }
    return _laserView;
}

- (UIView *)controlPannel
{
    if (!_controlPannel) {
        _controlPannel = [[UIView alloc] init];
        _controlPannel.layer.borderWidth = 1;
        _controlPannel.layer.borderColor = UIColorFromRGB(0xd7dade).CGColor;
        _controlPannel.backgroundColor = [UIColor whiteColor];
    }
    return _controlPannel;
}

- (UIButton *)clearAllButton
{
    if (!_clearAllButton) {
        _clearAllButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        [_clearAllButton addTarget:self action:@selector(onClearAllPressed:)  forControlEvents:UIControlEventTouchUpInside];
        
        [_clearAllButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_clear_normal"] forState:UIControlStateNormal];
        [_clearAllButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_clear_pressed"] forState:UIControlStateHighlighted];
        [_clearAllButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_clear_disabled"] forState:UIControlStateDisabled];
    }
    return _clearAllButton;
}

- (UIButton *)cancelLineButton
{
    if (!_cancelLineButton) {
        
        _cancelLineButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        [_cancelLineButton addTarget:self action:@selector(onCancelLinePressed:)  forControlEvents:UIControlEventTouchUpInside];
        
        [_cancelLineButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_cancel_normal"] forState:UIControlStateNormal];
        [_cancelLineButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_cancel_pressed"] forState:UIControlStateHighlighted];
        [_cancelLineButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_cancel_disabled"] forState:UIControlStateDisabled];

    }
    return _cancelLineButton;
}

- (UIButton *)colorSelectButton
{
    if (!_colorSelectButton) {
        _colorSelectButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        _colorSelectButton.layer.cornerRadius = 35.f / 2.f;
        [_colorSelectButton setBackgroundColor:UIColorFromRGB(_myDrawColorRGB)];
        [_colorSelectButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_select_color_disabled"] forState:UIControlStateDisabled];

        [_colorSelectButton addTarget:self action:@selector(onColorSelectPressed:)  forControlEvents:UIControlEventTouchUpInside];
        
        UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(9.f, 9.f, 17.f, 17.f)];
        circle.layer.cornerRadius = 17.f / 2.f;
        circle.layer.borderColor = [UIColor whiteColor].CGColor;
        circle.layer.borderWidth = 1;
        [circle setUserInteractionEnabled:NO];
        [_colorSelectButton addSubview:circle];
    }
    return _colorSelectButton;
}

-(UIButton*)openDocumentButton
{
    if (!_openDocumentButton) {
        _openDocumentButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        [_openDocumentButton addTarget:self action:@selector(onOpenDocumentPressed:)  forControlEvents:UIControlEventTouchUpInside];
        
        [_openDocumentButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_file_normal"] forState:UIControlStateNormal];
        [_openDocumentButton setBackgroundImage:[UIImage imageNamed:@"btn_whiteboard_file_pressed"] forState:UIControlStateHighlighted];



    }
    return _openDocumentButton;
}

-(UIButton*)previousButton
{
    if (!_previousButton) {
        _previousButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        [_previousButton addTarget:self action:@selector(onPreviousPagePressed:)  forControlEvents:UIControlEventTouchUpInside];
        [_previousButton setImageEdgeInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
        [_previousButton setImage:[UIImage imageNamed:@"btn_whiteboard_page_previous"] forState:UIControlStateNormal];
        [_previousButton setImage:[UIImage imageNamed:@"btn_whiteboard_page_previous_pressed"] forState:UIControlStateHighlighted];
        [_previousButton setImage:[UIImage imageNamed:@"btn_whiteboard_page_previous_disable"] forState:UIControlStateDisabled];
    }
    return _previousButton;
}

-(UIButton*)nextButton
{
    if (!_nextButton) {
        _nextButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        [_nextButton addTarget:self action:@selector(onNextPagePressed:)  forControlEvents:UIControlEventTouchUpInside];
        [_nextButton setImageEdgeInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
        [_nextButton setImage:[UIImage imageNamed:@"btn_whiteboard_page_next"] forState:UIControlStateNormal];
        [_nextButton setImage:[UIImage imageNamed:@"btn_whiteboard_page_next_pressed"] forState:UIControlStateHighlighted];
        [_nextButton setImage:[UIImage imageNamed:@"btn_whiteboard_page_next_disable"] forState:UIControlStateDisabled];

    }
    return _nextButton;
}

-(UIButton*)closeDocButton
{
    if (!_closeDocButton) {
        _closeDocButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 35.f, 35.f)];
        [_closeDocButton addTarget:self action:@selector(onCloseDocPressed:)  forControlEvents:UIControlEventTouchUpInside];
        _closeDocButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_closeDocButton setTitle:@"关闭" forState:UIControlStateNormal];
        [_closeDocButton setBackgroundImage:[UIImage imageNamed:@"chatroom_interaction_bottom"] forState:UIControlStateNormal];
        [_closeDocButton setBackgroundImage:[UIImage imageNamed:@"chatroom_interaction_bottom_selected"] forState:UIControlStateHighlighted];
    }
    return _closeDocButton;
}

- (UIImageView*)docView
{
    if (!_docView) {
        _docView = [[UIImageView alloc]initWithFrame:CGRectZero];
        _docView.contentMode = UIViewContentModeScaleAspectFit;
        _docView.backgroundColor = [UIColor whiteColor];
    }
    return _docView;
}
- (NTESColorSelectView *)colorSelectView
{
    if (!_colorSelectView) {
        _colorSelectView = [[NTESColorSelectView alloc] initWithFrame:CGRectZero
                                                               colors:_colors
                                                             delegate:self];
    }
    return _colorSelectView;
}

- (UILabel *)hintLabel
{
    if (!_hintLabel) {
        _hintLabel = [[UILabel alloc] init];
        _hintLabel.text = @"加入互动后可在上方涂鸦";
        _hintLabel.textColor = UIColorFromRGB(0x999999);
        _hintLabel.font = [UIFont systemFontOfSize:12.f];
        _hintLabel.textAlignment = NSTextAlignmentCenter;
        [_hintLabel sizeToFit];
    }
    return _hintLabel;
}

- (UILabel *)pageNumLabel
{
    if (!_pageNumLabel) {
        _pageNumLabel = [[UILabel alloc] init];
        _pageNumLabel.text = [NSString stringWithFormat:@"%d/%lu",_currentPage,(unsigned long)_docInfo.numberOfPages];
                _pageNumLabel.textColor = UIColorFromRGB(0x999999);
        _pageNumLabel.font = [UIFont systemFontOfSize:15.f];
        _pageNumLabel.textAlignment = NSTextAlignmentCenter;
        [_pageNumLabel sizeToFit];
    }
    return _pageNumLabel;
}

- (UILabel *)imgloadLabel
{
    if (!_imgloadLabel) {
        _imgloadLabel = [[UILabel alloc] init];
        _imgloadLabel.text = @"加载中...";
        _imgloadLabel.textColor = UIColorFromRGB(0x999999);
        _imgloadLabel.font = [UIFont systemFontOfSize:15.f];
        _imgloadLabel.textAlignment = NSTextAlignmentCenter;
        _imgloadLabel.backgroundColor = [UIColor whiteColor];
    }
    return _imgloadLabel;
}


-(void)setCurrentPage:(int)currentPage
{
    _currentPage = currentPage;
    if (self.docInfo.numberOfPages ==1) {
        self.previousButton.enabled = NO;
        self.nextButton.enabled = NO;
    }
    else
    {
        if (_currentPage == 1) {
            self.previousButton.enabled = NO;
            self.nextButton.enabled = YES;
        }
        else if (_currentPage == self.docInfo.numberOfPages) {
            self.nextButton.enabled = NO;
            self.previousButton.enabled = YES;
        }
        else
        {
            self.previousButton.enabled = YES;
            self.nextButton.enabled = YES;
        }
    }
    self.pageNumLabel.text = [NSString stringWithFormat:@"%d/%lu",_currentPage,(unsigned long)_docInfo.numberOfPages];
    [self.pageNumLabel sizeToFit];
    [self.view setNeedsLayout];
    
    if (_isManager) {
        [self onClearAllPressed:nil];
    }
}
#pragma mark - User Interactions
- (void)onClearAllPressed:(id)sender
{
    [_lines clear];
    [_cmdHander sendPureCmd:NTESWhiteBoardCmdTypeClearLines to:nil];
    
}

- (void)onCancelLinePressed:(id)sender
{
    [_lines cancelLastLine:_myUid];
    [_cmdHander sendPureCmd:NTESWhiteBoardCmdTypeCancelLine to:nil];
}

- (void)onColorSelectPressed:(id)sender
{
    [self.colorSelectView setHidden:!(self.colorSelectView.hidden)];
}

- (void)onColorSeclected:(int)rgbColor
{
    [self.colorSelectButton setBackgroundColor:UIColorFromRGB(rgbColor)];
    _myDrawColorRGB = rgbColor;
    [self.colorSelectView setHidden:YES];
}

- (void)onOpenDocumentPressed:(id)sender
{
    NTESDocumentViewController *docVc = [[NTESDocumentViewController alloc]init];
    docVc.delegate = self;
    [self.navigationController pushViewController:docVc animated:YES];
}

- (void)onNextPagePressed:(id)sender
{
    self.currentPage++;
    [self loadImageOnWhiteboard];
}

- (void)onPreviousPagePressed:(id)sender
{
    self.currentPage--;
    [self loadImageOnWhiteboard];
}

-(void)onCloseDocPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"确定关闭文档，回到纯白版模式吗？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"关闭文档", nil];
    [alert showAlertWithCompletionHandler:^(NSInteger index) {
        switch (index) {
            case 1:{
                self.docView.hidden = YES;
                self.nextButton.hidden = YES;
                self.previousButton.hidden = YES;
                self.pageNumLabel.hidden = YES;
                self.closeDocButton.hidden = YES;
                self.drawView.backgroundColor = [UIColor whiteColor];
                self.currentPage = 0;
                [self onSendDocShareInfoToUser:nil];
                break;
            }
                
            default:
                break;
        }
    }];
}
#pragma mark  - UIResponder
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.colorSelectView.hidden = YES;
    CGPoint p = [[touches anyObject] locationInView:_drawView];
    [self onPointCollected:p type:NTESWhiteboardPointTypeStart];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:_drawView];
    [self onPointCollected:p type:NTESWhiteboardPointTypeMove];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint p = [[touches anyObject] locationInView:_drawView];
    [self onPointCollected:p type:NTESWhiteboardPointTypeEnd];
}

- (void)onPointCollected:(CGPoint)p type:(NTESWhiteboardPointType)type
{
    if (!([NTESMeetingRolesManager sharedInstance].myRole.whiteboardOn)) {
        return;
    }
    
    if (!_isJoined) {
        return;
    }
    
//    if (p.x < 0 || p.y < 0 || p.x > _drawView.frame.size.width || p.y > _drawView.frame.size.height) {
//        return;
//    }
    
    NTESWhiteboardPoint *point = [[NTESWhiteboardPoint alloc] init];
    point.type = type;
    point.xScale = p.x/_drawView.frame.size.width;
    point.yScale = p.y/_drawView.frame.size.height;
    point.colorRGB = _myDrawColorRGB;
    [_cmdHander sendMyPoint:point];
    [_lines addPoint:point uid:_myUid];
}


# pragma mark - NTESMeetingRTSManagerDelegate
- (void)onReserve:(NSString *)name result:(NSError *)result
{
    if (result == nil) {
        NSError *result = [[NTESMeetingRTSManager sharedInstance] joinConference:_name];
        DDLogError(@"join rts conference: %@ result %zd", _name, result.code);
    }
    else {
        [self.view makeToast:[NSString stringWithFormat:@"预订白板出错:%zd", result.code]];
    }
}

- (void)onJoin:(NSString *)name result:(NSError *)result
{
    if (result == nil) {
        _isJoined = YES;
        [self checkPermission];
        
        if (_isManager) {
            [_cmdHander sendPureCmd:NTESWhiteBoardCmdTypeSyncPrepare to:nil];
            if ([_lines hasLines]) {
                [_cmdHander sync:[_lines allLines] toUser:nil];
            }
            [self onSendDocShareInfoToUser:nil];
        }
        else {
            [_lines clear];
            [_cmdHander sendPureCmd:NTESWhiteBoardCmdTypeSyncRequest to:_managerUid];
        }
    }
}

- (void)onLeft:(NSString *)name error:(NSError *)error
{
    [self.view makeToast:[NSString stringWithFormat:@"已离开白板:%zd", error.code]];
    _isJoined = NO;
    
    NSError *result = [[NTESMeetingRTSManager sharedInstance] joinConference:_name];
    DDLogError(@"Rejoin rts conference: %@ result %zd", _name, result.code);
    
    [self checkPermission];
}

- (void)onUserJoined:(NSString *)uid conference:(NSString *)name
{
    
}

- (void)onUserLeft:(NSString *)uid conference:(NSString *)name
{
    
}

#pragma mark - NTESWhiteboardCmdHandlerDelegate
- (void)onReceivePoint:(NTESWhiteboardPoint *)point from:(NSString *)sender
{
    [_lines addPoint:point uid:sender];
}

- (void)onReceiveCmd:(NTESWhiteBoardCmdType)type from:(NSString *)sender
{
    if (type == NTESWhiteBoardCmdTypeCancelLine) {
        [_lines cancelLastLine:sender];
    }
    else if (type == NTESWhiteBoardCmdTypeClearLines) {
        [_lines clear];
        [_cmdHander sendPureCmd:NTESWhiteBoardCmdTypeClearLinesAck to:nil];
    }
    else if (type == NTESWhiteBoardCmdTypeClearLinesAck) {
        [_lines clearUser:sender];
    }
    else if (type == NTESWhiteBoardCmdTypeSyncPrepare) {
        [_lines clear];
        [_cmdHander sendPureCmd:NTESWhiteBoardCmdTypeSyncPrepareAck to:sender];
    }
}

- (void)onReceiveSyncRequestFrom:(NSString *)sender
{
    if (_isManager) {
        [_cmdHander sync:[_lines allLines] toUser:sender];
        if (!self.docView.hidden) {
            [self onSendDocShareInfoToUser:sender];
        }
    }
}

- (void)onReceiveSyncPoints:(NSMutableArray *)points owner:(NSString *)owner
{
    [_lines clearUser:owner];
    
    for (NTESWhiteboardPoint *point in points) {
        [_lines addPoint:point uid:owner];
    }
}

- (void)onReceiveLaserPoint:(NTESWhiteboardPoint *)point from:(NSString *)sender
{
    [self.laserView setHidden:NO];
     CGPoint p = CGPointMake(point.xScale * self.drawView.frame.size.width , point.yScale * self.drawView.frame.size.height);
    self.laserView.center = p;
}

-(void)onReceiveHiddenLaserfrom:(NSString *)sender
{
    [self.laserView setHidden:YES];
}

-(void)onReceiveDocShareInfo:(NTESDocumentShareInfo *)shareInfo from:(NSString *)sender
{
    self.currentPage = shareInfo.currentPage;
    if (shareInfo.currentPage == 0) {
        self.drawView.backgroundColor = [UIColor whiteColor];
        [self.pageNumLabel setHidden:YES];
        return;
    }
    if (![self.docInfoDic objectForKey:shareInfo.docId])
    {
        [_docHander inquireDocInfo:shareInfo.docId];
    }
    else
    {
        self.docInfo = [self.docInfoDic objectForKey:shareInfo.docId];
        [self showDocOnStdWhiteboard];
    }
}

#pragma mark - NTESDocumentHandlerDelegate
-(void)notifyGetDocInfo:(NIMDocTranscodingInfo *)docInfo
{
    self.docInfo = docInfo;
    self.pageNumLabel.text = [NSString stringWithFormat:@"%d/%lu",_currentPage,(unsigned long)_docInfo.numberOfPages];
    [self.pageNumLabel sizeToFit];
    [self.docInfoDic setObject:docInfo forKey:docInfo.docId];
    [self showDocOnStdWhiteboard];
}

#pragma mark - NTESDocumentViewControllerDelegate
-(void)showDocOnWhiteboard:(NIMDocTranscodingInfo *)info
{
    self.docInfo = info;
    self.docView.hidden = NO;
    self.currentPage = 1;
    [self loadImageOnWhiteboard];
    
    self.pageNumLabel.hidden = NO;
    self.nextButton.hidden = NO;
    self.previousButton.hidden = NO;
    self.closeDocButton.hidden = NO;
    self.drawView.backgroundColor = [UIColor clearColor];
}

- (void)showDocOnStdWhiteboard
{
    NSString * url= [self.docInfo transcodedUrl:_currentPage ofQuality:NIMDocTranscodingQualityMedium];
    [self.docView sd_setImageWithURL:[NSURL URLWithString:url]];
    [self.docView setHidden:NO];
    [self.pageNumLabel setHidden:NO];
    self.drawView.backgroundColor = [UIColor clearColor];
}

- (void)onSendDocShareInfoToUser:(NSString*)sender{
    
    NTESDocumentShareInfo *shareInfo = [[NTESDocumentShareInfo alloc]init];
    shareInfo.docId = self.docInfo.docId;
    shareInfo.currentPage = _currentPage;
    shareInfo.pageCount = (int)self.docInfo.numberOfPages;
    shareInfo.type = NTESDocShareTypeTurnThePage;
    
    [_cmdHander sendDocShareInfo:shareInfo toUser:sender];
}

#pragma mark - NIMLoginManagerDelegate
- (void)onLogin:(NIMLoginStep)step
{
    if (step == NIMLoginStepLoginOK) {
        if (!_isJoined) {
            NSError *result = [[NTESMeetingRTSManager sharedInstance] joinConference:_name];
            DDLogError(@"Rejoin rts conference: %@ result %zd", _name, result.code);
        }
    }
}

#pragma mark - private method
-(void)loadImageOnWhiteboard
{
    NSString *filePath = [self getFilePathWithPage:_currentPage];
    UIImage* image = [self loadImage:filePath];
    //重新下载
    if (!image) {
        [self.imgloadLabel setHidden:NO];
        __weak typeof(self) weakself = self;
        [[NTESDocDownloadManager sharedManager]downLoadDoc:self.docInfo page:_currentPage completeBlock:^(NSError *error) {
            if (!error) {
                UIImage *image = [weakself loadImage:filePath];
                [weakself.imgloadLabel setHidden:YES];
                [weakself.docView setImage:image];
            }
            else
            {
                //加载失败
                [weakself.imgloadLabel setText:@"加载失败"];
                [weakself.imgloadLabel setHidden:NO];
            }
        }];
    }
    else
    {
        [self.imgloadLabel setHidden:YES];
        [self.docView setImage:image];
    }
    [self onSendDocShareInfoToUser:nil];
}

-(NSString *)getFilePathWithPage:(NSInteger)pageNum
{
    NSString *filePath = [[NTESDocumentHandler getFilePathPrefix:self.docInfo.docId]stringByAppendingString:[NSString stringWithFormat:@"%@_%zd.png",self.docInfo.docName,pageNum]];
                            
     return filePath;
}

-(UIImage *)loadImage:(NSString*)filePath{

    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        NSData * data = [NSData dataWithContentsOfFile:filePath];
        UIImage *image = [UIImage imageWithData:data];
        return image;
    }
    return nil;
}


@end
