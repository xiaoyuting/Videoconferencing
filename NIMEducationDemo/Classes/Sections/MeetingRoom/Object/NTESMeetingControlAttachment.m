//
//  NTESMeetingControlAttachment.m
//  NIM
//
//  Created by amao on 7/2/15.
//  Copyright (c) 2015 Netease. All rights reserved.
//

#import "NTESMeetingControlAttachment.h"

@implementation NTESMeetingControlAttachment

- (NSString *)encodeAttachment
{
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    [dict setObject:@(CustomMessageTypeMeetingControl) forKey:CMType];
    [data setObject:_roomID?_roomID:@"" forKey:CMRoomID];
    [data setObject:@(_command) forKey:CMCommand];
    if (_uids.count) {
        [data setObject:_uids forKey:CMUIDs];
    }
    [dict setObject:data forKey:CMData];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:0
                                                         error:nil];
    
    return [[NSString alloc] initWithData:jsonData
                                 encoding:NSUTF8StringEncoding];
}

-(NSString *)description {
    return [NSString stringWithFormat:@"room: %@, command:%zd, uids:%@", _roomID, _command, _uids];
}

@end
