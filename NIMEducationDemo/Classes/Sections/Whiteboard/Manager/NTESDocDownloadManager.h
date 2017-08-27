//
//  NTESDocDownloadManager.h
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/21.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESDocumentCell.h"

typedef void(^DocDownLoadPageCompleteBlock)( NSError * error);

typedef NS_ENUM(NSUInteger, NTESDocDownloadType){
    NTESDocDownloadTypeNotFound = 0,
    NTESDocDownloadTypeCompleted = 1,
    NTESDocDownloadTypeNotCompleted = 2,
    NTESDocDownloadTypeFailed = 3,
};

@protocol NTESDocDownloadManagerDelegate <NSObject>

-(void)notifyDownloadState;

@end

@interface NTESDocDownloadManager : NSObject

+ (instancetype)sharedManager;

-(NTESDocDownloadType)downlaodCompelete:(NSString*)docId;
-(void)addDelegate:(id<NTESDocDownloadManagerDelegate>)delegate;
-(void)downLoadDoc:(NIMDocTranscodingInfo*)info;
-(void)downLoadDoc:(NIMDocTranscodingInfo*)info page:(int)page completeBlock:(DocDownLoadPageCompleteBlock)completeBlock;

@end
