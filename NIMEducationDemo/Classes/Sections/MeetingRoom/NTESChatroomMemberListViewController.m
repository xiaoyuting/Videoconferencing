//
//  NTESChatroomMemberListViewController.m
//  NIM
//
//  Created by chris on 15/12/17.
//  Copyright © 2015年 Netease. All rights reserved.
//

#import "NTESChatroomMemberListViewController.h"
#import "NTESChatroomMemberCell.h"
#import "UIScrollView+NTESPullToRefresh.h"
#import "UIView+Toast.h"
#import "UIView+NTES.h"
#import "NTESMeetingManager.h"
#import "NTESMeetingRolesManager.h"
#import "NTESTimerHolder.h"

@interface NTESChatroomMemberListViewController()<UITableViewDataSource,UITableViewDelegate,NIMChatManagerDelegate, NTESTimerHolderDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NIMChatroom *chatroom;

@property (nonatomic, assign) NSInteger limit; //分页条数

@property (nonatomic, strong) NSMutableArray<NIMChatroomMember *> *members;

@property (nonatomic, assign) BOOL canEditTableView;

@property (nonatomic, strong) NTESTimerHolder *fetchMembersTimer;

@property (nonatomic, assign) BOOL fetchMembersCooldown;

@end

@implementation NTESChatroomMemberListViewController

- (instancetype)initWithChatroom:(NIMChatroom *)chatroom{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _limit     = 100;
        _chatroom = chatroom;
        _members   = [[NSMutableArray alloc] init];
        _fetchMembersTimer = [[NTESTimerHolder alloc] init];
    }
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.view.backgroundColor = UIColorFromRGB(0xedf1f5);
    [self.view addSubview:self.tableView];
    [self prepareData];
    [[NIMSDK sharedSDK].chatManager addDelegate:self];
    [self.tableView registerClass:[NTESChatroomMemberCell class] forCellReuseIdentifier:self.cellReuseIdentifier];
    if ([_chatroom.creator isEqualToString:[[NIMSDK sharedSDK].loginManager currentAccount]]) {
        _canEditTableView = YES;
    }
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!_fetchMembersCooldown) {
        [self prepareData];
        _fetchMembersCooldown = YES;
        [_fetchMembersTimer startTimer:10 delegate:self repeats:NO];
    }
}

- (void)prepareData{
    __weak typeof(self) wself = self;
    [self requestTeamMembers:nil handler:^(NSError *error, NSArray *members) {
        if (!error)
        {
            [wself.members removeAllObjects];
            if (members.count == wself.limit)
            {
                [wself.tableView addPullToRefreshWithActionHandler:^{
                    [wself loadMoreData];
                } position:NTESPullToRefreshPositionBottom];
            }
            else
            {
                wself.tableView.tableFooterView = [[UIView alloc] init];
            }
            wself.members = [NSMutableArray arrayWithArray:members];
            [wself sortMember];
            [wself.tableView reloadData];
        }
        else
        {
            [wself.view makeToast:@"直播间成员获取失败"];
        }
    }];
}

- (void)refresh
{
    [self.tableView reloadData];
}

- (BOOL)hasMemberData:(NSString *)userId
{
    for (NIMChatroomMember *member in self.members) {
        if ([member.userId isEqualToString:userId]) {
            return YES;
        }
    }
    return NO;
}

- (void)updateMembers:(NSArray *)members entered:(BOOL)entered
{
    if (!entered) {
        return;
    }
    
    NSMutableArray *chatroomMembers = [[NSMutableArray alloc] init];

    for (NIMChatroomNotificationMember *memberNotification in members) {
        if ([self hasMemberData:memberNotification.userId]) {
            continue;
        }
        NIMChatroomMember *chatroomMember = [[NIMChatroomMember alloc] init];
        chatroomMember.userId = memberNotification.userId;
        chatroomMember.roomNickname = memberNotification.nick;
        chatroomMember.type = [chatroomMember.userId isEqualToString:self.chatroom.creator] ? NIMChatroomMemberTypeCreator : NIMChatroomMemberTypeNormal;
        [chatroomMembers addObject:chatroomMember];
    }
    
    if (chatroomMembers.count > 0) {
        [self.members addObjectsFromArray:chatroomMembers];
        [self refresh];
    }
}

