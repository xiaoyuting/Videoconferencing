//
//  NTESDocumentViewController.h
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/13.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NTESDocumentHandler.h"
#import "NTESDocumentCell.h"

@protocol NTESDocumentViewControllerDelegate <NSObject>

-(void)showDocOnWhiteboard:(NIMDocTranscodingInfo*)info;

@end


@interface NTESDocumentViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,NTESDocumentHandlerDelegate,NTESDocumentCellDelegate>

@property (nonatomic,weak) id <NTESDocumentViewControllerDelegate> delegate;

@end
