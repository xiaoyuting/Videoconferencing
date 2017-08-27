//
//  NTESWhiteboardLines.m
//  NIMEducationDemo
//
//  Created by fenric on 16/10/26.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESWhiteboardLines.h"

@interface NTESWhiteboardLines()

//所有人的白板线信息，key 是 uid
@property(nonatomic, strong) NSMutableDictionary *allLines;

@property(nonatomic, assign) BOOL hasUpdate;

@end

@implementation NTESWhiteboardLines

- (instancetype)init
{
    if (self = [super init]) {
        _allLines = [[NSMutableDictionary alloc] init];
        
    }
    return self;
}

- (NSDictionary *)allLines
{
    return _allLines;
}


- (void)addPoint:(NTESWhiteboardPoint *)point uid:(NSString *)uid
{
    if (!point || !uid) {
        return;
    }
    
    NSMutableArray *lines = [_allLines objectForKey:uid];
    
    if (!lines) {
        lines = [[NSMutableArray alloc] init];
        [_allLines setObject:lines forKey:uid];
    }
    
    if (point.type == NTESWhiteboardPointTypeStart) {
        [lines addObject:[NSMutableArray arrayWithObject:point]];
    }
    else if (lines.count == 0){
        [lines addObject:[NSMutableArray arrayWithObject:point]];
    }
    else {
        NSMutableArray *lastLine = [lines lastObject];
        [lastLine addObject:point];
    }
    
    _hasUpdate = YES;
}

- (void)cancelLastLine:(NSString *)uid
{
    NSMutableArray *lines = [_allLines objectForKey:uid];
    [lines removeLastObject];
    _hasUpdate = YES;
}

- (void)clear
{
    [_allLines removeAllObjects];
    _hasUpdate = YES;
}

- (void)clearUser:(NSString *)uid
{
    NSMutableArray *lines = [_allLines objectForKey:uid];
    [lines removeAllObjects];
    _hasUpdate = YES;
}

#pragma  mark - NTESWhiteboardDrawViewDataSource
- (NSDictionary *)allLinesToDraw
{
    _hasUpdate = NO;
    return _allLines;
}


- (BOOL)hasUpdate
{
    return _hasUpdate;
}

- (BOOL)hasLines
{
    BOOL has = NO;
    
    for (NSMutableArray *lines in _allLines.allValues) {
        if (lines.count > 0) {
            has = YES;
        }
    }
    return has;
}

@end
