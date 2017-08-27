//
//  NTESDocumentHandler.h
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/14.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NTESDocumentCell.h"

@protocol NTESDocumentHandlerDelegate <NSObject>

@optional
-(void)notifyGetDocsInfos:(NSArray*)docInfos complete:(BOOL)success;
-(void)notifyGetDocInfo:(NIMDocTranscodingInfo*)docInfo ;
-(void)notifyDeleteDoc:(NIMDocTranscodingInfo*)docInfo complete:(BOOL)success;

@end

@interface NTESDocumentHandler : NSObject

- (instancetype)initWithDelegate:(id<NTESDocumentHandlerDelegate>)delegate;
- (void)fetchMyDocsInfo:(NSString*)lastDocId limit:(NSUInteger)limit;
- (void)inquireDocInfo:(NSString*)docId;
- (void)deleteDoc:(NIMDocTranscodingInfo*)info;

- (BOOL)checkDocInLocal:(NIMDocTranscodingInfo*)info;

+(NSString *)getFilePathPrefix:(NSString*)docId;

@end
