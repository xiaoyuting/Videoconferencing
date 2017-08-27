//
//  NTESDocumentCell.h
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/13.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^DocDownloadCompleteBlock)( NSError * error);
typedef void(^DocDeleteCompleteBlock)( NSError * error);

@protocol NTESDocumentCellDelegate <NSObject>


-(void)onPressedUseDoc:(NIMDocTranscodingInfo*)info ;
-(void)onPressedDeleteDoc:(NIMDocTranscodingInfo*)info;
-(void)onPressedDownloadDoc:(NIMDocTranscodingInfo*)info;
-(BOOL)checkDocInLocal:(NIMDocTranscodingInfo*)info;


@end

@interface NTESDocumentCell : UITableViewCell

@property(nonatomic,weak)id<NTESDocumentCellDelegate> delegate;
-(void)refresh:(NIMDocTranscodingInfo*)info;

@end
