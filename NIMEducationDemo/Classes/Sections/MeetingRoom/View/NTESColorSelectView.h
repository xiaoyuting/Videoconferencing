//
//  NTESColorSelectView.h
//  NIMEducationDemo
//
//  Created by fenric on 16/10/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NTESColorSelectViewDelegate <NSObject>

- (void)onColorSeclected:(int)rgbColor;

@end

@interface NTESColorSelectView : UIView

- (instancetype)initWithFrame:(CGRect)frame
                       colors:(NSArray *)colors
                     delegate:(id<NTESColorSelectViewDelegate>)delegate;


@end
