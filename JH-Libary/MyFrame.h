//
//  MyFrame.h
//  JH_Wifi
//
//  Created by AivenLau on 16/8/4.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <UIKit/UIKit.h>

//#include "libavcodec/avcodec.h"
//#include "libavformat/avformat.h"
//#include "libswscale/swscale.h"
//#include "libavutil/pixfmt.h"
//#include "libavutil/imgutils.h"
//#include "libavutil/time.h"
//#include "libavutil/error.h"
#include "libavutil/frame.h"


@interface MyFrame : NSObject
{
@public     
    AVFrame *pFrame;
}
@end
