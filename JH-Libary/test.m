//
//  test.m
//  JH_Libary
//
//  Created by AivenLau on 2019/3/4.
//  Copyright © 2019 AivenLau. All rights reserved.
//

#import "test.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/pixfmt.h"
#include "libavutil/imgutils.h"
#include "libavutil/time.h"
#include "libavutil/error.h"
#include "libavutil/frame.h"

@implementation test

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(void)F_Convert:(NSString *)sPath
{
    
//    AVCodec *pVedioCodec = NULL;
//    AVCodec *pAudioCodec = NULL;
//
//    AVCodecContext      *m_codecCtx_Video ;
//    AVCodecContext      *m_codecCtx_Audio ;
//    AVFormatContext     *m_formatCtx;
//    int videoindex=-1;
//    int audioindex=-1;
//    char bufff[1025];
//    int err_code;
//    const char *path = [sPath UTF8String];
//    m_formatCtx = avformat_alloc_context();
//    err_code = avformat_open_input(&m_formatCtx, path, NULL, NULL);
//    if (err_code != 0)
//    {
//        av_strerror(err_code, bufff, 1024);
//        NSLog(@"Open input path errorcode = %d info = %s ",err_code,bufff);
//        avformat_free_context(m_formatCtx);
//        m_formatCtx = NULL;
//        return ;
//    }
//    if(avformat_find_stream_info(m_formatCtx, NULL) < 0) {
//        NSLog(@"avformat_find_stream_info failed!\n");
//        if (m_formatCtx!=NULL)
//        {
//            avformat_close_input(&m_formatCtx);
//            avformat_free_context(m_formatCtx);
//            m_formatCtx = NULL;
//        }
//        return ;
//    }
//
//    int ret = 0;
//    avcodec_version();
//    av_dump_format(m_formatCtx, 0, path, 0);
//
//
//    for(int i=0; i<m_formatCtx->nb_streams; i++)
//    {
//
//        AVStream *strem =m_formatCtx->streams[i];
//#if 0
//        if(strem->codecpar->codec_type==AVMEDIA_TYPE_VIDEO)
//        {
//            videoindex=i;
//
//        }
//        if(strem->codecpar->codec_type==AVMEDIA_TYPE_AUDIO)
//        {
//            audioindex=i;
//        }
//#else
//        if(strem->codec->codec_type == AVMEDIA_TYPE_VIDEO)
//        {
//            videoindex=i;
//        }
//        if(strem->codec->codec_type == AVMEDIA_TYPE_AUDIO)
//        {
//            audioindex=i;
//        }
//
//#endif
//    }
//
//#if 0
//    pVedioCodec = avcodec_find_decoder(m_formatCtx->streams[videoindex]->codecpar->codec_id);
//    pAudioCodec= avcodec_find_decoder(m_formatCtx->streams[audioindex]->codecpar->codec_id);
//    m_codecCtx_Video = avcodec_alloc_context3(pVedioCodec);
//    avcodec_parameters_to_context(m_codecCtx_Video, m_formatCtx->streams[videoindex]->codecpar);
//#else
//    pVedioCodec = avcodec_find_decoder(m_formatCtx->streams[videoindex]->codec->codec_id);
//    pAudioCodec= avcodec_find_decoder(m_formatCtx->streams[audioindex]->codec->codec_id);
//    m_codecCtx_Video =m_formatCtx->streams[audioindex]->codec;
//    //m_codecCtx_Video = avcodec_alloc_context3(pVedioCodec);
//    //avcodec_parameters_to_context(m_codecCtx_Video, m_formatCtx->streams[videoindex]->codecpar);
//#endif
//
//    err_code = avcodec_open2(m_codecCtx_Video, pVedioCodec, NULL);
//    if(err_code <0)
//    {
//        NSLog(@"avcodec_open2 failed! error");
//        if (m_formatCtx)
//        {
//            avcodec_free_context(&m_codecCtx_Video);
//            avformat_close_input(&m_formatCtx);
//            avformat_free_context(m_formatCtx);
//            m_formatCtx = NULL;
//            m_codecCtx_Video = NULL;
//        }
//        return ;
//    }
//#if 0
//    m_codecCtx_Audio= avcodec_alloc_context3(pAudioCodec);
//    avcodec_parameters_to_context(m_codecCtx_Audio, m_formatCtx->streams[audioindex]->codecpar);
//#else
//    m_codecCtx_Audio= m_formatCtx->streams[audioindex]->codec;
//#endif
//    err_code = avcodec_open2(m_codecCtx_Video, pAudioCodec, NULL);
//    if(err_code <0)
//    {
//        NSLog(@"avcodec_open2 failed! error");
//       if (m_formatCtx)
//        {
//            avcodec_free_context(&m_codecCtx_Audio);
//            avformat_close_input(&m_formatCtx);
//            avformat_free_context(m_formatCtx);
//            m_formatCtx = NULL;
//            m_codecCtx_Audio = NULL;
//
//            avcodec_free_context(&m_codecCtx_Video);
//            m_codecCtx_Video = NULL;
//        }
//        return ;
//    }
//
//    AVPacket pkt = {0};
//    av_init_packet(&pkt);
//    pkt.data = NULL;
//    pkt.size = 0;
//
//    AVFrame *m_decodedFrame_Video=av_frame_alloc();
//    AVFrame *m_decodedFrame_Audio=av_frame_alloc();
//    int nFinished = 0;
//    {
//        while(av_read_frame(m_formatCtx, &pkt)>=0)
//        {
//            int stream_index = pkt.stream_index;
//            if(stream_index == videoindex)
//            {
//#if 0
//                if (avcodec_send_packet(m_codecCtx_Video, &pkt) == 0)
//                {
//                    if ((ret = avcodec_receive_frame(m_codecCtx_Video, m_decodedFrame_Video)) == 0) {
//                        {
//                            //[self F_H264Decord:ret TYPE:1];
//                        }
//                    }
//                }
//#else
//
//                ret = avcodec_decode_video2(m_codecCtx_Video, m_decodedFrame_Video, &nFinished, &pkt);
//                if(ret >=0  && nFinished>0)
//                {
//                    //[self F_H264Decord:ret TYPE:1];
//                }
//#endif
//                av_packet_unref(&pkt);
//            }
//            if(stream_index == audioindex)
//            {
//#if 0
//                if (avcodec_send_packet(m_codecCtx_Audio, &pkt) == 0)
//                {
//                    if ((ret = avcodec_receive_frame(m_codecCtx_Audio, m_decodedFrame_Audio)) == 0) {
//                        {
//                            //[self F_H264Decord:ret TYPE:1];
//                        }
//                    }
//                }
//#else
//#endif
//                av_packet_unref(&pkt);
//            }
//        }
//    }
}

@end
