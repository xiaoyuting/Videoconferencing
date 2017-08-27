//
//  NTESMeetingActorsView.h
//  NIMEducationDemo
//
//  Created by fenric on 16/4/9.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESMeetingActorsView : UIView

@property (nonatomic) BOOL isFullScreen;

@property (nonatomic) BOOL showFullScreenBtn;

- (void)updateActors;

-(void)stopLocalPreview;

@end