- (void)loadMoreData{
    __weak typeof(self) wself = self;
    [self requestTeamMembers:self.members.lastObject handler:^(NSError *error, NSArray *members){
        [wself.tableView.pullToRefreshView stopAnimating];
        [wself.members addObjectsFromArray:members];
        [wself sortMember];
        [wself.tableView reloadData];
    }];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    NIMChatroomMember *member = self.members[indexPath.row];
    
    if (member.type == NIMChatroomMemberTypeCreator) {
        return NO;
    }
    else {
        return _canEditTableView;
    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"踢出";
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self kickMemberAtIndexPath:indexPath];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.members.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NTESChatroomMemberCell *cell = [tableView dequeueReusableCellWithIdentifier:self.cellReuseIdentifier];
    NIMChatroomMember *member = self.members[indexPath.row];
    [cell refresh:member];
    return cell;
}

#pragma mark - NTESTimerHolderDelegate
- (void)onNTESTimerFired:(NTESTimerHolder *)holder
{
    _fetchMembersCooldown = NO;
}

#pragma mark - Role
- (void)updateBlackListAtIndexPath:(NSIndexPath *)indexPath isBlack:(BOOL)isBlack
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberUpdateRequest *request = [[NIMChatroomMemberUpdateRequest alloc] init];
    request.roomId = self.chatroom.roomId;
    request.userId = member.userId;
    request.enable = isBlack;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager updateMemberBlack:request completion:^(NSError *error) {
        if (!error)
        {
            member.isInBlackList = isBlack;
            if (!isBlack) {
                //解除拉黑后默认变回游客身份
                member.type = NIMChatroomMemberTypeGuest;
            }
            [weakSelf.members replaceObjectAtIndex:indexPath.row withObject:member];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}


- (void)updateMuteListAtIndexPath:(NSIndexPath *)indexPath isMute:(BOOL)isMute
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberUpdateRequest *request = [[NIMChatroomMemberUpdateRequest alloc] init];
    request.roomId = self.chatroom.roomId;
    request.userId = member.userId;
    request.enable = isMute;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager updateMemberMute:request completion:^(NSError *error) {
        if (!error)
        {
            member.isMuted = isMute;
            if (!isMute) {
                //解除禁言后默认变回游客身份
                member.type = NIMChatroomMemberTypeGuest;
            }
            [weakSelf.members replaceObjectAtIndex:indexPath.row withObject:member];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)appointManagerAtIndexPath:(NSIndexPath *)indexPath isManager:(BOOL)isManager
{
    NIMChatroomMember *member = self.members[indexPath.row];
    NIMChatroomMemberUpdateRequest *request = [[NIMChatroomMemberUpdateRequest alloc] init];
    request.roomId = self.chatroom.roomId;
    request.userId = member.userId;
    request.enable = isManager;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager markMemberManager:request completion:^(NSError *error) {
        if (!error)
        {
            member.type = isManager ? NIMChatroomMemberTypeManager : NIMChatroomMemberTypeNormal;
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

- (void)kickMemberAtIndexPath:(NSIndexPath *)indexPath
{
    NIMChatroomMember *member = self.members[indexPath.row];
    
    NIMChatroomMemberKickRequest *request = [[NIMChatroomMemberKickRequest alloc] init];
    request.roomId = self.chatroom.roomId;
    request.userId = member.userId;
    __weak typeof(self) weakSelf = self;
    [[NIMSDK sharedSDK].chatroomManager kickMember:request completion:^(NSError *error) {
        if (!error)
        {
            NSUInteger idx = [weakSelf.members indexOfObject:member];
            if (idx != NSNotFound) {
                [[NTESMeetingRolesManager sharedInstance] kick:member.userId];
                [weakSelf.members removeObjectAtIndex:idx];
                [weakSelf.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:indexPath.section]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        else
        {
            NSString *toast = [NSString stringWithFormat:@"操作失败 code:%zd",error.code];
            [weakSelf.tableView makeToast:toast duration:2.0 position:CSToastPositionCenter];
        }
    }];
}

#pragma mark - Private 
- (void)requestTeamMembers:(NIMChatroomMember *)lastMember handler:(NIMChatroomMembersHandler)handler{
    NIMChatroomMemberRequest *request = [[NIMChatroomMemberRequest alloc] init];
    request.roomId = self.chatroom.roomId;
    request.lastMember = lastMember;
    request.type   = lastMember.type == NIMChatroomMemberTypeGuest ? NIMChatroomFetchMemberTypeTemp : NIMChatroomFetchMemberTypeRegularOnline;
    request.limit  = self.limit;
    __weak typeof(self) wself = self;
    [[NIMSDK sharedSDK].chatroomManager fetchChatroomMembers:request completion:^(NSError *error, NSArray *members) {
        if (!error)
        {
            if (members.count < wself.limit && request.type == NIMChatroomFetchMemberTypeRegularOnline) {
                //固定的没抓够，再抓点临时的充数
                NIMChatroomMemberRequest *req = [[NIMChatroomMemberRequest alloc] init];
                req.roomId = wself.chatroom.roomId;
                req.lastMember = nil;
                req.type   = NIMChatroomFetchMemberTypeTemp;
                req.limit  = wself.limit;
                [[NIMSDK sharedSDK].chatroomManager fetchChatroomMembers:req completion:^(NSError *error, NSArray *tempMembers) {
                    NSArray *result;
                    if (!error) {
                        result = [members arrayByAddingObjectsFromArray:tempMembers];
                        if (result.count > wself.limit) {
                            result = [result subarrayWithRange:NSMakeRange(0, wself.limit)];
                        }
                    }
                    handler(error,result);
                }];
            }
            else
            {
                handler(error,members);
            }
        }
        else
        {
            handler(error,members);
        }
    }];
}

- (void)sortMember
{
    NSDictionary<NSNumber *,NSNumber *> *values =
                             @{
                               @(NIMChatroomMemberTypeCreator) : @(1),
                               @(NIMChatroomMemberTypeManager) : @(2),
                               @(NIMChatroomMemberTypeNormal ) : @(3),
                               @(NIMChatroomMemberTypeLimit  ) : @(4),
                               @(NIMChatroomMemberTypeGuest  ) : @(5),
                              };
    [self.members sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NIMChatroomMember *member1  = obj1;
        NIMChatroomMember *member2  = obj2;
        NIMChatroomMemberType type1 = member1.type;
        NIMChatroomMemberType type2 = member2.type;
        
        //自己排在同级里面排第一
        if (type1 != NIMChatroomMemberTypeCreator && type1 == type2) {
            
            NSString *myUid = [[NIMSDK sharedSDK].loginManager currentAccount];

            if ([member1.userId isEqualToString:myUid]) {
                return NSOrderedAscending;
            }
            else if ([member2.userId isEqualToString:myUid]) {
                return NSOrderedDescending;
            }
        }
        
        return (values[@(type1)].integerValue < values[@(type2)].integerValue) ? NSOrderedAscending : NSOrderedDescending;
    }];
}

#pragma mark - Get
- (NSString *)cellReuseIdentifier{
    return @"cell";
}


- (UITableView *)tableView
{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height) style:UITableViewStylePlain];
        CGFloat contentInsetTop = 10.f;
        _tableView.contentInset = UIEdgeInsetsMake(contentInsetTop, 0, 0, 0);
        _tableView.backgroundColor  = [UIColor clearColor];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.dataSource = self;
        _tableView.delegate   = self;
        
    }
    return _tableView;
}

@end
