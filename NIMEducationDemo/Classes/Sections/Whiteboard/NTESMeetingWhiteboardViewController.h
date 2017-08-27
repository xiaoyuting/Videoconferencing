//
//  NTESMeetingWhiteboardViewController.h
//  NIMEducationDemo
//
//  Created by fenric on 16/10/25.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESDocumentViewController.h"




@interface NTESMeetingWhiteboardViewController : UIViewController<NTESDocumentViewControllerDelegate>

- (instancetype)initWithChatroom:(NIMChatroom *)room;

- (void)checkPermission;

@end
