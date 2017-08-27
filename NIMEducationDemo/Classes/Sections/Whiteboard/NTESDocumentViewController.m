//
//  NTESDocumentViewController.m
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/13.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESDocumentViewController.h"
#import "SDWebImageManager.h"
#import "UIView+Toast.h"
#import "NTESDocDownloadManager.h"

@interface NTESDocumentViewController ()<NTESDocDownloadManagerDelegate>

@property (nonatomic,strong)UITableView *tableView;
@property (nonatomic,strong)NTESDocumentHandler *handler;
@property (nonatomic,strong)NSMutableArray<NIMDocTranscodingInfo*> *docInfos;
@end

#define cellReuseIdentifier @"documentCell"
@implementation NTESDocumentViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"文档库";
    self.navigationController.navigationBarHidden = NO;
    self.view.backgroundColor = UIColorFromRGB(0xedf1f5);
    [self.view addSubview:self.tableView];
    self.docInfos = [NSMutableArray array];
    
    _handler = [[NTESDocumentHandler alloc]initWithDelegate:self];
    [_handler fetchMyDocsInfo:nil limit:30];
    
    [[NTESDocDownloadManager sharedManager]addDelegate:self];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(UITableView*)tableView
{
    if (!self.isViewLoaded) {
        return nil;
    }
    if (!_tableView) {
        _tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        [_tableView registerClass:[NTESDocumentCell class] forCellReuseIdentifier:cellReuseIdentifier];
        _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor  = [UIColor clearColor];

    }
    return _tableView;
}

#pragma mark - tableView delegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 132.f;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 7.5;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 30;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView * view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];

    UILabel * label = [[UILabel alloc]initWithFrame:CGRectMake(0, 2.5, self.view.frame.size.width, 12)];
    [label setText:@"可在教育DEMO的PC端上传文档，在移动端下载使用"];
    label.font = [UIFont systemFontOfSize:10];
    label.textColor = UIColorFromRGB(0x999999);
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    [view addSubview:label];
    
    return view;
}

#pragma mark - tableView dataSource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.docInfos.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NTESDocumentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    cell.delegate = self;
    NIMDocTranscodingInfo *info = self.docInfos[indexPath.row];
    [cell refresh:info];
    return cell;
}

#pragma mark - NTESDocumentHandlerDelegate

-(void)notifyGetDocsInfos:(NSArray*)docInfos complete:(BOOL)success
{
    if (success) {
        for (NIMDocTranscodingInfo *info in docInfos) {
            if (info.state == NIMDocTranscodingStateCompleted) {
                [self.docInfos addObject:info];
            }
        }
        [self.tableView reloadData];
    }
    else
    {
        [self.view makeToast:@"获取列表失败" duration:1 position:CSToastPositionCenter];
    }
}

-(void)notifyDeleteDoc:(NIMDocTranscodingInfo *)docInfo complete:(BOOL)success
{
    if (success) {
        [self.docInfos removeObject:docInfo];
        [self.tableView reloadData];
    }
    else
    {
        [self.view makeToast:@"删除失败" duration:1 position:CSToastPositionCenter];
    }
}
#pragma mark - NTESDocDownloadManagerDelegate

-(void)notifyDownloadState
{
    [self.tableView reloadData];
}

#pragma mark - NTESDocumentCellDelegate

-(void)onPressedUseDoc:(NIMDocTranscodingInfo *)info
{
    //跳转白板页面 显示doc
    if(self.delegate && [self.delegate respondsToSelector:@selector(showDocOnWhiteboard:)])
    {
        [self.delegate showDocOnWhiteboard:info];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)onPressedDownloadDoc:(NIMDocTranscodingInfo *)info
{
    [[NTESDocDownloadManager sharedManager]downLoadDoc:info];
}

-(void)onPressedDeleteDoc:(NIMDocTranscodingInfo *)info
{
    [_handler deleteDoc:info];
}

-(BOOL)checkDocInLocal:(NIMDocTranscodingInfo*)info;
{
    return [_handler checkDocInLocal:info];
}



@end
