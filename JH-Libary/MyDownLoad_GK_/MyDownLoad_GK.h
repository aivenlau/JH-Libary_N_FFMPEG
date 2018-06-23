//
//  MyDownLoad_GK.h
//  Wifi_Camera
//
//  Created by AivenLau on 16/5/23.
//  Copyright © 2016年 KLStudio. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^Progress)(NSInteger precent);
typedef void (^Sucess)(NSString *tempfile);
typedef void (^Fail)(void);


@interface MyDownLoad_GK : NSObject<NSURLSessionDownloadDelegate>
//- (void)downloadFile:(NSString *)urlStr ByIndex:(NSInteger)inx;

-(void)F_DownLoad:(NSString *)sPath   Sucess:(Sucess)sucess_  Progress:(Progress)Progress_  Fail:(Fail)Fail_;
-(void)Cancel;


@end
