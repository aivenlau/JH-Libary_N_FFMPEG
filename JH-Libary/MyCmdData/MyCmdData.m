//
//  MyCmdData.m
//  SyMaDemo
//
//  Created by AivenLau on 2017/11/25.
//  Copyright © 2017年 AivenLau. All rights reserved.
//

#import "MyCmdData.h"

@implementation MyCmdData

-(id)init
{
    self = [super init];
    if(self)
    {
        _udpInx=-1;
        _data = [[NSMutableData alloc] init];
    }
    return self;
}
-(id)initWithdata:(int32_t)ix Data:(NSData *)data
{
    self = [super init];
    if(self)
    {
        _udpInx = ix;
        Byte *buff = (Byte *)[data bytes];
        _data = [[NSMutableData alloc] initWithBytes:buff+4 length:data.length-4];
    }
    return self;
}

@end
