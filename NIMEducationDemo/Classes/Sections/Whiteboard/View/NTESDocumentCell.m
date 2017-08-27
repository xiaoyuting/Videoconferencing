//
//  NTESDocumentCell.m
//  NIMEducationDemo
//
//  Created by Simon Blue on 16/12/13.
//  Copyright © 2016年 Netease. All rights reserved.
//

#import "NTESDocumentCell.h"
#import "UIView+NTES.h"
#import "NTESDataManager.h"
#import "NIMAvatarImageView.h"
#import "UIImageView+WebCache.h"
#import "UIAlertView+NTESBlock.h"
#import "NTESDocDownloadManager.h"


@interface NTESDocumentCell ()

@property (nonatomic,strong) UIView  *content;
@property (nonatomic,strong) UIImageView  *imgView;
@property (nonatomic,strong) UIButton  *downLoadBtn;
@property (nonatomic,strong) UIButton  *deleteBtn;
@property (nonatomic,strong) UIView  *seperatorLine;
@property (nonatomic,strong) UILabel  *title;
@property (nonatomic,strong) NIMDocTranscodingInfo *docInfo;


@end

@implementation NTESDocumentCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self addSubview:self.content];
        [self.content addSubview:self.imgView];
        [self.content addSubview:self.title];
        [self.content addSubview:self.seperatorLine];
        [self.content addSubview:self.deleteBtn];
        [self.content addSubview:self.downLoadBtn];

    }
    return self;
}

-(UIView*)content{
    if (!_content) {
        _content = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width-2*7.5, 117)];
        _content.backgroundColor = [UIColor whiteColor];
        _content.layer.cornerRadius = 3.5;
        _content.layer.masksToBounds = YES;
    }
    return _content;
}

-(UIImageView*)imgView{
    if (!_imgView) {
        _imgView = [[UIImageView alloc]initWithFrame:CGRectZero];
        _imgView.layer.borderColor = UIColorFromRGB(0xCCCCCC).CGColor;
        _imgView.layer.borderWidth = 0.5;
    }
    return _imgView;
}

-(UILabel*)title
{
    if (!_title) {
        _title = [[UILabel alloc]initWithFrame:CGRectZero];
        _title.text = @"";
    }
    return _title;
}

-(UIView*)seperatorLine
{
    if (!_seperatorLine) {
        _seperatorLine = [[UIView alloc]initWithFrame:CGRectZero];
        _seperatorLine.backgroundColor = UIColorFromRGB(0xCCCCCC);
    }
    return _seperatorLine;
}

