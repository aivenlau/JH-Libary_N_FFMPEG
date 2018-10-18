//
//  MyCmdData.h
//  SyMaDemo
//
//  Created by AivenLau on 2017/11/25.
//  Copyright © 2017年 AivenLau. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyCmdData : NSObject
{
    
}


@property(assign,nonatomic)  int32_t  udpInx;
//@property(strong,nonatomic)  NSData  *data;
@property(strong,nonatomic)  NSMutableData *data;
-(id)initWithdata:(int32_t)ix Data:(NSData *)data;
@end
