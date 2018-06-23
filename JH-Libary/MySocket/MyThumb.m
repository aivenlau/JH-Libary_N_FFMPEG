//
//  MyThumb.m
//  JH_Libary
//
//  Created by AivenLau on 2017/4/14.
//  Copyright © 2017年 AivenLau. All rights reserved.
//

#import "MyThumb.h"
#import "phone_rl_protocol.h"


#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/pixfmt.h"
#include "libavutil/imgutils.h"
#include "libavutil/time.h"
#include "libavutil/error.h"
#include "libavutil/frame.h"


@interface MyThumb()
{
    
}


//@property(strong,nonatomic) NSMutableArray   *socketArray;
@property(copy,nonatomic) Thumb_Sucess  Sucess;
@property(strong,nonatomic)MySocket *serchSocket;
@end


@implementation MyThumb

-(id)init
{
    self = [super init];
    if(self)
    {
        
        //_socketArray = [[NSMutableArray alloc] init];
        //dispatch_queue_t myQueue = dispatch_queue_create("JOYHONEST-WIFI-Download", DISPATCH_QUEUE_PRIORITY_DEFAULT);
        _session_id = -1;
        _bCancel = NO;
    }
    return self;
}

-(int)download_GP:(NSString *)filename  Sucess:(Thumb_Sucess)sucess
{
    self.Sucess = sucess;
    __weak  MyThumb  *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        int nInx = [filename intValue];
        [weakself F_GP_GetThumbnailA:nInx];
    });
    
    return 0;
}

-(void)F_GP_GetThumbnailA:(int)fileInx
{
    _serchSocket = [[MySocket alloc] init];
    
    
    Byte *dat=NULL;
    int nLen=0;
    Byte cmd[20];
    cmd[0] = 'G';
    cmd[1] = 'P';
    cmd[2] = 'S';
    cmd[3] = 'O';
    cmd[4] = 'C';
    cmd[5] = 'K';
    cmd[6] = 'E';
    cmd[7] = 'T';
    
    cmd[8] = 0x00;
    cmd[9] = 0x01;
    
    cmd[10] = 0x03;
    cmd[11] = 0x04;    //GetThumbnail
    
    
    cmd[12] = fileInx;
    cmd[13] = fileInx>>8;
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:14];
    if(!self.serchSocket.bConnected)
    {
        if([_serchSocket Connect:@"192.168.25.1" PORT:8081]<0)
        {
            self.Sucess(nil,nil);
            return;
        }
    }
    [_serchSocket Write:data];
    usleep(10000);
    BOOL  bRe=YES;
    NSData *data_rev;
    NSMutableData  *revData = [[NSMutableData alloc] init];
    while(bRe)
    {
        data_rev = [_serchSocket Read:14 timeout:200];
        if(data_rev)
        {
            if(data_rev.length==14)
            {
                dat = (Byte *)[data_rev bytes];
                if(dat[10]== 0x03 && dat[11]== 0x04)
                {
                    nLen = dat[13]*0x100+dat[12];
                    data_rev=nil;
                    if(nLen>0)
                    {
                        data_rev = [_serchSocket Read:nLen timeout:150];
                        if(data_rev)
                        {
                            [revData appendData:data_rev];
                        }
                        if(nLen<242)
                        {
                            bRe = NO;
                        }
                    }
                }
            }
        }
        else
        {
            //nLen = (int)revData.length;
            //[revData resetBytesInRange:NSMakeRange(0, revData.length)];
            //[revData setLength:0];
            bRe = NO;
        }
    }
    nLen = (int)revData.length;
    [_serchSocket Read:10*1024 timeout:100];
    if(nLen==0)
    {
        self.Sucess(nil,nil);
        [_serchSocket DisConnect];
        return ;
    }
    UIImage *img = [UIImage imageWithData:revData];
    self.Sucess(img,nil);
    [_serchSocket DisConnect];
}



-(int)download:(NSString *)filename  Sucess:(Thumb_Sucess)sucess
{
    self.Sucess = sucess;
    __weak  MyThumb  *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [weakself F_GetThumb:filename];
    });
    return 0;
}

