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
        _buffer = malloc(100*1024);
        _nCount = 0;;
        _nJpegInx = 0;
        memset(mInx, 0, 50);
    }
    return self;
}

-(void)Clear
{
    _nCount = 0;;
    _nJpegInx = 0;
    memset(mInx, 0, 50);
    
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
        memset(mInx, 0, 50);
}


@end
