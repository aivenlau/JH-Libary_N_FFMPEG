//
//  MyDownLoad.h
//  JH_WifiCamera
//
//  Created by AivenLau on 2016/12/7.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MySocket.h"
//#import "GCDAsyncSocket.h"

#define   GK_ServerIP @"175.16.10.2"
#define   GK_Port       0x7102

#define  Tag_DownLoadSocket  1
#define  Tag_DownLoadHead   2
#define  Tag_DownLoadData   3



typedef void (^Progress)(NSInteger precent);
typedef void (^Sucess)(NSString *tempfile);
typedef void (^Fail)(void);




@interface MyDownLoad_a : NSObject

@property(assign,nonatomic) int session_id;
@property(assign,nonatomic) int64_t file_all_size;
@property(assign,nonatomic) UInt64 nSize;


@property(strong,nonatomic)   NSString *VideosFloder;
@property(strong,nonatomic)   NSString *PhotosFloder;



-(void)disconnect;
-(void)F_DownLoad:(NSString *)sPath   Sucess:(Sucess)sucess  Progress:(Progress)Progress  Fail:(Fail)Fail;

@end
