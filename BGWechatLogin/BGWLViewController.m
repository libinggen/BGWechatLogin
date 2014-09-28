//
//  BGWLViewController.m
//  BGWechatLogin
//
//  Created by Libinggen on 14-9-23.
//  Copyright (c) 2014年 Libinggen. All rights reserved.
//

#import "BGWLViewController.h"
#import "AGUserInfoViewController.h"

#import <AGCommon/UINavigationBar+Common.h>
#import <AGCommon/UIColor+Common.h>
#import <AGCommon/UIImage+Common.h>
#import <AGCommon/UIDevice+Common.h>
#import <AGCommon/NSString+Common.h>

#define TABLE_CELL_ID @"tableCell"

@interface BGWLViewController (Private)
- (void)loadImage:(NSString *)url;

- (void)showUserIcon:(UIImage *)icon;
/**
 *	@brief	填充微信用户信息
 *
 *	@param 	userInfo 	用户信息
 */
- (void)fillWeixinUser:(id<ISSPlatformUser>)userInfo;

@end

@implementation BGWLViewController


- (void)loadImage:(NSString *)url
{
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    [self performSelectorOnMainThread:@selector(showUserIcon:) withObject:image waitUntilDone:NO];
    
}

- (void)showUserIcon:(UIImage *)icon
{
    if (icon)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:icon];
        imageView.frame = CGRectMake(0.0, 0.0, _tableView.width, imageView.height * _tableView.width / imageView.width);
        _tableView.tableHeaderView = imageView;
    }
}

- (void)fillWeixinUser:(id<ISSPlatformUser>)userInfo
{
    NSArray *keys = [[userInfo sourceData] allKeys];
    for (int i = 0; i < [keys count]; i++)
    {
        NSString *keyName = [keys objectAtIndex:i];
        id value = [[userInfo sourceData] objectForKey:keyName];
        if (![value isKindOfClass:[NSString class]])
        {
            if ([value respondsToSelector:@selector(stringValue)])
            {
                value = [value stringValue];
            }
            else
            {
                value = @"";
            }
        }
        
        [_infoDict setObject:value forKey:keyName];
    }
}

-(void)loadUserInfoView
{
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 60.0, self.view.width, self.view.height - 60) style:UITableViewStyleGrouped];
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _tableView.backgroundColor = [UIColor colorWithRGB:0xe1e0de];
    _tableView.backgroundView = nil;
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    
    if (![ShareSDK getCredentialWithType:ShareTypeWeixiSession])
    {
        _tableView.hidden = YES;
    }
    
    [self.view bringSubviewToFront:_tableView];
    
    ShareType type = ShareTypeWeixiSession;
    _type = type;
    
    //设置授权选项
    id<ISSAuthOptions> authOptions = [ShareSDK authOptionsWithAutoAuth:YES
                                                         allowCallback:YES
                                                         authViewStyle:SSAuthViewStyleFullScreenPopup
                                                          viewDelegate:nil
                                               authManagerViewDelegate:nil];
    
    //在授权页面中添加关注官方微博
    [authOptions setFollowAccounts:[NSDictionary dictionaryWithObjectsAndKeys:
                                    [ShareSDK userFieldWithType:SSUserFieldTypeName value:@"ShareSDK"],
                                    SHARE_TYPE_NUMBER(ShareTypeSinaWeibo),
                                    [ShareSDK userFieldWithType:SSUserFieldTypeName value:@"ShareSDK"],
                                    SHARE_TYPE_NUMBER(ShareTypeTencentWeibo),
                                    nil]];
    
    [ShareSDK getUserInfoWithType:_type
                      authOptions:authOptions
                           result:^(BOOL result, id<ISSPlatformUser> userInfo, id<ICMErrorInfo> error) {
                               
                               if (result)
                               {
                                   [_infoDict removeAllObjects];
                                   
                                   if ([userInfo profileImage])
                                   {
                                       [NSThread detachNewThreadSelector:@selector(loadImage:)
                                                                toTarget:self
                                                              withObject:[userInfo profileImage]];
                                   }
                                   
                                   switch (_type)
                                   {
                                       case ShareTypeWeixiSession:
                                           //微信
                                           [self fillWeixinUser:userInfo];
                                           break;
                                       default:
                                           break;
                                   }
                                   
                                   [_tableView reloadData];
                                   _tableView.hidden = NO;
                                   
                                   _initialized = YES;
                               }
                               else
                               {
                                   UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"TEXT_TIPS", @"提示")
                                                                                       message:error.errorDescription
                                                                                      delegate:nil
                                                                             cancelButtonTitle:NSLocalizedString(@"TEXT_KNOW", @"知道了")
                                                                             otherButtonTitles: nil];
                                   [alertView show];
                                   [self dismissViewControllerAnimated:YES completion:nil];
                               }
                           }];

    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _infoDict = [[NSMutableDictionary alloc] init];
    
    if ([ShareSDK getCredentialWithType:ShareTypeWeixiSession]) {
        
        [self loadUserInfoView];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//授权登录按钮点击处理方法
- (IBAction)clickButtonLogin:(id)sender {
    [self loadUserInfoView];
    }

- (void)cancelAuthButtonClickHandler:(id)sender
{
    [ShareSDK cancelAuthWithType:ShareTypeWeixiSession];
    
    [_tableView removeFromSuperview];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[_infoDict allKeys] count] == 0) {
        return 0;
    }
    return [[_infoDict allKeys] count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TABLE_CELL_ID];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:TABLE_CELL_ID];
    }
    if (indexPath.row < [[_infoDict allKeys] count])
    {
        NSString *keyName = [[_infoDict allKeys] objectAtIndex:indexPath.row];
        cell.textLabel.text = keyName;
        cell.detailTextLabel.text = [_infoDict objectForKey:keyName];
    }
    if (indexPath.row == [[_infoDict allKeys] count]) {
        UIButton *cancelAuthButton = [[UIButton alloc] init];
        [cancelAuthButton setBackgroundImage:[UIImage imageNamed:@"Common/NavigationButtonBG.png" bundleName:BUNDLE_NAME]
                                    forState:UIControlStateNormal];
        [cancelAuthButton setTitle:@"注销"/*NSLocalizedString(@"TEXT_CANCEL", @"注销")*/ forState:UIControlStateNormal];
        [cancelAuthButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        cancelAuthButton.titleLabel.font = [UIFont systemFontOfSize:14];
        cancelAuthButton.frame = CGRectMake(cell.width/2 - 100/2, 5.0, 100.0, 30.0);
        [cancelAuthButton addTarget:self action:@selector(cancelAuthButtonClickHandler:) forControlEvents:UIControlEventTouchUpInside];
        [cell addSubview:cancelAuthButton];
    }
    
    return cell;
}
@end
