//
//  NTESMeetingActorsView.m
//  NIMEducationDemo
//
//  Created by fenric on 16/4/9.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESMeetingActorsView.h"
#import "NTESMeetingRolesManager.h"
#import "UIView+NTES.h"
#import "NTESGLView.h"
#import <NIMAVChat/NIMAVChat.h>
#import "NTESVideoFSViewController.h"
#import "NTESBundleSetting.h"
#define NTESMeetingMaxActors 4

@interface NTESMeetingActorsView()<NIMNetCallManagerDelegate>
{
    NSMutableArray *_actorViews;
    NSMutableArray *_actors;
    NSMutableArray *_backgroundViews;
}

@property (nonatomic, strong) NTESVideoFSViewController *videoVc;
@property (nonatomic, strong) UIButton *fullScreenBtn;
@property (nonatomic, weak) UIView *localPreview;



@end

@implementation NTESMeetingActorsView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        _actorViews = [NSMutableArray array];
        _backgroundViews = [NSMutableArray array];
        _videoVc = [[NTESVideoFSViewController alloc]init];
        _fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *backgroundImage = [UIImage imageNamed:@"meeting_background"];
        _fullScreenBtn.hidden = YES;
        for (int i = 0; i < NTESMeetingMaxActors; i++) {
            UIImageView *background = [[UIImageView alloc] initWithImage:backgroundImage];
            [self addSubview:background];
            [_backgroundViews addObject:background];
            
            NTESGLView *view = [[NTESGLView alloc] initWithFrame:self.bounds];

            view.contentMode = [[NTESBundleSetting sharedConfig] videochatRemoteVideoContentMode];
            
            view.backgroundColor = [UIColor clearColor];
            [view render:nil width:0 height:0];
            [self addSubview:view];
            [_actorViews addObject:view];

        }
        [self updateActors];
        [[NIMAVChatSDK sharedSDK].netCallManager addDelegate:self];
    }
    return self;
}


- (void)dealloc
{
    [[NIMAVChatSDK sharedSDK].netCallManager removeDelegate:self];
}

- (void)onLocalDisplayviewReady:(UIView *)displayView
{
    
    if ([NTESMeetingRolesManager sharedInstance].myRole.isActor) {
        [self startLocalPreview:displayView];
        
        NSInteger type = [[NTESBundleSetting sharedConfig] beautifyType];
        //美颜
        [[NIMAVChatSDK sharedSDK].netCallManager selectBeautifyType:type] ;
    }
    else {
        _localPreview = displayView;
    }

}

- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    if (_actors.count == 0) {
        return;
    }
    NSUInteger viewIndex = [_actors indexOfObject:user];

    //判断是否全屏
    if(_isFullScreen)
    {
        if(viewIndex == 0)
        {
            [_videoVc onRemoteYUVReady:yuvData width:width height:height from:user];
        }
    }
    else
    {
        if (viewIndex != NSNotFound && viewIndex < NTESMeetingMaxActors) {
            NTESGLView *view = _actorViews[viewIndex];
            [view render:yuvData width:width height:height];
            if(viewIndex == 0)
            {
                if(_showFullScreenBtn)
                {
                    _fullScreenBtn.hidden = NO;
                }
                else
                {
                    _fullScreenBtn.hidden = YES;
                }
            }
        }
    }
}

-(void)setShowFullScreenBtn:(BOOL)showFullScreenBtn
{
    _showFullScreenBtn = showFullScreenBtn;
    if(!showFullScreenBtn)
    {
        _fullScreenBtn.hidden = !showFullScreenBtn;
    }
    //退出全屏
    if (self.isFullScreen&&!showFullScreenBtn ) {
        [_videoVc onExitFullScreen];
    }
}

-(void)goFullScreen
{
    [self.viewController presentViewController:_videoVc animated:NO completion:^{
        self.isFullScreen = YES;
    }];
}

- (void)startLocalPreview:(UIView *)view
{
    [self stopLocalPreview];

    DDLogInfo(@"Start local preview");

    _localPreview = view;

    NTESGLView *localView = _actorViews[[self localViewIndex]];
    
    [localView render:nil width:0 height:0];
    
    [localView  addSubview:view];
    
    [self layoutLocalPreview];

}


-(void)stopLocalPreview
{
    DDLogInfo(@"Stop local preview");
    if (_localPreview) {
        [_localPreview removeFromSuperview];
    }
}

- (void)layoutLocalPreview
{
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    CGFloat rotateDegree;
    switch (orientation) {
        case UIInterfaceOrientationPortraitUpsideDown:
            rotateDegree = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            rotateDegree = M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            rotateDegree = M_PI_2 * 3.0;
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationUnknown:
            rotateDegree = 0;
            break;
    }
    
    UIView *localView = _actorViews[[self localViewIndex]];

    _localPreview.transform = CGAffineTransformMakeRotation(rotateDegree);
    
    _localPreview.frame = localView.bounds;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    for (int i = 0; i < NTESMeetingMaxActors; i ++) {
        UIView *view = _actorViews[i];
        view.width = self.width / 2;
        view.height = self.height / 2;
        view.top = i < 2 ? 0 : self.height / 2;
        view.left = (i + 1) % 2 ? 0 : self.width / 2;
        if(i==0)
        {
            _fullScreenBtn.frame = CGRectMake(view.frame.size.width-7-30, view.frame.size.height-7-30, 30, 30);
            [_fullScreenBtn setImage: [UIImage imageNamed:@"chatroom_video_fullscreen"] forState:UIControlStateNormal];
            [_fullScreenBtn addTarget:self action:@selector(goFullScreen) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:_fullScreenBtn];
        }

        UIImageView *backgound = _backgroundViews[i];
        backgound.frame = view.frame;
    }
}

- (void)updateActors
{
    NSMutableArray *actors = [NSMutableArray arrayWithArray:[[NTESMeetingRolesManager sharedInstance] allActors]];
    
    [actors sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSString *actor1  = obj1;
        NSString *actor2  = obj2;
        NSString *myUid = [[NIMSDK sharedSDK].loginManager currentAccount];
        NTESMeetingRole *role1 = [[NTESMeetingRolesManager sharedInstance] role:actor1];
        NTESMeetingRole *role2 = [[NTESMeetingRolesManager sharedInstance] role:actor2];

        //Manager排第一
        if (role1.isManager) {
            return NSOrderedAscending;
        }
        else if (role2.isManager) {
            return NSOrderedDescending;
        }
        
        //自己排第二（如果自己不是Manager）
        if ([actor1 isEqualToString:myUid]) {
            return NSOrderedAscending;
        }
        else if ([actor2 isEqualToString:myUid]) {
            return NSOrderedDescending;
        }

        return NSOrderedAscending;

    }];

    if (actors.count != _actors.count) {
        for (NTESGLView *view in _actorViews) {
            [view render:nil width:0 height:0];
        }
    }
    
    _actors = actors;
    
    if (_localPreview) {
        if ([NTESMeetingRolesManager sharedInstance].myRole.videoOn) {
            [self onLocalDisplayviewReady:_localPreview];
        }
        else {
            [self stopLocalPreview];
        }

    }
}

-(NSUInteger)localViewIndex
{
    NSString *myUid = [[NIMSDK sharedSDK].loginManager currentAccount];
    if (_actors.count) {
        return [_actors indexOfObject:myUid];
    }
    else {
        return NSNotFound;
    }
}

@end
