//
//  VideoFSViewController.m
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/9.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESVideoFSViewController.h"
#import "NTESGLView.h"

@interface NTESVideoFSViewController ()
@property (nonatomic,strong)NTESGLView *videoView ;
@property (nonatomic,strong)UIButton *backBtn ;

@end

@implementation NTESVideoFSViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.view.backgroundColor = [UIColor whiteColor];
    // Do any additional setup after loading the view.
    
    _videoView = [[NTESGLView alloc]initWithFrame:CGRectZero];
    
    _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_backBtn setImage:[UIImage imageNamed: @"chatroom_video_fullscreen_off"]forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_videoView];
    [self.view addSubview:_backBtn];

    
}

-(void)viewWillAppear:(BOOL)animated
{
    _videoView.contentMode = UIViewContentModeScaleAspectFit;
}

-(void)viewDidLayoutSubviews
{
    _videoView.frame =self.view.frame;
    _backBtn.frame = CGRectMake(7, self.view.frame.size.height-7-30, 30, 30);
    _videoView.transform = CGAffineTransformMakeRotation(M_PI_2);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)goBack
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)onExitFullScreen
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user
{
    [_videoView render:yuvData width:width height:height];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
