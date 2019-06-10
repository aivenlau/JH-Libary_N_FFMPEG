//
//  JPEG_BUFFER.m
//  JH_Libary
//
//  Created by AivenLau on 2017/9/11.
//  Copyright © 2017年 AivenLau. All rights reserved.
//

#import "JPEG_BUFFER.h"

@implementation JPEG_BUFFER
{
    
}
-(id)init
{
    self = [super init];
    if(self)
    {
        _buffer = malloc(500*1024);
        _nCount = 0;;
        _nJpegInx = 0;
        memset(mInx, 0, 250);
    }
    return self;
}

-(void)Clear
{
    _nCount = 0;;
    _nJpegInx = 0;
    memset(mInx, 0, 250);
    
}
-(void)Release
{
        if(_buffer!=NULL)
        {
            free(_buffer);
            _buffer = NULL;
        }
        _nCount = 0;;
        _nJpegInx = 0;
        memset(mInx, 0, 250);
}

-(BOOL)AppendData:(uint8_t *)data Length:(int)nLen
{
     if(_nCount+nLen>500*1024)
     {
         [self Clear];
         return NO;
     }
    memcpy(_buffer+_nCount,data,nLen);
    _nCount+=nLen;
    return YES;
}


@end