-(UIButton*)downLoadBtn
{
    if (!_downLoadBtn) {
        _downLoadBtn = [[UIButton alloc]initWithFrame:CGRectZero];
        [_downLoadBtn setTitle:@"下载使用" forState:UIControlStateNormal];
        _downLoadBtn.titleLabel.font= [UIFont systemFontOfSize:15];
        [_downLoadBtn setBackgroundImage:[UIImage imageNamed :@"btn_document_interaction" ]forState:UIControlStateNormal];
        [_downLoadBtn addTarget:self action:@selector(onPressDownLoad:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _downLoadBtn;
}

-(UIButton*)deleteBtn
{
    if (!_deleteBtn) {
        _deleteBtn = [[UIButton alloc]initWithFrame:CGRectZero];
        [_deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
        _deleteBtn.titleLabel.font= [UIFont systemFontOfSize:15];
        [_deleteBtn setBackgroundImage:[UIImage imageNamed :@"btn_document_interaction" ]forState:UIControlStateNormal];
        [_deleteBtn addTarget:self action:@selector(onPressDelete:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deleteBtn;
}

-(void)layoutSubviews
{
    self.content.width = self.frame.size.width-2*15;
    self.content.height = 117;
    self.content.left = 15;
    self.content.top = 7.5;
    
    self.imgView.width = 45;
    self.imgView.height =45;
    self.imgView.left = 15;
    self.imgView.top = 10;
    
    self.title.width = self.content.width-self.imgView.right-15;
    self.title.height = 45;
    self.title.left = self.imgView.right+15;
    self.title.top = self.imgView.top;
    
    self.seperatorLine.width = self.content.width -15*2;
    self.seperatorLine.height = 0.5;
    self.seperatorLine.left = 15;
    self.seperatorLine.top = self.imgView.bottom+10;
    
    CGRect deleteBtnRect = [self.deleteBtn.titleLabel.text boundingRectWithSize:CGSizeMake(999, 30)
                                                                            options:NSStringDrawingUsesLineFragmentOrigin
                                                                         attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                                                            context:nil];
    self.deleteBtn.width = deleteBtnRect.size.width+24;
    self.deleteBtn.height = 30;
    self.deleteBtn.right = self.content.width-10;
    self.deleteBtn.top = self.seperatorLine.bottom+10;
    
    CGRect downloadBtnRect = [self.downLoadBtn.titleLabel.text boundingRectWithSize:CGSizeMake(999, 30)
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:15]}
                                                   context:nil];
    self.downLoadBtn.width = downloadBtnRect.size.width+24;
    self.downLoadBtn.height = 30;
    self.downLoadBtn.right = self.deleteBtn.left-10;
    self.downLoadBtn.top = self.deleteBtn.top;
}

#pragma mark - btn

-(void)onPressDelete:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"确定删除这个文件吗？" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
    [alert showAlertWithCompletionHandler:^(NSInteger index) {
        switch (index) {
            case 1:{
                if(self.delegate && [self.delegate respondsToSelector:@selector(onPressedDeleteDoc:)])
                {
                    [self.delegate onPressedDeleteDoc:self.docInfo];
                }
                break;
            }
                
            default:
                break;
        }
    }];
}

-(void)onPressDownLoad:(id)sender
{
    if ([self.downLoadBtn.titleLabel.text isEqualToString:@"使用"]) {
        if(self.delegate&&[self.delegate respondsToSelector:@selector(onPressedUseDoc:)])
        {
            [self.delegate onPressedUseDoc:self.docInfo];
        }
    }

    else {
        [self.downLoadBtn setTitle:@"下载中..." forState:UIControlStateNormal];
        self.downLoadBtn.enabled = NO;
        [self setNeedsLayout];
        //下载
        if(self.delegate&&[self.delegate respondsToSelector:@selector(onPressedDownloadDoc:)])
        {
            [self.delegate onPressedDownloadDoc:self.docInfo];
        }
    }
}

-(void)refresh:(NIMDocTranscodingInfo*)info;
{
    self.docInfo = info;
    self.title.text = info.docName;
    [self.imgView sd_setImageWithURL:[NSURL URLWithString:[info transcodedUrl:1 ofQuality:NIMDocTranscodingQualityMedium]] placeholderImage:[UIImage imageNamed: @"btn_document_placeholderImage"]];
    [self getDownloadInfo:info];
}

-(void)getDownloadInfo:(NIMDocTranscodingInfo*)info;
{
   NTESDocDownloadType type = [[NTESDocDownloadManager sharedManager] downlaodCompelete:info.docId];
    
    switch (type) {
        case NTESDocDownloadTypeCompleted:
            [self.downLoadBtn setTitle:@"使用" forState:UIControlStateNormal];
            self.downLoadBtn.enabled = YES;
            break;
            
        case NTESDocDownloadTypeFailed:
            [self.downLoadBtn setTitle:@"重试" forState:UIControlStateNormal];
            self.downLoadBtn.enabled = YES;
            break;

        case NTESDocDownloadTypeNotCompleted:
            [self.downLoadBtn setTitle:@"下载中..." forState:UIControlStateNormal];
            self.downLoadBtn.enabled = NO;
            break;

        case NTESDocDownloadTypeNotFound:
            if (self.delegate&&[self.delegate respondsToSelector:@selector(checkDocInLocal:)]) {
                if([self.delegate checkDocInLocal:info])
                {
                    [self.downLoadBtn setTitle:@"使用" forState:UIControlStateNormal];
                    self.downLoadBtn.enabled = YES;
                }
                else
                {
                    [self.downLoadBtn setTitle:@"下载使用" forState:UIControlStateNormal];
                    self.downLoadBtn.enabled = YES;
                }
            }
            break;

        default:
            break;
    }
}
@end
