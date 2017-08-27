//
//  NTESActorSelectView.h
//  NIMEducationDemo
//
//  Created by fenric on 16/4/28.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NTESActorSelectViewDelegate <NSObject>

- (void)onSelectedAudio:(BOOL)audioOn video:(BOOL)videoOn whiteboard:(BOOL)whiteboardOn;

@end

@interface NTESActorSelectView : UIView

@property (nonatomic, weak) id<NTESActorSelectViewDelegate> delegate;

@end
