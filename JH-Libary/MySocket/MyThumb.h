//
//  MyThumb.h
//  JH_Libary
//
//  Created by AivenLau on 2017/4/14.
//  Copyright © 2017年 AivenLau. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MySocket.h"
//#import "GCDAsyncSocket.h"

#define   GK_ServerIP @"175.16.10.2"

typedef void (^Thumb_Sucess)(UIImage *img,NSString *sFilename);

@interface MyThumb : NSObject
{
    
}

@property(assign,nonatomic) int session_id;
@property(assign,nonatomic) BOOL   bCancel;


-(int)download:(NSString *)filename  Sucess:(Thumb_Sucess)sucess;
@end
