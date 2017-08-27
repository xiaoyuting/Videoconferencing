//
//  NTESColorSelectView.m
//  NIMEducationDemo
//
//  Created by fenric on 16/10/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESColorSelectView.h"
#import "UIView+NTES.h"

@interface NTESColorSelectView()

@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) NSMutableArray <UIButton *> *selectButtons;
@property(nonatomic, weak) id<NTESColorSelectViewDelegate> delegate;

@end

@implementation NTESColorSelectView

- (instancetype)initWithFrame:(CGRect)frame
                       colors:(NSArray *)colors
                     delegate:(id<NTESColorSelectViewDelegate>)delegate
{
    if (self = [super initWithFrame:frame]) {
        _colors = colors;
        _delegate = delegate;
        _selectButtons = [[NSMutableArray alloc] init];
        for (int i = 0 ; i < _colors.count; i ++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
            [button setBackgroundColor:UIColorFromRGB([_colors[i] unsignedIntValue])];
            button.tag = i;
            [button addTarget:self action:@selector(onColorPressed:)  forControlEvents:UIControlEventTouchUpInside];
            [_selectButtons addObject:button];
            [self addSubview:button];
        }
        
    }
    return self;
}

- (void)layoutSubviews
{
    CGFloat space = self.height / _selectButtons.count;
    
    for (int i = 0; i < _selectButtons.count; i++) {
        UIButton *button = _selectButtons[i];
        button.height = 27.f;
        button.width = button.height;
        button.centerX = self.width / 2.f;
        button.centerY = space / 2.f + space * i;
        button.layer.cornerRadius = button.height / 2.f;
    }
}

- (void)onColorPressed:(id)sender
{
    UIButton *button = sender;
    if (_delegate) {
        [_delegate onColorSeclected:[_colors[button.tag] unsignedIntValue]];
    }
}


@end
