//
//  BGWLViewController.h
//  BGWechatLogin
//
//  Created by Libinggen on 14-9-23.
//  Copyright (c) 2014年 Libinggen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ShareSDK/ShareSDK.h>

@interface BGWLViewController : UIViewController<UITableViewDataSource,
UITableViewDelegate>
{
@private
    NSMutableDictionary *_infoDict;
    ShareType _type;
    SSUserFieldType _paramType;
    NSInteger _flag;
    NSString *_name;
    BOOL _initialized;
    
    UITableView *_tableView;
}

- (IBAction)clickButtonLogin:(id)sender;

@end