-(void)setBCancel:(BOOL)bCancel
{
    _bCancel = bCancel;
    if(_bCancel)
    {
        if(_serchSocket)
        {
            [_serchSocket DisConnect];
        }
    }
}

-(void)F_GetThumb:(NSString *)filename
{
    NSData *retDat;
    T_REQ_MSG msg;
    if(_serchSocket==nil)
        _serchSocket = [[MySocket alloc] init];
    if([_serchSocket Connect:GK_ServerIP PORT:0x7102]<0)
    {
        _Sucess(nil,filename);
        return ;
    }
    
    
    
    
    
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG  config;
    
    
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_SEARCH_SOCK;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    [_serchSocket Write:sendData];
    
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_GET_CONFIG;
    config.type =CONFIG_SD_GET_REC_THUMB;
    config.res = 0;
    sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    [sendData appendData:data];
    [_serchSocket Write:sendData];
    usleep(2000);
    
    T_NET_SD_REC_THUMB_LIST  thumb;
    const char *buffer = filename.UTF8String;
    memset(thumb.file_name, 0, 40);
    memcpy(thumb.file_name,buffer,39);
    
    
    thumb.send_buf=0;
    thumb.thumb_size = 0;
    sendData =  [NSMutableData dataWithBytes:&thumb length:sizeof(T_NET_SD_REC_THUMB_LIST)];
    [_serchSocket Write:sendData];
    
    int nLen = sizeof(T_REQ_MSG);
    retDat = [_serchSocket Read:nLen timeout:2100];
    if(retDat.length==nLen)
    {
        [retDat getBytes:&msg length:sizeof(T_REQ_MSG)];
        if(msg.ret == 0)
        {
            if(_bCancel)
            {
                NSLog(@"Cancel Down thmb");
                [_serchSocket DisConnect];
               // [_socketArray removeObject:_serchSocket];
                return;
            }
            memset(thumb.file_name, 0, 40);
            thumb.send_buf=0;
            thumb.thumb_size = 0;
            nLen = sizeof(T_NET_SD_REC_THUMB_LIST);
            retDat = [_serchSocket Read:nLen timeout:2000];
            
            if(retDat.length==nLen)
            {
                if(_bCancel)
                {
                    NSLog(@"Cancel Down thmb");
                    [_serchSocket DisConnect];
                   // [_socketArray removeObject:_serchSocket];
                    return;
                }
                
                [retDat getBytes:&thumb length:sizeof(T_NET_SD_REC_THUMB_LIST)];
                nLen =thumb.thumb_size;
                retDat = [_serchSocket Read:nLen timeout:5000];
                if(_bCancel)
                {
                    NSLog(@"Cancel Down thmb");
                    [_serchSocket DisConnect];
                 //   [_socketArray removeObject:_serchSocket];
                    return;
                }
                [_serchSocket DisConnect];
               // [_socketArray removeObject:_serchSocket];
                if(retDat.length == nLen && retDat.length>0)
                {
                    
                    UIImage  *img=nil;
                    AVPacket packet_abc;
                    av_new_packet(&packet_abc, nLen);
                    memcpy(packet_abc.data, [retDat bytes], nLen);
                    AVFrame  *m_decodedFrame_abc = av_frame_alloc();
                    AVCodec *codec_abc = avcodec_find_decoder(AV_CODEC_ID_H264);
                    AVCodecContext  	*m_codecCtx_abc = avcodec_alloc_context3(codec_abc);
                    m_codecCtx_abc->codec_id = AV_CODEC_ID_H264;
                    struct SwsContext *img_convert_ctxBmp_abc;
                    AVFrame             *pFrameRGB_abc;
                    
                    int ret = avcodec_open2(m_codecCtx_abc, codec_abc, NULL);
                    
                    if(ret==0)
                    {
                        /*
                        int frameFinished;
                        ret = avcodec_decode_video2(m_codecCtx_abc, m_decodedFrame_abc, &frameFinished, &packet_abc);
                        if(ret<0)
                        {
                            
                        }
                         */
                        ret = -1;
                        if (avcodec_send_packet(m_codecCtx_abc, &packet_abc) == 0)
                        {
                            if (avcodec_receive_frame(m_codecCtx_abc, m_decodedFrame_abc) != 0) {
                                ret = -1;
                            } else {
                                ret = 0;
                            }
                        }
                        else
                        {
                            ret = -1;
                        }
                        
                        img_convert_ctxBmp_abc = sws_getContext(m_codecCtx_abc->width, m_codecCtx_abc->height, AV_PIX_FMT_YUV420P,
                                                                m_codecCtx_abc->width/4,m_codecCtx_abc->height/4,AV_PIX_FMT_BGR24,SWS_POINT, NULL, NULL, NULL); //   SWS_FAST_BILINEAR
                        pFrameRGB_abc=av_frame_alloc();
                        
                        
                        pFrameRGB_abc->format = AV_PIX_FMT_BGR24;
                        pFrameRGB_abc->width = m_codecCtx_abc->width/4;
                        pFrameRGB_abc->height = m_codecCtx_abc->height/4;
                        av_image_alloc( pFrameRGB_abc->data, pFrameRGB_abc->linesize, pFrameRGB_abc->width,
                                       pFrameRGB_abc->height,
                                       AV_PIX_FMT_BGR24, 4);
                        
                        sws_scale(img_convert_ctxBmp_abc,
                                  (const uint8_t *const *) m_decodedFrame_abc->data,
                                  m_decodedFrame_abc->linesize, 0, m_decodedFrame_abc->height,
                                  pFrameRGB_abc->data, pFrameRGB_abc->linesize);
                        
                        //ret = 0;
                        AVCodecContext      *My_EncodecodecCtx_abc;
                        AVCodec *codecA = avcodec_find_encoder(AV_CODEC_ID_BMP);
                        //if (!codecA) {
                        //    ret = -1;
                       // }
                        
                        My_EncodecodecCtx_abc = avcodec_alloc_context3(codecA);
                       // if (!My_EncodecodecCtx_abc) {
                       //     ret = -1;
                       // }
                        
                        My_EncodecodecCtx_abc->codec_type = AVMEDIA_TYPE_VIDEO;
                        My_EncodecodecCtx_abc->pix_fmt = AV_PIX_FMT_BGR24;
                        My_EncodecodecCtx_abc->width = pFrameRGB_abc->width;// m_codecCtx->width;
                        My_EncodecodecCtx_abc->height =pFrameRGB_abc->height;// m_codecCtx->height;
                        My_EncodecodecCtx_abc->time_base.num = 1; //m_codecCtx->time_base.num;
                        My_EncodecodecCtx_abc->time_base.den = 1;//m_codecCtx->time_base.den;
                        
                        if ((ret = avcodec_open2(My_EncodecodecCtx_abc, codecA, NULL)) < 0) {
                         //   ret = -1;
                        }
                        AVPacket            MypktA;
                        
                        av_init_packet(&MypktA);
                        MypktA.data = NULL;
                        MypktA.size = 0;
                        /*
                        int got = 0;
                        ret =  avcodec_encode_video2(My_EncodecodecCtx_abc, &MypktA,pFrameRGB_abc, &got);
                        
                        if(ret <0 || got == 0)
                        {
                            ret = -1;
                        }
                         */
                        
                        ret =-1;
                        if( avcodec_send_frame(My_EncodecodecCtx_abc,pFrameRGB_abc)==0)
                        {
                            if(avcodec_receive_packet(My_EncodecodecCtx_abc,&MypktA)==0)
                            {
                                ret = 0;
                            }
                        }
                        
                        if (ret == 0)
                        {
                            img = [UIImage imageWithData: [NSData dataWithBytes:MypktA.data length:MypktA.size]];
                        }
                        avcodec_free_context(&My_EncodecodecCtx_abc);
                        avcodec_free_context(&m_codecCtx_abc);
                        av_frame_free(&pFrameRGB_abc);
                        av_frame_free(&m_decodedFrame_abc);
                        av_packet_unref(&packet_abc);
                        av_packet_unref(&MypktA);
                    }
                    if(_bCancel)
                    {
                        return ; //self.Sucess(nil,filename);
                    }
                    else
                    {
                        self.Sucess(img,filename);
                        return;
                    }
                }
            }
        }
    }
    [_serchSocket DisConnect];
    //[_socketArray removeObject:_serchSocket];
    self.Sucess(nil,filename);
    
}


@end
