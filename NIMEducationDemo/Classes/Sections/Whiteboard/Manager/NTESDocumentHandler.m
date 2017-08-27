//
//  NTESDocumentHandler.m
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/14.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESDocumentHandler.h"
@interface NTESDocumentHandler ()

@property (nonatomic, weak) id<NTESDocumentHandlerDelegate> delegate;

@end

@implementation NTESDocumentHandler

- (instancetype)initWithDelegate:(id<NTESDocumentHandlerDelegate>)delegate
{
    if (self = [super init]) {
        _delegate = delegate;
        }
    return self;
}

- (void)fetchMyDocsInfo:(NSString*)lastDocId limit:(NSUInteger)limit
{
    __weak typeof(self) weakself = self;

    [[NIMSDK sharedSDK].docTranscodingManager fetchMyDocsInfo:lastDocId limit:limit completion:^(NSError * _Nullable error, NSArray<NIMDocTranscodingInfo *> * _Nullable infos) {
        if(!error)
        {
            if (weakself.delegate&&[weakself.delegate respondsToSelector:@selector(notifyGetDocsInfos:complete:)]) {
                [weakself.delegate notifyGetDocsInfos:infos complete:YES];
                if (!(infos.count < limit)) {
                    [weakself fetchMyDocsInfo:infos.lastObject.docId limit:limit];
                }
            }
        }
        else
        {
            if (weakself.delegate&&[weakself.delegate respondsToSelector:@selector(notifyGetDocsInfos:complete:)]) {
                [weakself.delegate notifyGetDocsInfos:nil complete:NO];
            }
        }
    }];
}

-(void)inquireDocInfo:(NSString*)docId 
{
    __weak typeof(self) weakself = self;

    [[NIMSDK sharedSDK].docTranscodingManager inquireDocInfo:docId completion:^(NSError * _Nullable error, NIMDocTranscodingInfo * _Nullable info) {
        if (!error) {
            if (weakself.delegate&&[weakself.delegate respondsToSelector:@selector(notifyGetDocInfo:)]) {
                [weakself.delegate notifyGetDocInfo:info];
            }
        }
    }];
}

-(void)deleteDoc:(NIMDocTranscodingInfo*)info
{
    __weak typeof(self) weakself = self;
        [[NIMSDK sharedSDK].docTranscodingManager deleteDoc:info.docId completion:^(NSError * _Nullable error) {
            if (!error) {
                if (weakself.delegate&&[weakself.delegate respondsToSelector:@selector(notifyDeleteDoc:complete:)]) {
                    // 删除本地文件
                    [weakself deleteFile:info.docId];
                    [weakself.delegate notifyDeleteDoc:info complete:YES];
                    
                }
            }
            else
            {
                if (weakself.delegate&&[weakself.delegate respondsToSelector:@selector(notifyDeleteDoc:complete:)]) {
                    [weakself.delegate notifyDeleteDoc:info complete:NO];
                }
            }
        }];
}

#pragma mark - fileManage

+(NSString *)getFilePathPrefix:(NSString*)docId
{
    static NSString *filePath = nil;
    
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        filePath= [[NSString alloc]initWithFormat:@"%@/%@/",[paths objectAtIndex:0],docId];
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:filePath
                                      withIntermediateDirectories:NO
                                                       attributes:nil
                                                            error:nil];
        }
    return filePath;
}

-(BOOL)deleteFile:(NSString*)docId
{
    static NSString *filePath = nil;

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    filePath= [[NSString alloc]initWithFormat:@"%@/%@/",[paths objectAtIndex:0],docId];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        return   [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    else
    {
        return YES;
    }
}


-(BOOL)checkDocInLocal:(NIMDocTranscodingInfo*)info
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = [[NSString alloc]initWithFormat:@"%@/%@/",[paths objectAtIndex:0],info.docId];
    NSString * filePath = [path stringByAppendingString:[NSString stringWithFormat:@"%@_%lu.png",info.docName,(unsigned long)info.numberOfPages]];

    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];

}

@end
