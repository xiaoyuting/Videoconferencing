//
//  NTESDocDownloadManager.m
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/21.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESDocDownloadManager.h"
#import "NTESDocumentHandler.h"

@interface NTESDocDownloadManager ()

@property(nonatomic, strong)NSMutableDictionary *docDic;
@property(nonatomic, strong)NSMutableArray *downloadTask;

@property (nonatomic,weak) id<NTESDocDownloadManagerDelegate> delegate;

@end

@implementation NTESDocDownloadManager

+ (instancetype)sharedManager
{
    static NTESDocDownloadManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NTESDocDownloadManager alloc] init];
        instance.docDic = [NSMutableDictionary dictionary];
        instance.downloadTask = [NSMutableArray array];
    });
    return instance;
}

-(void)addDelegate:(id<NTESDocDownloadManagerDelegate>)delegate
{
    _delegate = delegate;
}

-(void)downLoadDoc:(NIMDocTranscodingInfo*)info
{
    __block int completedCount = 0;
    __block int failedCount = 0;
    __block NSError * docError;
    NSString * filePathPrefix = [NTESDocumentHandler getFilePathPrefix:info.docId];
    [_docDic setObject:@(NTESDocDownloadTypeNotCompleted) forKey:info.docId];
    
    __weak typeof(self) weakself = self;
    for (int i = 0; i<info.numberOfPages; i++) {
        id<NIMResourceManager> resManager = [[NIMSDK sharedSDK] resourceManager];
        NSString * url = [info transcodedUrl:i+1 ofQuality:NIMDocTranscodingQualityHigh];
        NSString * filePath = [filePathPrefix stringByAppendingString:[NSString stringWithFormat:@"%@_%d.png",info.docName,i+1]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            [resManager  download:url
                         filepath:filePath
                         progress:nil
                       completion:^(NSError *error) {
                           if (error){
                               failedCount++;
                               docError = error;
                           }
                           else{
                               completedCount++;
                           }
                           if (completedCount == info.numberOfPages ){
                               [weakself.docDic setObject:@(NTESDocDownloadTypeCompleted) forKey:info.docId];
                               if(weakself.delegate &&[weakself.delegate respondsToSelector:@selector(notifyDownloadState)])
                               {
                                   [weakself.delegate notifyDownloadState];
                               }

                           }
                           else if (failedCount+completedCount == info.numberOfPages){
                               [weakself.docDic setObject:@(NTESDocDownloadTypeFailed) forKey:info.docId];
                               if(weakself.delegate &&[weakself.delegate respondsToSelector:@selector(notifyDownloadState)])
                               {
                                   [weakself.delegate notifyDownloadState];
                               }
                           }
                       }];
        }
        //已经下载
        else
        {
            completedCount++;
            if (completedCount == info.numberOfPages ){
                [weakself.docDic setObject:@(NTESDocDownloadTypeCompleted) forKey:info.docId];
                if(weakself.delegate &&[weakself.delegate respondsToSelector:@selector(notifyDownloadState)])
                {
                    [weakself.delegate notifyDownloadState];
                }
            }
            else if (failedCount+completedCount == info.numberOfPages){
                [weakself.docDic setObject:@(NTESDocDownloadTypeFailed) forKey:info.docId];
                if(weakself.delegate &&[weakself.delegate respondsToSelector:@selector(notifyDownloadState)])
                {
                    [weakself.delegate notifyDownloadState];
                }
            }
        }
    }
}

-(void)downLoadDoc:(NIMDocTranscodingInfo*)info page:(int)page completeBlock:(DocDownLoadPageCompleteBlock)completeBlock
{
    id<NIMResourceManager> resManager = [[NIMSDK sharedSDK] resourceManager];
    NSString * filePathPrefix = [NTESDocumentHandler getFilePathPrefix:info.docId];
    NSString * url = [info transcodedUrl:page ofQuality:NIMDocTranscodingQualityHigh];
    NSString * filePath = [filePathPrefix stringByAppendingString:[NSString stringWithFormat:@"%@_%d.png",info.docName,page]];
    //取消所有下载任务
    for (NSString *path in _downloadTask) {
        [resManager cancelTask:path];
    }
    [_downloadTask removeAllObjects];
    [_downloadTask addObject:filePath];
    
    __weak typeof(self) weakself = self;
    
    [resManager  download:url
                 filepath:filePath
                 progress:nil
               completion:^(NSError *error) {
                   if (!error) {
                       [weakself.downloadTask removeObject:filePath];
                       completeBlock(nil);
                   }
                   else
                   {
                       completeBlock(error);
                   }
               }];
}

-(NTESDocDownloadType)downlaodCompelete:(NSString*)docId
{
    if ([_docDic objectForKey:docId]) {
        return [[_docDic objectForKey:docId]integerValue];
    }
    return NTESDocDownloadTypeNotFound;
}

@end
