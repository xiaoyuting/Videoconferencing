//
//  VideoFSViewController.h
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/9.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NTESVideoFSViewController : UIViewController

- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
                    from:(NSString *)user;

- (void)onExitFullScreen;
@end
