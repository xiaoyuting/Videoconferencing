//
//  NTESMeetingActionView.h
//  NIM
//
//  Created by chris on 16/1/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESChatroomSegmentedControl.h"
#import "NTESPageView.h"

@protocol NTESMeetingActionViewDataSource <NSObject>

@required
- (NSInteger)numberOfPages;

- (UIView *)viewInPage:(NSInteger)index;

- (CGFloat)actorsViewHeight;


@end


@protocol NTESMeetingActionViewDelegate <NSObject>

@optional

- (void)onSegmentControlChanged:(NTESChatroomSegmentedControl *)control;

- (void)onTouchActionBackground:(UITapGestureRecognizer *)gesture;

@end

@interface NTESMeetingActionView : UIView

@property (nonatomic, strong) NTESPageView *pageView;

@property (nonatomic, strong) NTESChatroomSegmentedControl *segmentedControl;

@property (nonatomic, strong) UIImageView *unreadRedTip;

@property (nonatomic,weak) id<NTESMeetingActionViewDataSource> datasource;

@property (nonatomic,weak) id<NTESMeetingActionViewDelegate> delegate;

- (instancetype)initWithDataSource:(id<NTESMeetingActionViewDataSource>) datasource;

- (void)reloadData;

@end
