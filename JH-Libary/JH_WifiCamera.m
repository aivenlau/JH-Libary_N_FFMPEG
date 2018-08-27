
#define  MYSOCKET
#define  BufferLen  (1024*100)
#define  VideoPackLen  (512)

#import <AVFoundation/AVFoundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import "JH_WifiCamera.h"
#import <CoreGraphics/CoreGraphics.h>
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavutil/pixfmt.h"
#include "libavutil/imgutils.h"
#include "libavutil/time.h"
#include "libavutil/error.h"
#include "libavutil/frame.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ALAssetsLibrary+CustomPhotoAlbum.h"
#import "MyFrame.h"
#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>
#import "Reachability_aiven.h"
#import "JPEG_BUFFER.h"
#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#import <NetworkExtension/NetworkExtension.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import "mp4v2.h"
#import "libyuv.h"
//#import "acc/AACEncoder.h"
#import "acc/XDXRecoder.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <fcntl.h>
#include <unistd.h>


#import "phone_rl_protocol.h"
#import "MySocket/MySocket.h"

#import "MyDownLoad_a.h"
#import "MyThumb.h"

#import "My_Header.h"
#import "H264HwDecoderImpl.h"

#ifdef Langtong
#import "MyTFHpple.h"
#endif

//AVCaptureAudioDataOutputSampleBufferDelegate
@interface JH_WifiCamera()<MySocket_Delegate,H264HwDecoderImplDelegate,ReceivedAACData_Delegate>
{
@public
    int 				m_videoStream;
    AVPacket            Mypkt;
    AVPacket            Mypkt_YUV;
    AVFormatContext 	*m_formatCtx;
    AVCodecContext  	*m_codecCtx ;
    AVFrame         	*m_decodedFrame;
    AVFrame             *pFrameYUV;
    
    AVFrame             *pFrameSnap;
    
    AVFrame             *frame_a;
    AVFrame             *frame_b;
    
    
    T_NET_VIDEO_INFO    video_info_A;
    
    struct SwsContext *img_convert_ctx;
    struct SwsContext *img_convert_ctxBmp;
    struct SwsContext *img_convert_ctx_half;
    //struct SwsContext *img_convert_ctx_Rec;
    
    int            nDataCount;
    dispatch_queue_t    _dispatchQueue;
    BOOL                bDisping;
    
    int64_t             m_outFrameCnt;
    int64_t             m_prevTime;
    int                 m_prevLeft;
    AVPacket            m_prevPkt;
    //struct SwsContext   *m_outsws_ctx;
    struct SwsContext   *m_YUV_ctx;
    struct SwsContext   *m_YUV_ctxHalf;
    
    bool                m_bSaveVideo;
    // pthread_t           m_writeThread;
    pthread_mutex_t     m_Frame_Queuelock;
    pthread_cond_t      m_Frame_condition;
    E_PlayerStatus      m_Status;
    NSString            *m_VideoPath;
    
    AVOutputFormat      *m_outFmt;
    AVFormatContext     *m_outCtx;
    AVCodecContext      *m_pOutCodecCtx;
    AVStream            *m_outStrm;
    enum AVCodecID           m_EncodeID;
    
    NSMutableArray      *videoFrames;
    NSMutableArray      *ImageArray;
    
    
    //AVCodecContext      *My_EncodecodecCtx;
    AVCodec             *disp_codec;
    
    BOOL                bInitEncodeBMP;
    
    
    int commandfd;
    int uartCommandfd;
    
    BOOL _isRecording;
    BOOL _alreadyBind;
    BOOL _isWaiting;
    NSInteger indexForPacket;
    BOOL      mIsFirstPacket;
    NSInteger _qValue;
    NSInteger _frameCount;
    
    
    T_NET_VIDEO_INFO  info;
    int    RevFlag;
    AVPicture picture;
    AVCodec *codec;
    AVPacket packet;
    BOOL  bFindKeyFrame;
    
    NSMutableData *restData;
    AVCodecParserContext * m_parser;
    uint64_t   nPacket;
    T_NET_FRAME_HEADER head;
    T_REQ_MSG    req_msg;
    
    enum AVPixelFormat pix_format;
    enum AVPixelFormat disp_pix_format;
    enum AVCodecID     dispCodeID;
    
    //int nDispWidth;
    //int nDispHeight;
    
    Byte    *_packDataA;//[1024*1024*2];
    Byte    *_packData;//[1024*1024*2];
    
    
    
    
    
    int         nFrame_Count;
    int64_t     nStartTime;
    
    //GPRTP
    
    
    
    
    VTCompressionSessionRef _encodeSesion;
    dispatch_queue_t _encodeQueue;
    
    int nFps;
    
    
    MP4TrackId video;
    MP4TrackId audio_trkid;
    MP4FileHandle fileHandle;
    CVPixelBufferRef pixelBuffer;
    
    
    H264HwDecoderImpl *h264Decoder;
    
    
    
    
    
}

@property(strong,nonatomic) MyFrame  *my_snapframe;
@property(assign,nonatomic)  float  nScale;
@property(assign,nonatomic)   int  nRota;

@property(assign,nonatomic)   BOOL  bG_Audio;   //录像是是否录入声音
//@property (nonatomic , strong) AACEncoder                *aacEncoder;
@property (nonatomic, strong) XDXRecorder    *liveRecorder;
//@property (nonatomic , strong) AVCaptureSession          *session;
@property (nonatomic , strong) AVAudioSession          *session;


@property (nonatomic , assign) AudioComponentInstance audioUnit;

@property (nonatomic , strong) dispatch_queue_t          AudioQueue;
@property (nonatomic , strong) AVCaptureConnection       *audioConnection;
@property (nonatomic , strong) AVCaptureAudioDataOutput *audioOutput;


@property(assign,nonatomic)   int nDispWidth;
@property(assign,nonatomic)   int nDispHeight;

@property  (assign,nonatomic)  char *jpgbuffer;
@property  (assign,nonatomic)  char *databuffer;
@property  (assign,nonatomic)  uint8_t *readRtpBuffer;//[1600];
@property  (assign,nonatomic)  Byte    *pBuffer;

@property  (assign,nonatomic)  BOOL bCanWrite;
@property  (assign,nonatomic)  BOOL spsppsFound;

@property  (strong,nonatomic)  NSString *sver;
@property (assign,nonatomic)  int nRecordWidth;
@property (assign,nonatomic)  int nRecordHeight;

@property (assign,nonatomic)  BOOL  bSetRecordWH;

@property (assign,nonatomic)  uint64_t  nFrameCount;
@property (assign,nonatomic)  int  nDispFps;
@property (assign,nonatomic)  int64_t   nAdjCountStartTime;
@property (assign,nonatomic)  uint64_t  nErrorFrame;
@property (strong, nonatomic) JPEG_BUFFER *jpg0;
@property (strong, nonatomic) JPEG_BUFFER *jpg1;
@property (strong, nonatomic) JPEG_BUFFER *jpg2;


@property (strong, nonatomic) NSLock *packetLock;
@property (strong, nonatomic) NSMutableArray *packets;


@property (assign,nonatomic) int videofd;

@property (assign,nonatomic)  BOOL isCancelled;




@property (assign,nonatomic)  BOOL bSNT;
@property (strong,nonatomic)  UIImage *imgSNT;
@property (weak,nonatomic)  JH_OpenGLView *imageView;

@property (nonatomic,assign) int    nCheckStat;
@property (nonatomic,assign)int64_t  nLost;
@property (nonatomic,assign)int64_t  nRelinkCount;

@property (nonatomic,strong)Reachability_aiven *hostReach;
@property (nonatomic,assign)BOOL     bPlaying;

@property (nonatomic,assign)BOOL     bNeedStop2Relink;

@property (nonatomic,assign)BOOL     bOpen;
@property (nonatomic,assign)BOOL     bExitReLink;


@property(assign,nonatomic)  int64_t             nCurrent_now;//= av_gettime();
@property(assign,nonatomic)  int64_t             nTimeOut;//= av_gettime();

@property(assign,nonatomic)  IC_TYPE        nIC_Type;
@property(strong,nonatomic)  NSString*      sPath;
@property(strong,nonatomic)  NSString*      sAlbumName;
//@property (strong,nonatomic) GCDAsyncUdpSocket *Udp_SendSocket;
//@property (strong,nonatomic) GCDAsyncSocket     *Tcp_SendSocket;

@property(assign,nonatomic)  BOOL           bRecroding;


@property(assign,nonatomic)  BOOL           bNeedSave2Photo;
@property(assign,nonatomic)  BOOL           bSaveCompelete;


@property(assign,nonatomic)  BOOL           bStartCheckStatus;

@property (nonatomic,assign)  uint8_t nHttpType;
@property (nonatomic,assign)  uint16_t nSdStatus;

@property (nonatomic,assign)  uint16_t nSdStatus_GP;

@property (nonatomic,assign)  BOOL bIsWifi;
@property (nonatomic,assign)  BOOL bNeedRecon;

@property (nonatomic,strong)  NSString *sWifiIP;
@property (nonatomic,strong)  NSString *sSerVerIP;


@property (strong, nonatomic) NSData *header10;
@property (strong, nonatomic) NSData *header15;
@property (strong, nonatomic) NSData *header20;
@property (strong, nonatomic) NSData *header25;
@property (strong, nonatomic) NSData *header30;
@property (strong, nonatomic) NSData *header35;
@property (strong, nonatomic) NSData *header40;
@property (strong, nonatomic) NSData *header45;
@property (strong, nonatomic) NSData *header50;


@property (assign, nonatomic) int     packData_Inx;

@property (strong, nonatomic) NSLock *videoLock;

@property (strong, nonatomic) NSMutableData *mjpgFrame;
@property (strong, nonatomic) NSString  *sSavePath;
@property (strong, nonatomic) NSString  *sSavePathPhoto;
@property (assign, nonatomic) BOOL  bNormalStop;


//@property (strong, nonatomic) GCDAsyncUdpSocket *ReceiveUDPSocket;
@property (assign, nonatomic) BOOL  bExit;

@property (assign, nonatomic) BOOL  bTCP;
@property (assign, nonatomic) uint32_t  nHeartbeat;


@property (strong, nonatomic) NSString *sSSID;

@property (assign, nonatomic) BOOL  bOpenOK;

//@property (strong, nonatomic)NSMutableArray      *videoFrames_bak;


@property (assign,nonatomic)  int64_t          nPreTime;
@property (assign,nonatomic)  uint32_t          nGKA_SDStatus;


@property (strong,nonatomic) NSMutableData     *NotifyData;
@property (assign,nonatomic) BOOL  bGk_TcpOK;
@property (assign,nonatomic) BOOL  bGk_NormalExit;

@property (assign,nonatomic) BOOL  bNeedCreateNotify;

@property (assign,nonatomic) int32_t  session_id;

@property (assign,nonatomic) BOOL     bSima;


@property (assign,nonatomic) BOOL  bOpenVideoOK;
@property (nonatomic,assign) Byte     nDelayms;
@property (nonatomic,assign) BOOL     bGKA_Start;
@property (nonatomic,assign) BOOL     bisPlayGKA;
@property (nonatomic,assign) BOOL     bFlip;
@property (nonatomic,assign) BOOL     b3D;
@property (nonatomic,assign) BOOL     b3DA;




@property (nonatomic,strong) NSData *lastStartCode;
@property (nonatomic,strong) NSData *startcodeData;

@property (nonatomic,strong)NSMutableData *keyFrame;

@property (strong,nonatomic) MySocket *GP_tcp_VideoSocket;
@property (strong,nonatomic) MySocket *GKA_Cmd_Socket;
@property (strong,nonatomic) MySocket *GKA_Data_Socket;
@property (strong,nonatomic) MySocket *GKA_Notice_Socket;



//@property (strong,nonatomic) GCDAsyncSocket *GK_tcp_SendSocket;
//@property (strong,nonatomic) GCDAsyncSocket *GK_tcp_DataSocket;
//@property (strong,nonatomic) GCDAsyncSocket *GK_tcp_NoticeSocket;

@property (strong,nonatomic) NSMutableArray   *downArray;
@property (strong,nonatomic) NSMutableArray   *downArray_thumb;

@property (assign,nonatomic) BOOL   bCheckLink;
@property (assign,nonatomic) BOOL   bIsConnect;

//@property (assign,nonatomic) int64_t   nPreCheckT;
//@property (assign,nonatomic) int64_t   nCurrentCheckT;

//@property (assign,nonatomic) int64_t   nCountFrame;
@property (assign,nonatomic) BOOL   bStoped;

@property (assign,nonatomic) uint16_t   nRelinkTime;
@property (assign,nonatomic) int   nRelinkTime_Set;
@property (assign,nonatomic) int   nRelinkTime_Set1;
@property (assign,nonatomic) int   nSetStream;

//@property (assign,nonatomic) BOOL   bNoCheckRelink;

@property (assign,nonatomic) BOOL   bNoDisp;

@property (assign,nonatomic) BOOL   bCanCheckRelink;

@property (assign,nonatomic) BOOL   bStartinit;
@property (assign,nonatomic) BOOL   bSetpause;
@property (assign,nonatomic) BOOL   bConnectedOK;
@property (weak,nonatomic)  JH_OpenGLView *dispView;

@property (strong,nonatomic) UIImage  *dispBackImg;
@property (assign,nonatomic) BOOL    bVaild;

@property (assign,nonatomic) int    nVaildT;

@property (strong,nonatomic) NSString  *sCustomer;

@property (assign,nonatomic) BOOL    b480;


@property(copy,nonatomic) Progress_GP Progress;
@property(copy,nonatomic) SDFiles_GP SDFiles;
//@property(copy,nonatomic) Thumb_Sucess SD_Thumbnail;



@property (strong, nonatomic) MySocket *gpCmd_Socket;

@property(assign,nonatomic) BOOL bGp_GetStatus;

@property(assign,nonatomic) BOOL bGp_Capturing;

@property(assign,nonatomic) BOOL bGp_GetStatusing;

@property(assign,nonatomic) int  nGp_CurrentMode;

@property(assign,nonatomic) int  nGp_SocketStart;

@property(assign,nonatomic) BOOL  bGp_SocketStart;

@property(strong,nonatomic) NSMutableData  *RevData;
@property(strong,nonatomic) NSMutableData  *RevDataB;

//@property(strong,nonatomic)   MyGPSocket *gpSocket;

@property(assign,nonatomic)    BOOL   bSendDecordGKA;


//@property(assign,nonatomic)    NSInteger nLossLinkT;

@property(assign,nonatomic)    BOOL bCanCheckLink_GKA;

@property(strong,nonatomic)   NSString *VideosFloder;
@property(strong,nonatomic)   NSString *PhotosFloder;



@property(assign,nonatomic)     int socket_udp8001;
@property(assign,nonatomic)     int socket_udp20000;
@property(assign,nonatomic)     BOOL bRead20000;


@property(assign,nonatomic)     int nFlag;

@property(assign,nonatomic)     BOOL bSetDispBack_VerB;



@property(strong,nonatomic)     NSString *server_ip;




@property (assign,nonatomic)  int64_t nRecTime;
@property (assign,nonatomic)  int64_t nRecTimePreStart;
//@property (assign,nonatomic)  BOOL  bRealRec;

@property (assign,nonatomic)  BOOL  bGKACmd_UDP;
@property (assign,nonatomic)  BOOL  bGKA_ConnOK;


@property (assign,nonatomic)  BOOL bWhite;
@end


typedef struct
{
    uint8  r;
    uint8  g;
    uint8  b;
    uint8  a;
}RGBA_STRUCT;


@implementation JH_WifiCamera


-(UIImage*)imageWithImage :( UIImage*)sourceImage scaledToSize :( CGSize)newSize;
{
    CGFloat targetWidth = newSize.width;
    CGFloat targetHeight = newSize.height;
    
    CGImageRef imageRef = [sourceImage CGImage];
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(imageRef);
    CGColorSpaceRef colorSpaceInfo = CGImageGetColorSpace(imageRef);
    
    if (bitmapInfo == kCGImageAlphaNone) {
        bitmapInfo = (kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast) ;//kCGImageAlphaNoneSkipLast;
    }
    
    CGContextRef bitmap;
    
    if (sourceImage.imageOrientation == UIImageOrientationUp || sourceImage.imageOrientation == UIImageOrientationDown) {
        bitmap = CGBitmapContextCreate(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    } else {
        bitmap = CGBitmapContextCreate(NULL, targetHeight, targetWidth, CGImageGetBitsPerComponent(imageRef), CGImageGetBytesPerRow(imageRef), colorSpaceInfo, bitmapInfo);
        
    }
    
    if (sourceImage.imageOrientation == UIImageOrientationLeft) {
        CGContextRotateCTM (bitmap, M_PI_2); // + 90 degrees
        CGContextTranslateCTM (bitmap, 0, -targetHeight);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationRight) {
        CGContextRotateCTM (bitmap, -M_PI_2); // - 90 degrees
        CGContextTranslateCTM (bitmap, -targetWidth, 0);
        
    } else if (sourceImage.imageOrientation == UIImageOrientationUp) {
        // NOTHING
    } else if (sourceImage.imageOrientation == UIImageOrientationDown) {
        CGContextTranslateCTM (bitmap, targetWidth, targetHeight);
        CGContextRotateCTM (bitmap, -M_PI); // - 180 degrees
    }
    
    CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), imageRef);
    CGImageRef ref = CGBitmapContextCreateImage(bitmap);
    UIImage* newImage = [UIImage imageWithCGImage:ref];
    
    CGContextRelease(bitmap);
    CGImageRelease(ref);
    
    return newImage;
}

-(void)F_GetServerIP
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    NSString *sIp=nil;
    success = (getifaddrs(&addrs) == 0);
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                {
                    sIp =  [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    NSRange range = [sIp rangeOfString:@"192.168.234."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.234.1";
    }
    range = [sIp rangeOfString:@"192.168.25."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.25.1";
    }
    range = [sIp rangeOfString:@"192.168.26."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.26.1";
    }
    range = [sIp rangeOfString:@"192.168.27."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.27.1";
    }
    range = [sIp rangeOfString:@"192.168.28."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.28.1";
    }
    range = [sIp rangeOfString:@"192.168.29."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.29.1";
    }
    range = [sIp rangeOfString:@"192.168.30."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.30.1";
    }
    range = [sIp rangeOfString:@"192.168.123."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"192.168.123.1";
    }
    
    range = [sIp rangeOfString:@"175.16.10."];
    if (range.location !=NSNotFound)
    {
        self.sSerVerIP = @"175.16.10.2";
    }
    
    
}

-(BOOL)naIsValidType
{
    return [self F_SetOpInfo];
}

-(BOOL)F_SetOpInfo
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    NSString *sIp=nil;
    success = (getifaddrs(&addrs) == 0);
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                {
                    sIp =  [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    BOOL re = NO;
    if(!sIp)
        return re;
    
    self.sSerVerIP=@"192.168.200.1";
    
    NSRange range = [sIp rangeOfString:@"192.168.234."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.234.";
        self.sSerVerIP =@"192.168.234.1";
        re = YES;
    }
    range = [sIp rangeOfString:@"192.168.25."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.25.";
        self.sSerVerIP =@"192.168.25.1";
        re = YES;
    }
    range = [sIp rangeOfString:@"192.168.26."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.26.";
        self.sSerVerIP =@"192.168.26.1";
        re = YES;
    }
    range = [sIp rangeOfString:@"192.168.27."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.27.";
        self.sSerVerIP =@"192.168.27.1";
        re = YES;
    }
    range = [sIp rangeOfString:@"192.168.28."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.28.";
        self.sSerVerIP =@"192.168.28.1";
        re = YES;
    }
    range = [sIp rangeOfString:@"192.168.29."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.29.";
        self.sSerVerIP =@"192.168.29.1";
        re = YES;
    }
    range = [sIp rangeOfString:@"192.168.30."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.30.";
        self.sSerVerIP =@"192.168.30.1";
        re = YES;
    }
    
    range = [sIp rangeOfString:@"192.168.123."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"192.168.123.";
        self.sSerVerIP =@"192.168.123.1";
        re = YES;
    }
    
    range = [sIp rangeOfString:@"175.16.10."];
    if (range.location !=NSNotFound)
    {
        self.sWifiIP = @"175.16.10.";
        self.sSerVerIP =@"175.16.10.2";
        re = YES;
    }
    return re;
    
}
-(void)SetIcType:(IC_TYPE)nICType
{
    //[self naSetIcType:nICType];
    self.nIC_Type = nICType;
    if(nICType == IC_NO)
    {
        if(self.hostReach)
            [self.hostReach stopNotifier];
        self.hostReach=nil;
        self.bIsWifi = NO;
        return;
    }
    if(nICType == IC_GK)
    {
        self.sWifiIP = @"192.168.234.";
        self.sSerVerIP =@"192.168.234.1";
        
    }
    else if(nICType == IC_SN)
    {
        self.sWifiIP = @"192.168.123.";
        self.sSerVerIP =@"192.168.123.1";
    }
    else if(nICType == IC_GKA)
    {
        self.sWifiIP = @"175.16.10.";
        self.sSerVerIP =@"175.16.10.2";
    }
    else if(nICType == IC_GPH264)
    {
        self.sWifiIP = @"192.168.27.";
        self.sSerVerIP =@"192.168.27.1";
    }
    else if(nICType == IC_GPRTP)
    {
        self.sWifiIP = @"192.168.28.";
        self.sSerVerIP =@"192.168.28.1";
    }
    else if(nICType == IC_GPRTPB)
    {
        self.sWifiIP = @"192.168.29.";
        self.sSerVerIP =@"192.168.29.1";
    }
    else if(nICType == IC_GPH264A)
    {
        self.sWifiIP = @"192.168.30.";
        self.sSerVerIP =@"192.168.30.1";
    }
    
}

-(IC_TYPE)F_AdjType:(NSString *)sPat
{
    IC_TYPE SetIcType = [self F_GetType_];
    if(SetIcType == IC_NO)
        return NO;
    
    [self SetIcType:SetIcType];
    
    if([sPat hasPrefix:@"rtsp://192.168.25.1"])
    {
        self.sWifiIP = @"192.168.25.";
        self.sSerVerIP =@"192.168.25.1";
        SetIcType = IC_GPRTSP;
    }
    if([sPat hasPrefix:@"rtsp://192.168.26.1"])
    {
        self.sWifiIP = @"192.168.26.";
        self.sSerVerIP =@"192.168.26.1";
        SetIcType = IC_GPRTSP;
    }
    
    if([sPat hasPrefix:@"http://192.168.25.1"])
    {
        self.sWifiIP = @"192.168.25.";
        self.sSerVerIP =@"192.168.25.1";
        SetIcType = IC_GP;
    }
    if([sPat hasPrefix:@"http://192.168.26.1"])
    {
        self.sWifiIP = @"192.168.26.";
        self.sSerVerIP =@"192.168.26.1";
        SetIcType = IC_GP;
    }
    self.nIC_Type = SetIcType;
    return  SetIcType;
}


-(int)F_GetType_
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    NSString *sIp=nil;
    success = (getifaddrs(&addrs) == 0);
    if (success)
    {
        cursor = addrs;
        while (cursor != NULL)
        {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                {
                    sIp =  [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    
    /*
     IC_GK = 0,      //192.168.234.X
     
     IC_SN,          //192.168.123.X
     IC_GKA,             //175.16.10.X
     IC_GP,          //192.168.25.X
     IC_GPRTSP,   //192.168.26.X
     IC_GPH264,   //192.168.27.X
     IC_GPRTP,    //192.168.28.X
     IC_GPRTPB,   //192.168.29.X
     IC_GPH264A,   //192.168.30.X
     */
    
    if(!sIp)
        return IC_NO;
    NSRange range = [sIp rangeOfString:@"192.168.234."];
    if (range.location !=NSNotFound)
    {
        return IC_GK;
    }
    range = [sIp rangeOfString:@"192.168.25."];
    if (range.location !=NSNotFound)
    {
        return IC_GP;
    }
    range = [sIp rangeOfString:@"192.168.26."];
    if (range.location !=NSNotFound)
    {
        return IC_GPRTSP;
    }
    range = [sIp rangeOfString:@"192.168.27."];
    if (range.location !=NSNotFound)
    {
        return IC_GPH264;
    }
    range = [sIp rangeOfString:@"192.168.28."];
    if (range.location !=NSNotFound)
    {
        return IC_GPRTP;
    }
    range = [sIp rangeOfString:@"192.168.29."];
    if (range.location !=NSNotFound)
    {
        return IC_GPRTPB;
    }
    range = [sIp rangeOfString:@"192.168.30."];
    if (range.location !=NSNotFound)
    {
        return IC_GPH264A;
    }
    
    range = [sIp rangeOfString:@"192.168.123."];
    if (range.location !=NSNotFound)
    {
        return IC_SN;
    }
    
    range = [sIp rangeOfString:@"175.16.10."];
    if (range.location !=NSNotFound)
    {
        return IC_GKA;
    }
    return IC_NO;
}

-(void)naSetDispViewB:(JH_OpenGLView *)dispView  BackGround:(UIImage *)img
{
    self.dispView = dispView;
    self.bSetDispBack_VerB = YES;
    [self.dispView SetRotation:_nRota];
    if(img)
    {
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize reSize = CGSizeMake(640, 360);
        UIGraphicsBeginImageContextWithOptions(reSize, NO, scale);
        [img drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
        UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.dispBackImg = reSizeImage;
        [self F_DispBack:self.dispBackImg];
    }
}

-(void)naSetDispView:(JH_OpenGLView *)dispView  BackGround:(UIImage *)img
{
    self.dispView = dispView;
    self.bSetDispBack_VerB = NO;
    [self.dispView SetRotation:_nRota];
    
    if(img)
    {
        CGFloat scale = [[UIScreen mainScreen] scale];
        CGSize reSize = CGSizeMake(640, 360);
        UIGraphicsBeginImageContextWithOptions(reSize, NO, scale);
        [img drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
        UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.dispBackImg = reSizeImage;
        [self F_DispBack:self.dispBackImg];
    }
}

-(void)naSetRecordAudio:(BOOL)bGAudio
{
    _bG_Audio = bGAudio;
}
-(int)F_RecGP:(NSString *)sPath SaveTyoe:(TYPE_SNAP_REC)nType Destination:(TYPE_DEST)dest
{
    if(sPath==nil && dest ==TYPE_DEST_SNADBOX && (TYPE_ONLY_PHONE == nType || TYPE_ONLY_PHONE == nType))
    {
        return -2;
    }
    
    if(nType == TYPE_ONLY_PHONE)
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            return [self _naSaveVideo:nil];
        }
        else
        {
            if(sPath)
                return [self _naSaveVideo:sPath];
            else
                return -1;
        }
    }
    else if(nType == TYPE_ONLY_SD)
    {
        {
            return [self naStartRemoteRec];
        }
    }
    else
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            [self _naSaveVideo:nil];
        }
        else
        {
            if(sPath)
                [self _naSaveVideo:sPath];
        }
        //if(self.nSdStatus_GP & 0x0400)
        return [self naStartRemoteRec];
    }
    return 0;
    
}


-(int)naStartRecord:(NSString *)sPath SaveTyoe:(TYPE_SNAP_REC)nType Destination:(TYPE_DEST)dest
{
    
    if(self.nIC_Type == IC_GPRTSP || self.nIC_Type == IC_GPH264)
    {
        return [self F_RecGP:sPath  SaveTyoe:nType Destination:dest];
    }
    
    /*
     if(self.nIC_Type == IC_GKA)
     {
     if(!self.bVaild)
     {
     return -100;
     }
     }
     */
    
    
    if(!self.bConnectedOK)
        return -1;
    if(sPath==nil && dest ==TYPE_DEST_SNADBOX && (TYPE_ONLY_PHONE == nType || TYPE_ONLY_PHONE == nType))
    {
        return -2;
    }
    
    if(nType == TYPE_ONLY_PHONE)
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            return [self _naSaveVideo:nil];
        }
        else
        {
            if(sPath)
                return [self _naSaveVideo:sPath];
            else
                return -1;
        }
    }
    else if(nType == TYPE_ONLY_SD)
    {
        if(self.nSdStatus & SD_Ready)
        {
            return [self naStartRemoteRec];
        }
        else
        {
            return -1;
        }
    }
    else
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            [self _naSaveVideo:nil];
        }
        else
        {
            if(sPath)
                [self _naSaveVideo:sPath];
        }
        if(self.nSdStatus & SD_Ready)
            return [self naStartRemoteRec];
    }
    return 0;
}

-(int)naSaveSnapshot_All:(NSString *)spath
{
    
    return 0;
}

-(int)F_SanpGP:(NSString *)sPath SaveTyoe:(TYPE_SNAP_REC)nType Destination:(TYPE_DEST)dest
{
    if(!self.bConnectedOK)
        return -1;
    if(sPath==nil && dest ==TYPE_DEST_SNADBOX && (TYPE_ONLY_PHONE == nType || TYPE_ONLY_PHONE == nType))
    {
        return -2;
    }
    
    if(nType == TYPE_ONLY_PHONE)
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            return [self naSaveSnapshot];
        }
        else
        {
            if(sPath)
                return [self naSaveSnapshot:sPath];
            else
                return -1;
        }
    }
    else if(nType == TYPE_ONLY_SD)
    {
        if(self.nSdStatus_GP & 0x0400)
            return [self naRemoteSnapshot];
        else
            return -1;
    }
    else
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            [self naSaveSnapshot];
        }
        else
        {
            if(sPath)
                [self naSaveSnapshot:sPath];
        }
        if(self.nSdStatus_GP & 0x0400)
            [self  naRemoteSnapshot];
    }
    return 0;
    
}

-(int)naSnapPhoto:(NSString *)sPath SaveTyoe:(TYPE_SNAP_REC)nType Destination:(TYPE_DEST)dest
{
    if(self.nIC_Type == IC_GPRTSP || self.nIC_Type == IC_GPH264)
    {
        return [self F_SanpGP:sPath SaveTyoe:nType Destination:dest];
    }
    
    //if(!self.bVaild && self.nIC_Type == IC_GKA)
    //    return -100;
    if(!self.bConnectedOK)
        return -1;
    if(sPath==nil && dest ==TYPE_DEST_SNADBOX && (TYPE_ONLY_PHONE == nType || TYPE_ONLY_PHONE == nType))
    {
        return -2;
    }
    
    if(nType == TYPE_ONLY_PHONE)
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            return [self naSaveSnapshot];
        }
        else
        {
            if(sPath)
                return [self naSaveSnapshot:sPath];
            else
                return -1;
        }
    }
    else if(nType == TYPE_ONLY_SD)
    {
        if(self.nSdStatus & SD_Ready)
            return [self naRemoteSnapshot];
        else
            return -1;
    }
    else
    {
        if(dest == TYPE_DEST_GALLERY)
        {
            [self naSaveSnapshot];
        }
        else
        {
            if(sPath)
                [self naSaveSnapshot:sPath];
        }
        if(self.nSdStatus & SD_Ready)
            [self  naRemoteSnapshot];
    }
    return 0;
    
}

static   int   interrupt_cb( void   *para)
{
    JH_WifiCamera * wificamera = (__bridge JH_WifiCamera *)para;
    if(wificamera==nil)
        return 0;
    if(wificamera.nTimeOut==0)
    {
        if(!wificamera.bIsWifi)
            return 1;
        else
            return 0;
    }
    int64_t  now = av_gettime();
    if((now - wificamera.nCurrent_now)>wificamera.nTimeOut)
    {
        return 1;
    }
    return 0;
}


- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    //    NSLog(@"Supported interfaces: %@", ifs);
    id infoa = nil;
    for (NSString *ifnam in ifs) {
        infoa = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        //  NSLog(@"%@ => %@", ifnam, info);
        if (infoa && [infoa count]) { break; }
    }
    return infoa;
}


-(NSString *)F_GetSSID
{
    
    NSDictionary *ifs= [self fetchSSIDInfo];
    NSString *ssid = [[ifs objectForKey:@"SSID"] lowercaseString];
    //self.sSSID = ssid;
    return ssid;
}

-(void)F_SetTimeout:(int64_t) timeout
{
    self.nCurrent_now= av_gettime();
    self.nTimeOut = timeout*1000;
    
}

/*
 IC_GK = 0,      //192.168.234.X
 IC_GP,          //192.168.25.X
 IC_SN,          //192.168.123.X
 IC_GKA,             //175.16.10.X
 IC_GPRTSP,   //192.168.26.X
 IC_GPH264,   //192.168.27.X
 IC_GPRTP,    //192.168.28.X
 IC_GPH264A,   //192.168.30.X
 IC_GPRTPB,   //192.168.29.X
 */



-(void)naSetIcType:(IC_TYPE)nICType
{
    ;
}

-(void)F_StartChecknetWrok:(const char *)ipaddr
{
    
    __weak JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
                   {
                       struct sockaddr_in address;
                       memset(&address, 0, sizeof(address));
                       address.sin_len = sizeof(address);
                       address.sin_family = AF_INET;
                       address.sin_port = htons(80);
                       address.sin_addr.s_addr = inet_addr(ipaddr);
                       if(weakself.hostReach)
                           [weakself.hostReach stopNotifier];
                       weakself.hostReach=nil;
                       [[NSNotificationCenter defaultCenter] removeObserver:self];
                       [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(network_change:) name:kReachabilityChangedNotification_aiven object:nil];
                       weakself.hostReach=[Reachability_aiven reachabilityWithAddress:(const struct sockaddr *)&address];
                       [weakself.hostReach startNotifier];//开始监听网络请求的变化
                       if([weakself isWifiCamera])
                       {
                           weakself.bIsWifi = YES;
                       }
                       else
                       {
                           weakself.bIsWifi = NO;
                       }
                   });
}


-(void)dealloc
{
    if(_packDataA!=NULL)
    {
        free(_packDataA);
        _packDataA = NULL;
    }
    if(_pBuffer!=NULL)
    {
        free(_pBuffer);
        _pBuffer=NULL;
        
    }
    if(_readRtpBuffer!=NULL)
    {
        free(_readRtpBuffer);
        _readRtpBuffer=NULL;
    }
    
    NSLog(@"WifiCamera dealloc!");
}


-(id)init
{
    self = [super init];
    if(self)
    {
        _nScale = 1.0f;
        _nRota = 0;
        _bSetRecordWH = NO;
        
        pFrameSnap = NULL;
        _my_snapframe = [[MyFrame alloc] init];
        
        _bWhite = NO;
        _bGKACmd_UDP = true;
        _bGKA_ConnOK = false;
      //  self.bRealRec = NO;
        _nRecordWidth = 640;
        _nRecordHeight = 360;
        _readRtpBuffer = malloc(1600);
        h264Decoder = [[H264HwDecoderImpl alloc] init];
        h264Decoder.delegate = self;
        
        pixelBuffer = NULL;
        _encodeQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        nFps = 20;
        _jpgbuffer = NULL;
        _databuffer = NULL;
        
        fileHandle =MP4_INVALID_FILE_HANDLE;
        
        struct sigaction sa;
        sa.sa_handler = SIG_IGN;
        sigaction( SIGPIPE, &sa, 0 );
        
        _pBuffer = (Byte *)malloc(VideoPackLen);
        
        _bVaild = YES;
        _nVaildT = 0;
        
        _GP_tcp_VideoSocket=[[MySocket alloc] init];
        _GKA_Cmd_Socket =[[MySocket alloc] init];
        _GKA_Data_Socket =[[MySocket alloc] init];
        _GKA_Notice_Socket =[[MySocket alloc] init];
        
        
        //_gpSocket = [[MyGPSocket alloc] init];
        _RevData = [[NSMutableData alloc] init];
        _RevDataB= [[NSMutableData alloc] init];
        
        _gpCmd_Socket = [[MySocket alloc] init];
        commandfd = -1;
        _videofd = -1;
        
        _nDispWidth = 640;
        _nDispHeight = 360;
        _b480=false;
        [self F_Set480P:_b480];
        
        
        self.packetLock = [[NSLock alloc] init];
        self.packets = [[NSMutableArray alloc] init];
        
        
        mIsFirstPacket = NO;
        _packDataA =(Byte *)malloc(1024*1024*2);
        _packData =_packDataA;
        _packData_Inx = 0;
        
        
        avcodec_register_all();
        av_register_all();
        avformat_network_init();
        
        
        
        self.nRelinkTime_Set1 = 8000/100;
        // self.nDelaySet = 10;
        self.bFlip = false;
        
        self.NotifyData = [[NSMutableData alloc] init];
        
        RevFlag = 0;
        self.nCheckStat = 0;
        self.bTCP = NO;
        
        m_codecCtx = NULL;
        restData = nil;
        
        self.downArray = [[NSMutableArray alloc] init];
        _downArray_thumb = [[NSMutableArray alloc] init];
        
        
        
        unsigned char startcode[] = {0,0,1};
        self.startcodeData = [NSData dataWithBytes:startcode length:3];
        
        self.keyFrame = [[NSMutableData alloc]init];
        
        self.nPreTime = av_gettime();
        self.bPlaying = NO;
        bDisping = NO;
        videoFrames    = [NSMutableArray array];
        ImageArray    = [NSMutableArray array];
        
        m_EncodeID = AV_CODEC_ID_MPEG4;
        _bNeedSave2Photo = NO;
        _bSaveCompelete = YES;
        _sAlbumName = @"JH_WIFI_Camera";
        _dispatchQueue  = dispatch_queue_create("JH_WifiCamera", DISPATCH_QUEUE_SERIAL);
        [self naSetIcType:IC_NO];
        self.sWifiIP = @"";
        
        
        self.header10 =  [NSData dataWithBytes:Jasc_CF10_Header length:1024];
        self.header15 =  [NSData dataWithBytes:Jasc_CF15_Header length:1024];
        self.header20 =  [NSData dataWithBytes:Jasc_CF20_Header length:1024];
        self.header25 =  [NSData dataWithBytes:Jasc_CF25_Header length:1024];
        self.header30 =  [NSData dataWithBytes:Jasc_CF30_Header length:1024];
        self.header35 =  [NSData dataWithBytes:Jasc_CF35_Header length:1024];
        self.header40 =  [NSData dataWithBytes:Jasc_CF40_Header length:1024];
        self.header45 =  [NSData dataWithBytes:Jasc_CF45_Header length:1024];
        self.header50 =  [NSData dataWithBytes:Jasc_CF50_Header length:1024];
        
        //self.mjpgPacket = [NSMutableData new];
        self.mjpgFrame = [NSMutableData new];
        self.videoLock = [[NSLock alloc] init];
        m_parser = 0;
        m_formatCtx = NULL;
        m_decodedFrame = NULL;
        m_codecCtx = NULL;
        img_convert_ctx = NULL;
        img_convert_ctxBmp = NULL;
        pFrameYUV = NULL;
        frame_a = NULL;
        //   pFrameRGB = NULL;
        //My_EncodecodecCtx = NULL;
        m_formatCtx= NULL;
        m_codecCtx = NULL;
        //   pFrameRGB= NULL;
        img_convert_ctx= NULL;
        img_convert_ctxBmp= NULL;
        //  m_outsws_ctx = NULL;
        disp_codec = NULL;
        m_YUV_ctx = NULL;
        m_YUV_ctxHalf = NULL;
        av_log_set_level(AV_LOG_QUIET);
    }
    return self;
}

#pragma mark 硬件解码
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
    
}

-(void)naSetDispStyle:(int)nStyle
{
    self.dispView.nDispStyle = nStyle;
}

#pragma mark -  H264编码回调  H264HwEncoderImplDelegate
- (void)DecordSpsPps:(NSData*)sps pps:(NSData*)pps
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}

- (void)DecordH264dedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}



-(void)F_Set480P:(BOOL)b480p
{
    
    if(b480p)
    {
        Jasc_CF10_Header[0x10*27+0x0A]=0x01;
        Jasc_CF10_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF15_Header[0x10*27+0x0A]=0x01;
        Jasc_CF15_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF20_Header[0x10*27+0x0A]=0x01;
        Jasc_CF20_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF25_Header[0x10*27+0x0A]=0x01;
        Jasc_CF25_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF30_Header[0x10*27+0x0A]=0x01;
        Jasc_CF30_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF35_Header[0x10*27+0x0A]=0x01;
        Jasc_CF35_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF40_Header[0x10*27+0x0A]=0x01;
        Jasc_CF40_Header[0x10*27+0x0B]=0xe0;
        
        Jasc_CF45_Header[0x10*27+0x0A]=0x01;
        Jasc_CF45_Header[0x10*27+0x0B]=0xe0;
        
        
        Jasc_CF50_Header[0x10*27+0x0A]=0x01;
        Jasc_CF50_Header[0x10*27+0x0B]=0xe0;
    }
    else {
        Jasc_CF10_Header[0x10*27+0x0A]=0x01;
        Jasc_CF10_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF15_Header[0x10*27+0x0A]=0x01;
        Jasc_CF15_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF20_Header[0x10*27+0x0A]=0x01;
        Jasc_CF20_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF25_Header[0x10*27+0x0A]=0x01;
        Jasc_CF25_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF30_Header[0x10*27+0x0A]=0x01;
        Jasc_CF30_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF35_Header[0x10*27+0x0A]=0x01;
        Jasc_CF35_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF40_Header[0x10*27+0x0A]=0x01;
        Jasc_CF40_Header[0x10*27+0x0B]=0x68;
        
        Jasc_CF45_Header[0x10*27+0x0A]=0x01;
        Jasc_CF45_Header[0x10*27+0x0B]=0x68;
        
        
        Jasc_CF50_Header[0x10*27+0x0A]=0x01;
        Jasc_CF50_Header[0x10*27+0x0B]=0x68;
    }
    
    
    self.header10 =  [NSData dataWithBytes:Jasc_CF10_Header length:1024];
    self.header15 =  [NSData dataWithBytes:Jasc_CF15_Header length:1024];
    self.header20 =  [NSData dataWithBytes:Jasc_CF20_Header length:1024];
    self.header25 =  [NSData dataWithBytes:Jasc_CF25_Header length:1024];
    self.header30 =  [NSData dataWithBytes:Jasc_CF30_Header length:1024];
    self.header35 =  [NSData dataWithBytes:Jasc_CF35_Header length:1024];
    self.header40 =  [NSData dataWithBytes:Jasc_CF40_Header length:1024];
    self.header45 =  [NSData dataWithBytes:Jasc_CF45_Header length:1024];
    self.header50 =  [NSData dataWithBytes:Jasc_CF50_Header length:1024];
    
}

- (BOOL)isWifiCamera
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    NSString *sIp=nil;
    //NSString *_sIP = @"";
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                {
                    sIp =  [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                    //_sIP = sIp;
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    NSRange range = [sIp rangeOfString:self.sWifiIP];
    if (range.location ==NSNotFound)
    {
        return NO;
    }
    else
        return YES;
}

-(void)network_change:(NSNotification *)notify
{//当网络发生变化的时候，都会触发这个事件
    Reachability_aiven* curReach = [notify object];
    NSParameterAssert([curReach isKindOfClass: [Reachability_aiven class]]);
    NetworkStatus status = [curReach currentReachabilityStatus];
    if(status == ReachableViaWiFi)
    {
        NSString *ssid = [self F_GetSSID];
        if(self.sSSID)
        {
            if(![ssid isEqualToString:self.sSSID])
            {
                if([self.delegate respondsToSelector:@selector(StatusChanged:)])
                    [self.delegate StatusChanged:SSID_CHANGED];
                return;
            }
        }
        if([self isWifiCamera])
        {
            self.bIsWifi = YES;
            
        }
        else
        {
            NSLog(@"Connected wifi but no a Camera!");
        }
    }
    else
    {
        if(self.nIC_Type == IC_SN)
        {
            [self sendStop];
            [self closeVideoSocket];
            [self closeCommandSocket];
        }
        self.bIsWifi = NO;
        self.nSdStatus = 0;
        NSLog(@"disConnected to Camera");
    }
    
#if 0
    if(status == ReachableViaWiFi)
    {
        if([self isWifiCamera])
        {
            if(self.bReConnectent)
            {
                _interrupted = NO;
                self.bFisrtRun = YES;
                self.bExit = NO;
                [self F_InitRTSPA];
            }
        }
        NSString  *ss =[NSString stringWithFormat:@"Connected-%@",self.sIP];
        [self showMessage:ss duration:4.0];
        //  NSLog(@"WIFI");
    }else
    {
        UIImage *img = [UIImage imageNamed:@"wifi_s0"];
        [self.Wifi_Rssi_ImageView setBackgroundImage:img forState:UIControlStateNormal];
        // NSLog(@"无网络");
        if(self.decoder)
        {
            _decoder.bNoConnect = YES;
        }
        [self showMessage:@"Disconnected!" duration:4.0];
    }
#endif
}


-(BOOL)naPause
{
    if(self.imageView)
    {
        self.bSetpause = !self.bSetpause;
        return self.bSetpause;
    }
    return NO;
}

-(int)naPlay:(NSString *)sPath  ImageView:(JH_OpenGLView *)imgview
{
    self.bSetpause = NO;
    self.sPath = sPath;
    self.imageView = imgview;
    self.dispView = imgview;
    if([self initMedia])
    {
        __weak JH_WifiCamera *weakself = self;
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            weakself.bPlaying = YES;
            [weakself DecordData_ffmpeg];
        });
        //return [self naPlay];
        return 0;
    }
    else
        return -1;
}


-(BOOL)initMedia
{
    if(self.sPath==nil)
        return NO;
    NSLog(@"开始初始化  。。。。");
    
    if(self.nIC_Type == IC_GPRTSP || self.nIC_Type == IC_GPRTPB)
    {
        Byte cmd[7];
        cmd[0]='J';
        cmd[1]='H';
        cmd[2]='C';
        cmd[3]='M';
        cmd[4]='D';
        cmd[4]='D';
        cmd[5]=0x10;
        cmd[6]=0x00;
        NSData *data = [[NSData  alloc] initWithBytes:cmd length:7];
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        usleep(1000*20);
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        usleep(1000*20);
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        
        
    }
    
    if(self.nIC_Type == IC_GPH264 || self.nIC_Type == IC_GPH264A)
    {
        Byte cmd[7];
        cmd[0]='J';
        cmd[1]='H';
        cmd[2]='C';
        cmd[3]='M';
        cmd[4]='D';
        cmd[4]='D';
        cmd[5]=0x10;
        cmd[6]=0x00;
        NSData *data = [[NSData  alloc] initWithBytes:cmd length:7];
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        usleep(1000*20);
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        usleep(1000*20);
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        
        
    }
    
    
    int err_code;
    //bMisRTP = 0;
    m_videoStream = -1;
    AVCodec *pCodec = NULL;
    bInitEncodeBMP = NO;
    
    m_formatCtx = avformat_alloc_context();
    m_formatCtx->interrupt_callback.callback = interrupt_cb;
    //--------注册回调函数
    m_formatCtx->interrupt_callback.opaque = (__bridge void *)(self);
    
    NSArray *aArray = [self.sPath componentsSeparatedByString:@":"];
    NSString *sPre=nil;
    if(aArray)
    {
        if(aArray.count>0)
        {
            sPre = aArray[0];
        }
    }
    if(sPre)
    {
        sPre = [sPre lowercaseString];
    }
    self.bOpenOK = NO;
    const char *path = [self.sPath cStringUsingEncoding: NSUTF8StringEncoding];
    char bufff[1025];
    memset(bufff,0,1025);
    [self F_SetTimeout:4000];
    
    
    
    
    err_code = avformat_open_input(&m_formatCtx, path, NULL, NULL);
    if (err_code != 0)
    {
        av_strerror(err_code, bufff, 1024);
        NSLog(@"Open input path errorcode = %d info = %s ",err_code,bufff);
        avformat_free_context(m_formatCtx);
        m_formatCtx = NULL;
        self.bOpen = NO;
        return NO;
    }
    self.bOpenOK = YES;
    self.bOpen = YES;
    self.bIsWifi = YES;
    if(sPre)
    {
        {
            /*
             if(self.bTCP || !self.imageView)
             {
             ;
             }
             else
             */
            {
                m_formatCtx->flags |= AVFMT_FLAG_NOBUFFER;
                m_formatCtx->probesize =1024*200;
                m_formatCtx->max_analyze_duration = 100 * AV_TIME_BASE;
            }
            if(avformat_find_stream_info(m_formatCtx, NULL) < 0) {
                NSLog(@"avformat_find_stream_info failed!\n");
                if (m_formatCtx!=NULL)
                {
                    avformat_close_input(&m_formatCtx);
                    avformat_free_context(m_formatCtx);
                    m_formatCtx = NULL;
                }
                return NO;
            }
        }
    }
    av_dump_format(m_formatCtx, 0, path, 0);
    self.bOpen = YES;
    int videoindex=-1;
    int i=0;
    for(i=0; i<m_formatCtx->nb_streams; i++)
    {
        //if(m_formatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO)
        if(m_formatCtx->streams[i]->codecpar->codec_type==AVMEDIA_TYPE_VIDEO)
        {
            m_videoStream = i;
            videoindex=i;
            break;
        }
    }
    
    if(videoindex==-1){
        NSLog(@"Didn't find a video stream.\n");
        if (m_formatCtx)
        {
            avformat_close_input(&m_formatCtx);
            avformat_free_context(m_formatCtx);
            m_formatCtx = NULL;
        }
        return NO;
    }
    
    
    //m_codecCtx = m_formatCtx->streams[videoindex]->codec;
    //pCodec=avcodec_find_decoder(m_codecCtx->codec_id);
    
    pCodec = avcodec_find_decoder(m_formatCtx->streams[videoindex]->codecpar->codec_id);
    
    if(pCodec==NULL) {
        NSLog(@"Unsupported codec!");
        if (m_formatCtx)
        {
            avformat_close_input(&m_formatCtx);
            avformat_free_context(m_formatCtx);
            m_formatCtx = NULL;
        }
        return NO;
    }
    
    m_codecCtx = avcodec_alloc_context3(pCodec);
    avcodec_parameters_to_context(m_codecCtx, m_formatCtx->streams[videoindex]->codecpar);
    
    err_code = avcodec_open2(m_codecCtx, pCodec, NULL);
    
    if(err_code <0)
    {
        NSLog(@"avcodec_open2 failed! error");
        if (m_formatCtx)
        {
            avcodec_free_context(&m_codecCtx);
            avformat_close_input(&m_formatCtx);
            avformat_free_context(m_formatCtx);
            m_formatCtx = NULL;
            m_codecCtx = NULL;
        }
        return NO;
    }
    m_decodedFrame=av_frame_alloc();
    [self F_InitFrame];
    NSLog(@"开始播放。。。");
    self.nReLinkABC = 0;
    self.bCheckLink = NO;
    return YES;
}

-(BOOL)naInit:(NSString *)sPath  tcp:(BOOL)bTCP
{
    self.bConnectedOK = NO;
    self.bTCP = bTCP;
    return  [self naInit:sPath];
}


- (int)naSetRecFps:(int)nFpsA;
{
    nFps =nFpsA;
    
    return 0;
}


-(void)naSetGpLanguage:(int)nLan
{
    [self F_GP_SetLanguage:nLan];
}

-(int)F_GP_SetLanguage:(Byte)nLanguage
{
    
    if(!self.sSerVerIP)
    {
        [self F_GetServerIP];
    }
    
    Byte cmd[10];
    cmd[0]='U';
    cmd[1]='D';
    cmd[2]='P';
    cmd[3]='S';
    cmd[4]='O';
    cmd[5]='C';
    cmd[6]='K';
    cmd[7]='E';
    cmd[8]='T';
    cmd[9]=(Byte)nLanguage;
    
    
    int clientSocketId;
    ssize_t len;
    socklen_t addrlen;
    struct sockaddr_in client_sockaddr;
    
    // 第一步：创建Socket
    clientSocketId = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(clientSocketId < 0) {
        NSLog(@"creat client socket fail\n");
        return -1;
    }
    
    
    addrlen = sizeof(struct sockaddr_in);
    bzero(&client_sockaddr, addrlen);
    client_sockaddr.sin_len = sizeof(client_sockaddr);
    client_sockaddr.sin_family = AF_INET;
    client_sockaddr.sin_addr.s_addr = inet_addr([self.sSerVerIP UTF8String]);
    client_sockaddr.sin_port = htons(25010);
    
    len = sendto(clientSocketId, cmd, 10, 0, (struct sockaddr *)&client_sockaddr, addrlen);
    
    int re = -1;
    if (len ==10) {
        re = 0;
        //NSLog(@"发送成功");
        //NSLog(@"%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X,%02X",buffer[0],buffer[1],buffer[2],buffer[3],buffer[4],buffer[5],buffer[6],buffer[7],buffer[8],buffer[9],buffer[10],buffer[11],buffer[12]);
    } else {
        //NSLog(@"发送失败");
        re =-1;
    }
    close(clientSocketId);
    return re;
}


-(BOOL)F_Getis480P_A
{
    usleep(5000);
    Byte cmd[2];
    cmd[0]=0xA6;
    cmd[1]=0x6A;
    int udpSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    struct sockaddr_in addr4;
    bzero(&addr4, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(30864);
    addr4.sin_addr.s_addr = inet_addr([self.sSerVerIP UTF8String]);
    socklen_t add_len = sizeof(struct sockaddr_in);
    sendto(udpSocket, cmd, 2, 0, (struct sockaddr *)&addr4, add_len);
    
    Byte buf_[100];
    bzero(buf_, 100);
    
    
    bzero(&addr4, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(30864);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    add_len = sizeof(struct sockaddr_in);
    ssize_t nbytes;
    
    BOOL  b480 = NO;
    struct timeval timeoutA = {0,1000*210};     //20ms
    
    setsockopt(udpSocket,SOL_SOCKET,SO_RCVTIMEO,(char *)&timeoutA,sizeof(struct timeval));
    nbytes = recvfrom(udpSocket, buf_, 100, 0, (struct sockaddr *)&addr4, &add_len);
    if(nbytes<0)
    {
        b480 = NO;
    }
    if(nbytes>=48)
    {
        int n1 = buf_[42]*0x100;
        int n = buf_[41];
        n+=n1;
        if(n==480)
            b480 = YES;
    }
    close(udpSocket);
    return b480;
}

-(BOOL)F_Getis480P
{
    usleep(5000);
    Byte cmd[2];
    cmd[0]=0x42;
    cmd[1]=0x02;
    int udpSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    
    struct sockaddr_in addr4;
    bzero(&addr4, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(30864);
    addr4.sin_addr.s_addr = inet_addr([self.sSerVerIP UTF8String]);
    socklen_t add_len = sizeof(struct sockaddr_in);
    sendto(udpSocket, cmd, 2, 0, (struct sockaddr *)&addr4, add_len);
    
    int nbytes;
    int size;
    Byte buf_[200];
    struct sockaddr_in servaddr; /* the server's full addr */
    bzero((char *)&servaddr, sizeof(servaddr));
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000*210;
    setsockopt(udpSocket, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
    BOOL  b480 = NO;
    if ((nbytes =(int)recvfrom(udpSocket, buf_, 200, 0, (struct sockaddr*)&servaddr, (socklen_t *)&size)) < 0)
    {
        b480 = NO;
    }
    if(nbytes>=48)
    {
        int n1 = buf_[42]*0x100;
        int n = buf_[41];
        n+=n1;
        if(n==480)
            b480 = YES;
    }
    close(udpSocket);
    return b480;
}


-(void)F_GP_InitA
{
    Byte msg[10];
    msg[0]='J';
    msg[1]='H';
    msg[2]='C';
    msg[3]='M';
    msg[4]='D';
    msg[5]=0x10;
    msg[6]=0x00;
    NSData *data = [[NSData  alloc] initWithBytes:msg length:7];
    [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    
    usleep(1000*25);
    msg[0]='J';
    msg[1]='H';
    msg[2]='C';
    msg[3]='M';
    msg[4]='D';
    msg[5]=0x20;
    msg[6]=0x00;
    data = [[NSData  alloc] initWithBytes:msg length:7];
    [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    usleep(1000*10);
    
    msg[0]='J';
    msg[1]='H';
    msg[2]='C';
    msg[3]='M';
    msg[4]='D';
    msg[5]=0xD0;
    msg[6]=0x01;
    data = [[NSData  alloc] initWithBytes:msg length:7];
    [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    usleep(1000*15);
    msg[0]='J';
    msg[1]='H';
    msg[2]='C';
    msg[3]='M';
    msg[4]='D';
    msg[5]=0xD0;
    msg[6]=0x01;
    data = [[NSData  alloc] initWithBytes:msg length:7];
    [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    usleep(1000*10);
}



-(BOOL)naInit:(NSString *)sPath
{
    
    AVFrame *mFrame = av_frame_alloc();
    
    mFrame->width=_nRecordWidth;
    mFrame->height=_nRecordHeight;
    av_image_alloc(
                   mFrame->data, mFrame->linesize, _nRecordWidth,
                   _nRecordHeight,
                   AV_PIX_FMT_YUV420P, 4);
    av_freep(mFrame->data);
    av_frame_free(&mFrame);
    
    NSString *sPat =[sPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    sPat = [sPat lowercaseString];
    
    IC_TYPE SetIcType = [self F_GetType_];
    if(SetIcType == IC_NO)
        return NO;
    [self F_AdjType:sPat];
    
    if(pFrameSnap !=NULL)
    {
        av_freep(&(pFrameSnap->data[0]));
        av_frame_free(&pFrameSnap);
        pFrameSnap = NULL;
    }
    
    /*
     [self SetIcType:SetIcType];
     
     if([sPat hasPrefix:@"rtsp://192.168.25.1"])
     {
     self.sWifiIP = @"192.168.25.";
     self.sSerVerIP =@"192.168.25.1";
     SetIcType = IC_GPRTSP;
     }
     if([sPat hasPrefix:@"rtsp://192.168.26.1"])
     {
     self.sWifiIP = @"192.168.26.";
     self.sSerVerIP =@"192.168.26.1";
     SetIcType = IC_GPRTSP;
     }
     
     if([sPat hasPrefix:@"http://192.168.25.1"])
     {
     self.sWifiIP = @"192.168.25.";
     self.sSerVerIP =@"192.168.25.1";
     SetIcType = IC_GP;
     }
     if([sPat hasPrefix:@"http://192.168.26.1"])
     {
     self.sWifiIP = @"192.168.26.";
     self.sSerVerIP =@"192.168.26.1";
     SetIcType = IC_GP;
     }
     */
    
    
    [self F_StartChecknetWrok:[self.sSerVerIP cStringUsingEncoding: NSUTF8StringEncoding]];
    
    [self F_StartAdjDispFps];
    self.nFrameCount = 0;
    self.nDispFps = 0;
    nFps = 20;
    if(!sPath)
    {
        sPath = @"2";
    }
    self.nErrorFrame = 0;
    nFrame_Count = 0;
    nStartTime = -1;
    
    _nDispWidth = 640;
    _nDispHeight = 360;
    
    self.bStoped = NO;
    self.bCanCheckLink_GKA = NO;
    
    self.nSdStatus = 0;
    self.bVaild = NO;
    self.nVaildT=0;
    self.bStartinit = YES;
    self.bGp_Capturing = NO;
    self.bGp_GetStatusing=NO;
    self.sSSID = [self F_GetSSID];
    self.nHeartbeat=0;
    self.sPath = sPath;
    self.bExit = false;
    [self F_SetChekRelink:80];
    [self F_CheckConnect_AA];
    __weak JH_WifiCamera *weakself = self;
    [weakself F_StratListenat20000];
    
    if(self.nIC_Type == IC_GPRTP|| self.nIC_Type == IC_GPRTPB )
    {
        NSLog(@"Init GPRTP&B....");
        nFps = 20;
        [self createVideoSocket_RTP];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakself F_SetChekRelink:50];
            [weakself InitMediaSN:YES];
            weakself.bIsWifi = YES;
            [weakself doReceiveGPRTP];
            weakself.bOpenOK = YES;
            weakself.nRelinkTime = 0;
            [weakself F_StartCheckConnect];
            [weakself F_SentRTPHeartBeep];
            usleep(1000*5);
            [weakself F_SentRTPHeartBeep];
            //[weakself F_StratListenat20000];
            [weakself F_GP_InitA];
            [weakself F_SetChekRelink:50];
            
        });
        return YES;
    }
    
    if(self.nIC_Type == IC_GPH264A)
    {
        NSLog(@"Init H264A....");
        nFps = 20;
        [self F_SetChekRelink:80];
        //[self F_StratListenat20000];
        [self F_GP_InitA];
        self.bNormalStop=NO;
        self.nSetStream = 1;
        [self InitMediaGKA];
        if([self ConnectGPH264A]<0)
            return NO;
        else
        {
            
            return YES;
        }
    }
    if(self.nIC_Type == IC_SN)
    {
        NSLog(@"Init SN....");
        nFps = 20;
        mIsFirstPacket = NO;
        [self closeVideoSocket];
        [self closeCommandSocket];
        if([self createVideoSocket] == 0)
        {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [weakself createCommandSocket];
                [weakself sendStop];
                weakself.b480 = [weakself F_Getis480P_A];
                if(!weakself.b480)
                {
                    weakself.b480 = [weakself F_Getis480P_A];
                }
                
                NSLog(@" b480P=%d",weakself.b480);
                
                [weakself F_Set480P:weakself.b480];
                [weakself InitMediaSN:weakself.b480];
                
                weakself.bIsWifi = YES;
                [weakself doReceive];
                
                [weakself sendStart];
                weakself.bOpenOK = YES;
                weakself.nRelinkTime = 0;
                [weakself F_StartCheckConnect];
                //[self F_StratListenat20000];
            });
            
            return YES;
        }
        return NO;
    }
    
    if(self.nIC_Type == IC_GKA)
    {
        NSLog(@"Init GKA....");
        nFps = 18;
        _bGKA_ConnOK = NO;
        [self F_SetChekRelink:80];
        self.bNormalStop=NO;
        
        self.nSetStream = 2;
        if(sPath.length>0)
        {
            const char  *sp = [sPath UTF8String];
            if(sp[0]=='0')
                self.nSetStream=0;
            else if(sp[0]=='1')
                self.nSetStream=1;
            else
                self.nSetStream=2;
        }
        
        [self InitMediaGKA];
        if([self Connect_gk]<0)
            return NO;
        else
        {
            //[self F_StratListenat20000];
            return YES;
        }
    }
    // 以上都用到私有协议处理。
    
    if(self.nIC_Type == IC_GK)              //RTSP 或者 Http Mj
    {
        [self F_StratListenat8001];
    }
    
    if(self.nIC_Type == IC_GPRTSP || self.nIC_Type == IC_GPH264 )
    {
        //[self F_StratListenat20000];
        [self F_GP_InitA];
        [self F_SetChekRelink:60]; //uint 100ms
        NSLog(@"Init GPRTSP&H264....");
    }
    
    NSLog(@"Init GPHTTP....");
    BOOL res = [self initMedia];
    if(res)
    {
        [self F_SetChekRelink:40];
        [self naPlay_A];
    }
    else
    {
        [self F_SetChekRelink:5];
    }
    return res;
}


-(BOOL)naSentHartBeat
{
    Byte cmd[100];
    self.nHeartbeat++;
    cmd[0]= (Byte)self.nHeartbeat;
    cmd[1]= (Byte)(self.nHeartbeat>>8);
    cmd[2]= (Byte)(self.nHeartbeat>>16);
    cmd[3]= (Byte)(self.nHeartbeat>>24);
    NSData *data = [NSData dataWithBytes:cmd length:4];
    //[self.Udp_SendSocket sendData:data toHost:@"192.168.234.1" port:8001 withTimeout:15 tag:0];
    [self F_SentUdp:data Server:self.sSerVerIP Port:8001];
    return YES;
}


-(void)naRotation:(int)n
{
    
    _nRota=n;
    
    if(self.dispView)
    {
        [self.dispView SetRotation:_nRota];
    }
}
-(BOOL)naSentCmd:(NSData *)data
{
    Byte cmd[100];
    NSUInteger n = data.length;
    Byte *pdata = (Byte *)[data bytes];
    if(self.nIC_Type == IC_GKA)
    {
        if(_bGKACmd_UDP)
        {
            T_NET_UTP_PTZ_CONTROL  udp;
            
            udp.seq=1;
            udp.sid = self.session_id;
            udp.flag = 0x12345678;
            udp.size = (int)n;
            memcpy(udp.ptz_cmd,pdata,n);
            
            NSData *dat = [NSData dataWithBytes:&udp length:sizeof(T_NET_UTP_PTZ_CONTROL)];
            [self F_SentUdp:dat Server:self.sSerVerIP Port:0x7105];
        }
        else
        {
            if(_bGKA_ConnOK)
            {
                T_NET_CMD_MSG Cmd;
                Cmd.type=CMD_PTZ_CONTROL;
                Cmd.session_id = self.session_id;
                NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
                T_NET_PTZ_CONTROL  ptz;
                if(data.length>32)
                {
                    return NO;
                }
                ptz.size =(uint32_t)data.length;
                memcpy(ptz.ptz_cmd, [data bytes], data.length);
                NSData *data = [NSData dataWithBytes:&ptz length:sizeof(T_NET_PTZ_CONTROL)];
                [sendData appendData:data];
                [self.GKA_Cmd_Socket Write:sendData];
            }
        }
    }
    else if(self.nIC_Type == IC_GK)
    {
        
        int i = 0;
        int x = 0;
        NSUInteger n = [data length];
        cmd[i++] = 0x5b;
        cmd[i++] = 0x52;
        cmd[i++] = 0x74;
        cmd[i++] = 0x3e;
        cmd[i++] = (Byte)(12 + n);
        cmd[i++] = (Byte)((12 + n)>>8);
        cmd[i++] = 1;
        cmd[i++] = 0;
        cmd[i++] = 0xe0;
        cmd[i++] = 0x00;
        cmd[i++] = 0;  //10
        cmd[i++] = 0;          //11
        
        for (x = 0; x < n; x++) {
            cmd[i++] = pdata[x];
        }
        
        
        uint16_t checksum = 0;
        for (x = 0; x < i; x++) {
            checksum += cmd[x];
        }
        while ((checksum >> 8) != 0) {
            checksum = (checksum & 0xFF) + (checksum >> 8);
        }
        cmd[10] = (uint8_t) (checksum ^ 0x00FF);
        NSData *dat = [NSData dataWithBytes:cmd length:i];
        [self send_cmd_gk_udp:dat];
    }
    else if(self.nIC_Type == IC_SN)
    {
        cmd[0]=0xA5;
        cmd[1]=0x5A;
        cmd[2]=n+2;
        int x = 0;
        for (x = 0; x < n; x++) {
            if(x<40)
                cmd[x+3] = pdata[x];
        }
        uint16_t ncheck = 0;
        for(int i=0;i<n+3;i++)
        {
            ncheck +=cmd[i];
        }
        cmd[n+3]= (uint8_t)ncheck;
        cmd[n+4]= (uint8_t)(ncheck>>8);
        NSData *dat = [NSData dataWithBytes:cmd length:n+5];
        [self F_SendUDP_SN:dat];
    }
    //if(self.nIC_Type == IC_GP || self.nIC_Type == IC_GPRTSP || self.nIC_Type == IC_GPH264 || self.nIC_Type == IC_GPRTP || self.nIC_Type == IC_GPRTPB || self.nIC_Type == IC_GPH264A)
    else
    {
        NSUInteger n = [data length];
        cmd[0]=0xA5;
        cmd[1]=0x5A;
        cmd[2]=n+2;
        int x = 0;
        for (x = 0; x < n; x++) {
            if(x<40)
                cmd[x+3] = pdata[x];
        }
        uint16_t ncheck = 0;
        for(int i=0;i<n+3;i++)
        {
            ncheck +=cmd[i];
        }
        cmd[n+3]= (uint8_t)ncheck;
        cmd[n+4]= (uint8_t)(ncheck>>8);
        NSData *dat = [NSData dataWithBytes:cmd length:n+5];
        [self send_cmd_gp_udp:dat];
    }
    
    return YES;
}

-(void)F_SentUdp:(NSData *)dat Server:(NSString *)sServer Port:(int)nPort
{
    if(sServer==nil)
        return;
    int clientSocketId;
    ssize_t len;
    socklen_t addrlen;
    struct sockaddr_in client_sockaddr;
    // 第一步：创建Socket
    clientSocketId = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(clientSocketId < 0) {
        NSLog(@"creat client socket fail\n");
        return;
    }
    
    int set = 1;
    setsockopt(clientSocketId, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
    
    int err=0;
    addrlen = sizeof(struct sockaddr_in);
    bzero(&client_sockaddr, addrlen);
    client_sockaddr.sin_len = sizeof(client_sockaddr);
    client_sockaddr.sin_family = AF_INET;
    client_sockaddr.sin_addr.s_addr = inet_addr([sServer UTF8String]);
    client_sockaddr.sin_port = htons(nPort);
    len = sendto(clientSocketId, [dat bytes], dat.length, 0, (struct sockaddr *)&client_sockaddr, addrlen);
    if (len > 0)
    {
        ;
    } else {
        err = errno;
        // NSLog(@"发送失败a errno=%d %@",err,sServer);
    }
    close(clientSocketId);
}

-(void)F_SendUDP_SN:(NSData *)dat
{
    [self F_SentUdp:dat Server:self.sSerVerIP Port:30864];
}


-(void)send_cmd_gk_udp:(NSData *)data
{
    //[self.Udp_SendSocket sendData:data toHost:@"192.168.234.1" port:9001 withTimeout:15 tag:0];
    [self F_SentUdp:data Server:self.sSerVerIP Port:9001];
}


-(void)send_cmd_gp_udp:(NSData *)data
{
    [self F_SentUdp:data Server:self.sSerVerIP Port:25000];
    
}


-(int)naPlay
{
    return 0;
}
-(int)naPlay_A
{
    if(self.nIC_Type == IC_GKA)
    {
        return 0;
    }
    
    if(self.bPlaying)
        return -1;
    if(self.nIC_Type == IC_SN)
    {
        
        self.bPlaying = YES;
        [self F_SetChekRelink:40];
        {
            [self F_CheckStatusA];
        }
        return 0;
    }
    if(m_formatCtx==NULL)
    {
        BOOL re  = [self naInit:self.sPath];
        if(!re)
            return -2;
    }
    self.bPlaying = YES;
    
    [self F_SetTimeout:0];
    self.bNormalStop=NO;
    __weak JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        [weakself DecordData_ffmpeg];
    });
    [self F_SetChekRelink:40]; //4Sec
    if(self.nIC_Type != IC_GPRTSP && self.nIC_Type != IC_GPH264)
        [self F_CheckStatusA];
    [self F_SetChekRelink:40];
    return 0;
}



-(void)F_CheckConnect_AA
{
    
#ifdef D_Check_Relinker
    
    __weak JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL  bRelink = false;
        while(weakself.bCanCheckRelink)
        {
            if(weakself.bStartinit)
            {
                {
                    if(weakself.bCheckLink)
                    {
                        [weakself.packetLock lock];
                        {
                            weakself.nRelinkTime++;
                            
                            if(weakself.nRelinkTime==0)
                            {
                                weakself.nRelinkTime = 0xFFFF;
                            }
                        }
                        [weakself.packetLock unlock];
                        if(weakself.nRelinkTime>(weakself.nRelinkTime_Set*10) &&  !weakself.bStoped)
                        {
                            NSLog(@"");
                            NSLog(@"Start ReLink....1.....!");
                            weakself.nRelinkTime = 0;
                            weakself.bCanCheckRelink = NO;
                            if(weakself.nRelinkTime_Set!=0)
                                bRelink = YES;
                            break;
                        }
                    }
                }
            }
            usleep(1000*10);
        }
        if(bRelink)
        {
            NSLog(@"Exit check ReLink! and  Go Relink!!!!");
            self.nReLinkABC++;
            [weakself naStop_2ReLink];
        }
        else{
            NSLog(@"Exit check ReLink!");
        }
        
    });
#endif
}



-(void)naStop_2ReLink
{
    self.bStoped = NO;
    self.bStartinit = NO;
    self.nRelinkTime = 0;
    self.nRelinkTime_Set = 60;
    self.bCanCheckRelink = NO;
    self.bNeedStop2Relink = YES;
    [self StopABC];
}

-(void)naStop
{
    self.nRelinkTime_Set=0;
    self.bStoped = YES;
    self.nRelinkTime = 0;
    self.bCanCheckRelink = NO;
    self.bStartinit=NO;
    {
        self.bNeedStop2Relink = NO;
        NSLog(@"naStop!!!");
        [self StopABC];
        _nDispFps = 0;
        _nFrameCount = 0;
    }
}

-(void)naSetGKA_SentCmdByUDP:(BOOL)bUDP
{
    self.bGKACmd_UDP = bUDP;
}

-(void)StopABC
{
    
    @synchronized (self) {
        _bRead20000 = NO;
        usleep(1000*50);
        if(_socket_udp20000>0)
        {
            close(_socket_udp20000);
            _socket_udp20000=-1;
        }
        if(_socket_udp8001>0)
        {
            close(_socket_udp8001);
            _socket_udp8001=-1;
        }
        self.bCanCheckLink_GKA = NO;
        self.bStartinit = NO;
        self.bNormalStop=YES;
        self.bExitReLink = YES;
        if(self.nIC_Type == IC_GKA
           || self.nIC_Type == IC_GPRTSP
           || self.nIC_Type == IC_GPH264
           || self.nIC_Type == IC_GPRTP
           || self.nIC_Type == IC_SN
           || self.nIC_Type == IC_GPRTPB
           || self.nIC_Type == IC_GPH264A)
        {
            
            [self stopReceive];
            usleep(1000*15);
            [self closeVideoSocket];
            //[self  naStopSaveVideo];
            [self DisConnect];
            self.bPlaying = NO;
            self.bGKA_Start = NO;
            self.bisPlayGKA=NO;
            [self F_SetTimeout:5];
            bDisping = NO;
            _bNeedSave2Photo = NO;
            _bSaveCompelete = YES;
            [self F_SetTimeout:2];
            __weak  JH_WifiCamera  *weakself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_global_queue(0,0), ^{
                if(weakself.bStoped)
                {
                    [weakself  naStopSaveVideo];
                    
                    [weakself Releaseffmpeg];
                    
                    weakself.bConnectedOK = NO;
                    [weakself  F_DispBack:weakself.dispBackImg];
                }
                else
                {
                    weakself.nFlag = 0;
                    
                    weakself.bConnectedOK = NO;
                    if(!weakself.bNeedStop2Relink)
                    {
                        [weakself  naStopSaveVideo];
                        [weakself Releaseffmpeg];
                        [weakself  F_DispBack:weakself.dispBackImg];
                    }
                    else
                    {
                        NSLog(@"");
                        NSLog(@"");
                        NSLog(@"Start ReLink....2.....!");
                        [weakself Releaseffmpeg];
                        weakself.bCanWrite = NO;
                        weakself.bNeedStop2Relink = NO;
                        weakself.nRelinkTime = 0;
                       // self.bRealRec = NO;
                        [weakself naInit:self.sPath];
                    }
                }
            });
            return;
        }
        [self F_GP_StopGetStatus];
        [self.gpCmd_Socket DisConnect];
        
        
        // [self.Tcp_SendSocket disconnect];
        [self naStopSaveVideo];
        [self F_SetTimeout:1];
        if(self.bPlaying)
        {
            self.bPlaying = NO;
        }
        else
        {
            if(self.bOpenOK)
            {
                self.bOpenOK = NO;
            }
        }
        bDisping = NO;
        [self naStartCheckSDStatus:NO];
        _bNeedSave2Photo = NO;
        _bSaveCompelete = YES;
        {
            __weak  JH_WifiCamera  *weakself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(0,0), ^{
                weakself.nFlag = 2;
                [weakself Releaseffmpeg];
                weakself.bConnectedOK = NO;
                if(!weakself.bNeedStop2Relink)
                    [weakself  F_DispBack:weakself.dispBackImg];
            });
        }
        // [self.videoFrames_bak removeAllObjects];
    }
    
}

-(void)F_CheckStatus_GK
{
    NSString *sUrl= [NSString stringWithFormat:@"%@/web/cgi-bin/hi3510/getsdcareInfo.cgi?",HTTP_SERVER];
    [self F_SendCommand:sUrl Type:Type_GetSD_Status];
    if(self.bIsWifi)
    {
        self.nSdStatus |= Status_Connected;
    }
    else
    {
        self.nSdStatus &= (Status_Connected^0xFFFF);
    }
    
    if(self.bRecroding)
    {
        self.nSdStatus |= LocalRecording;
    }
    else
    {
        self.nSdStatus &= (LocalRecording^0xFFFF);
    }
    
}

-(void)F_CheckStatus_GPRTSP
{
    
}
-(void)F_CheckStatus_GP
{
    if(self.bRecroding)
    {
        self.nSdStatus |= LocalRecording;
    }
    else
    {
        self.nSdStatus &= (LocalRecording^0xFFFF);
    }
    if(self.bIsWifi)
    {
        self.nSdStatus |= Status_Connected;
    }
    else
    {
        self.nSdStatus &= (Status_Connected^0xFFFF);
    }
}

-(void)F_CheckStatus
{
    
    if(self.nIC_Type == IC_GK)
    {
        [self F_CheckStatus_GK];
    }
    else if(self.nIC_Type == IC_GP)
    {
        [self F_CheckStatus_GP];
    }
    else if(self.nIC_Type == IC_GPRTSP)
    {
        [self F_CheckStatus_GPRTSP];
    }
    else if(self.nIC_Type == IC_GPH264)
    {
        [self F_CheckStatus_GPRTSP];
    }
    
    else if(self.nIC_Type == IC_SN)
    {
        [self F_CheckStatus_GP];
    }
    else if(self.nIC_Type == IC_GKA)
    {
        NSLog(@"Not Support CheckStatus");
        //return;
    }
    [self F_SentStatus];
    
    
    
}



-(void)F_CheckStatusA
{
    [self F_CheckStatus];
    __weak JH_WifiCamera *weakself = self;
    const NSTimeInterval time = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_global_queue(0,0), ^(void){
        if(weakself.bStartCheckStatus)
        {
            if(weakself.nCheckStat>0)
            {
                weakself.nCheckStat--;
                if(weakself.nCheckStat!=0)
                    [weakself F_CheckStatusA];
                else
                {
                    weakself.bStartCheckStatus = NO;
                }
            }
            else
            {
                [weakself F_CheckStatusA];
            }
        }
    });
    
}

-(int)naStartCheckSDStatus:(BOOL) bStart
{
    if(self.nIC_Type == IC_SN)
        return 0;
    if(bStart)
    {
        if(!self.bStartCheckStatus)
        {
            self.bStartCheckStatus = bStart;
            self.nCheckStat = 30;
            [self F_CheckStatusA];
        }
    }
    self.bStartCheckStatus = bStart;
    return 0;
}


-(int)naSaveSnapshot:(NSString *)strpath
{
    self.sSavePathPhoto = strpath;
    return [self naSaveSnapshot];
}

-(int)naSaveSnapshot  // (String pFileName);
{
    if(!self.bPlaying)
        return -1;
    self.bNeedSave2Photo = YES;
    [self F_SavePhoto:nil];
    return 0;
}

-(int)naStartSaveVideo_A:(NSString *)sPath
{
    
    [self naSaveVideo:sPath];
    if((self.nSdStatus & SD_Recording) == 0)
    {
        if((self.nSdStatus & SD_Ready) != 0)
            [self naRemoteSaveVideo];
    }
    return 0;
}

-(int) naStopSaveVideo_A
{
    [self naStopSaveVideo];
    if((self.nSdStatus & SD_Recording) != 0)
    {
        [self naRemoteSaveVideo];
    }
    return 0;
}


-(int)_naSaveVideo:(NSString *)sPath
{
    if(self.bRecroding)
    {
        return -1;
    }
    if(!self.bPlaying)
        return -1;
    
    self.sSavePath = sPath;
    self.bRecroding = YES;
    if(_bG_Audio)
    {
        [self F_StartAudio:YES];
    }
    [self StartSaveVideo];
    self.nSdStatus |=LocalRecording;
  //  self.bRealRec = YES;
    [self F_SentStatus];
    NSLog(@"Start Record 1");
    return 0;
}

-(int)naSaveVideo:(NSString *)sPath
{
    
#if 1
    return [self _naSaveVideo:sPath];
#else
    if(self.bRecroding)
    {
        return -1;
    }
    if(!self.bPlaying)
        return -1;
    
    self.sSavePath = sPath;
    self.bRecroding = YES;
    [self StartSaveVideo];
    self.nSdStatus |=LocalRecording;
    [self F_SentStatus];
    NSLog(@"Start Record 2");
    return 0;
#endif
    
}
-(int)naSaveVideo
{
    return [self naSaveVideo:nil];
}

-(int) naStopSaveVideo
{
    //self.bRealRec = NO;
    if(!self.bRecroding)
    {
        return -1;
    }
    self.bRecroding = NO;
    [self StopSaveVideo];
    [self F_StartAudio:NO];
    self.nSdStatus &=(LocalRecording^0xFFFF);
    [self F_SentStatus];
    return 0;
}


-(int)naRemoteSnapshot
{
    __weak JH_WifiCamera *weakself = self;
    if(self.nIC_Type == IC_GKA)
    {
        if(self.session_id<=0)
            return -1;
        return [self F_SD_Snap];
    }
    else if(self.nIC_Type == IC_GK)
    {
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSString *sUrl= [NSString stringWithFormat:@"%@/web/cgi-bin/hi3510/snap.cgi?&-getpic&-chn=0",HTTP_SERVER];
            [weakself F_SendCommand:sUrl Type:Type_GetSD_Photo];
        });
        return 0;
    }
    else if(self.nIC_Type == IC_GP)
    {
        if(self.nSdStatus & SD_Ready)
        {
            dispatch_async(dispatch_get_global_queue(0,0), ^{
                if(!weakself.bGp_Capturing)
                {
                    weakself.bGp_Capturing = YES;
                    [weakself F_GP_SetMode:1];
                    usleep(10000);
                    [weakself F_GP_Capture];
                    usleep(10000);
                    weakself.bGp_Capturing = NO;
                    //[weakself F_GP_RestartStreaming];
                    //usleep(20000);
                    //[weakself F_GP_SetMode:0];
                    //usleep(5000);
                }
            });
            
            return 0;
        }
        return -1;
    }
    else  if(self.nIC_Type == IC_GPRTSP)
    {
        Byte cmd[7];
        cmd[0]='J';
        cmd[1]='H';
        cmd[2]='C';
        cmd[3]='M';
        cmd[4]='D';
        cmd[4]='D';
        cmd[5]=0x00;
        cmd[6]=0x01;
        NSData *data = [[NSData  alloc] initWithBytes:cmd length:7];
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        return 0;
    }
    else if(self.nIC_Type == IC_GPH264)
    {
        Byte cmd[7];
        cmd[0]='J';
        cmd[1]='H';
        cmd[2]='C';
        cmd[3]='M';
        cmd[4]='D';
        cmd[4]='D';
        cmd[5]=0x00;
        cmd[6]=0x01;
        NSData *data = [[NSData  alloc] initWithBytes:cmd length:7];
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        return 0;
    }
    else
    {
        return -100;
    }
    
}

-(int)naStartRemoteRec
{
    if(!self.bConnectedOK)
        return -1;
    if(self.nIC_Type == IC_GPRTSP)
    {
        //if(self.nSdStatus_GP & 0x0100)
        //    return 1;
        Byte cmd[7];
        cmd[0]='J';
        cmd[1]='H';
        cmd[2]='C';
        cmd[3]='M';
        cmd[4]='D';
        cmd[4]='D';
        cmd[5]=0x00;
        cmd[6]=0x02;
        NSData *data = [[NSData  alloc] initWithBytes:cmd length:7];
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    }
    else if(self.nIC_Type == IC_GPH264)
    {
        //if(self.nSdStatus_GP & 0x0100)
        //    return 1;
        Byte cmd[7];
        cmd[0]='J';
        cmd[1]='H';
        cmd[2]='C';
        cmd[3]='M';
        cmd[4]='D';
        cmd[4]='D';
        cmd[5]=0x00;
        cmd[6]=0x02;
        NSData *data = [[NSData  alloc] initWithBytes:cmd length:7];
        [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    }
    else if(self.nIC_Type == IC_GKA)
    {
        if(self.nSdStatus & SD_Recording)
        {
            return 1;
        }
        return [self F_SD_Start_Recrod];
    }
    else
    {
        if(self.nSdStatus & SD_Recording)
        {
            return 1;
        }
        else
        {
            [self naRemoteSaveVideo];
        }
    }
    return -1;
}

-(int)naStopRemoteRec
{
    if(self.nIC_Type == IC_GPRTSP)
    {
        //if((self.nSdStatus_GP & 0x0100))
        {
            Byte cmd[7];
            cmd[0]='J';
            cmd[1]='H';
            cmd[2]='C';
            cmd[3]='M';
            cmd[4]='D';
            cmd[5]=0x00;
            cmd[6]=0x03;
            NSData *data = [[NSData alloc] initWithBytes:cmd length:7];
            [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        }
    }
    else if(self.nIC_Type == IC_GPH264)
    {
        //if((self.nSdStatus_GP & 0x0100))
        {
            Byte cmd[7];
            cmd[0]='J';
            cmd[1]='H';
            cmd[2]='C';
            cmd[3]='M';
            cmd[4]='D';
            cmd[5]=0x00;
            cmd[6]=0x03;
            NSData *data = [[NSData alloc] initWithBytes:cmd length:7];
            [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
        }
    }
    else if(self.nIC_Type == IC_GKA)
    {
        return [self F_SD_Stop_Recrod];
    }
    else
    {
        if(self.nSdStatus & SD_Recording)
        {
            [self naRemoteSaveVideo];
        }
    }
    return -1;
}


-(int)naRemoteSaveVideo
{
    __weak JH_WifiCamera *weakself = self;
    if((self.nSdStatus & SD_Ready) == 0)
    {
        return -1;
    }
    if(self.nIC_Type == IC_GP)
    {
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            [weakself F_GP_SetMode:0];
            usleep(5000);
            [weakself F_GP_Record_Cmd];
        });
    }
    else
    {
        
        
        dispatch_async(dispatch_get_global_queue(0,0), ^{
            NSString *sUrl= [NSString stringWithFormat:@"%@/web/cgi-bin/hi3510/switchrec.cgi?-chn=11",HTTP_SERVER];
            [weakself F_SendCommand:sUrl Type:Type_GetSD_Record];
        });
    }
    
    return 0;
}


-(int)naStartRecord_All:(NSString *)spath
{
    if(!self.bConnectedOK)
        return -1;
    [self  naSaveVideo:spath];
    if((self.nSdStatus & SD_Recording) == 0)
    {
        if(self.nSdStatus & SD_Ready)
        {
            [self  naStartRemoteRec];
        }
    }
    return 0;
}

-(void)naStopRecord:(TYPE_SNAP_REC)nType
{
    if(nType == TYPE_ONLY_PHONE)
    {
        [self  naStopSaveVideo];
    }
    else if(nType == TYPE_ONLY_SD)
    {
        // if((self.nSdStatus & SD_Recording))
        [self  naStopRemoteRec];
    }
    else
    {
        //if((self.nSdStatus & SD_Recording))
        [self  naStopRemoteRec];
        [self  naStopSaveVideo];
    }
}

-(int)naStopRecord_All
{
    if(self.nIC_Type == IC_GPRTSP || self.nIC_Type == IC_GPH264 )
    {
        //if(self.nSdStatus_GP & 0x0400)
        {
            [self  naStopRemoteRec];
        }
    }
    else
    {
        //if((self.nSdStatus & SD_Recording))
        [self  naStopRemoteRec];
    }
    [self  naStopSaveVideo];
    return 0;
}




-(void)F_SendCommand:(NSString *)sCmd  Type:(int)nType
{
    //__weak JH_WifiCamera *weakself = self;
    self.nHttpType |=nType;
    NSString *strurl = sCmd;
    NSURL *url = [NSURL URLWithString:strurl];
    NSError *error = nil;
    NSURLResponse *response = nil;
    NSURLRequest  *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:0.8];
    NSData  *data =  [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if(!error && data)
    {
        NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if((self.nHttpType & Type_GetSD_Status) !=0)
        {
            //NSLog(@"%@",responseString);
            NSArray *list=[responseString componentsSeparatedByString:@";"];
            if(list.count>0)
            {
                
                NSString *sdstatus = list[0];
                //NSLog(sdstatus);
                if( [sdstatus compare:@"sdstatus=\"Ready\""] == NSOrderedSame)
                {
                    self.nCheckStat=1;
                    self.nSdStatus |= SD_Ready;
                    self.nSdStatus &= (SD_Recording^0xFFFF);
                    
                }
                else if([sdstatus compare:@"sdstatus=\"Recing\""] == NSOrderedSame  || [sdstatus compare:@"var rec=ok"] == NSOrderedSame || [sdstatus compare:@"var rec=on"] == NSOrderedSame || [sdstatus compare:@"var rec=off"] == NSOrderedSame)
                {
                    self.nSdStatus |= SD_Ready;
                    self.nSdStatus |= SD_Recording;
                    
                }
                else
                {
                    self.nSdStatus &= (SD_Ready^0xFFFF);
                    self.nSdStatus &= (SD_Recording^0xFFFF);
                    
                }
                if(list.count<5)
                {
                    self.nCheckStat=0;
                }
            }
            
        }
    }
    
    if((self.nHttpType & Type_GetSD_Status) !=0)
    {
        self.nHttpType &= (Type_GetSD_Status ^0xFF);
    }
    if((self.nHttpType & Type_GetSD_Record) !=0)
    {
        self.nHttpType &= (Type_GetSD_Record ^0xFF);
    }
    if((self.nHttpType & Type_GetSD_Photo) !=0)
    {
        self.nHttpType &= (Type_GetSD_Photo ^0xFF);
    }
    
}



#pragma mark  播放线程

-(UIImage *)naGetThumbnail:(NSString *)str
{
    self.bSNT = YES;
    self.bSetpause = NO;
    self.sPath = str;
    self.imageView = nil;
    
    _nDispWidth = 640;
    _nDispHeight = 360;
    if([self initMedia])
    {
        self.bPlaying = YES;
        [self DecordData_ffmpeg];
        UIImage *img = self.imgSNT;
        self.imgSNT = nil;
        return img;
    }
    else
        return nil;
}



-(void)Releaseffmpeg
{
    //@synchronized (self)
    {
        NSLog(@"Flag = %d",self.nFlag);
        NSLog(@"Release FFmpeg data!!!!!");
        self.bPlaying = NO;
        bDisping = NO;
        self.bIsWifi = NO;
        bInitEncodeBMP = NO;
        
        if(m_formatCtx!=NULL)
        {
            @try {
                avformat_close_input(&m_formatCtx);
                avformat_free_context(m_formatCtx);
                m_formatCtx = NULL;
            } @catch (NSException *exception) {
                ;
            } @finally {
                ;
            }
            m_formatCtx = NULL;
            m_codecCtx = NULL;
            
        }
        else
        {
            
            if(m_codecCtx!=NULL)
            {
                avcodec_close(m_codecCtx);
                avcodec_free_context(&m_codecCtx);
                m_codecCtx = NULL;
            }
        }
        
        
        
        if(m_codecCtx!=NULL)
        {
            avcodec_close(m_codecCtx);
            //avcodec_free_context(&m_codecCtx);
            m_codecCtx = NULL;
        }
        
        if(m_parser!=NULL)
        {
            av_parser_close(m_parser);
            m_parser = NULL;
        }
        
        
        
        if(m_decodedFrame != NULL)
        {
            av_frame_free(&m_decodedFrame);
            m_decodedFrame = NULL;
        }
        
        
        if(img_convert_ctx!=NULL)
        {
            sws_freeContext(img_convert_ctx);
            img_convert_ctx = NULL;
        }
        if(img_convert_ctxBmp!=NULL)
        {
            sws_freeContext(img_convert_ctxBmp);
            img_convert_ctxBmp = NULL;
        }
        if(img_convert_ctx_half!=NULL)
        {
            sws_freeContext(img_convert_ctx_half);
            img_convert_ctx_half = NULL;
        }
        
        
        /*
         if(img_convert_ctx_Rec!=NULL)
         {
         sws_freeContext(img_convert_ctx_Rec);
         img_convert_ctx_Rec = NULL;
         }
         */
        
        if(pFrameYUV!=NULL)
        {
            av_freep(&pFrameYUV->data[0]);
            av_frame_free(&pFrameYUV);
            pFrameYUV = NULL;
        }
        if(frame_a!=NULL)
        {
            av_freep(&frame_a->data[0]);
            av_frame_free(&frame_a);
            frame_a = NULL;
        }
        if(frame_b!=NULL)
        {
            av_freep(&frame_b->data[0]);
            av_frame_free(&frame_b);
            frame_b = NULL;
        }
        /*
         if(My_EncodecodecCtx!=NULL)
         {
         avcodec_close(My_EncodecodecCtx);
         avcodec_free_context(&My_EncodecodecCtx);
         My_EncodecodecCtx = NULL;
         }
         */
        NSLog(@"Exit PlayB...");
    }
}
#pragma mark  RTSP 初始化

-(BOOL)isPlaying
{
    return self.bPlaying;
}

-(BOOL)isPhoneRecording
{
    return self.bRecroding;
}

-(void)frame_link2frame:(AVFrame *)src DES:(AVFrame*)des
{
    
    
    int i= 0;
    int hw = src->width>>1;
    int hh = src->height>>1;
    
    int deshw = des->width>>1;
    
    Byte *pdes;
    Byte *pdes1;
    Byte *psrc;
    Byte *psrc1;
    
    pdes=(Byte *)(des->data[0]);
    psrc =(Byte *)(src->data[0]);
    
    Byte *srcp;
    Byte *desp;
    
    int ha = des->height/4;
    
    if(!_bWhite)
    {
        memset(des->data[0],16,des->width*des->height);
        memset(des->data[1],128,des->width*des->height/4);
        memset(des->data[2],128,des->width*des->height/4);
    }
    else
    {
        memset(des->data[0],255,des->width*des->height);
        memset(des->data[1],128,des->width*des->height/4);
        memset(des->data[2],128,des->width*des->height/4);
    }
    
    
    int dat = ha*des->width;
    
    pdes+=dat;
    for (i = 0; i < src->height; i++)
    {
        
        memcpy(pdes,psrc,src->width-1);
        memcpy(pdes+src->width,psrc,src->width);
        pdes+=des->width;
        psrc+=src->width;
        
        
    }
    ha = des->height/8;
    pdes =(Byte *)des->data[1];
    psrc =(Byte *)src->data[1];
    
    pdes1 = (Byte *)des->data[2];
    psrc1 =(Byte *)src->data[2];
    for (i = 0; i < hh; i++)
    {
        
        srcp = psrc+i*hw;
        desp = pdes+(i+ha)*deshw;
        memcpy(desp,srcp,hw-1);
        memcpy(desp+hw,srcp,hw);
        srcp = psrc1+i*hw;
        desp = pdes1+(i+ha)*deshw;
        memcpy(desp,srcp,hw-1);
        memcpy(desp+hw,srcp,hw);
    }
    
}

/*
 -(void)frame_rotate_180:(AVFrame *)src DesFrame:(AVFrame*)des
 {
 int i= 0;
 int hw = src->width>>1;
 int hh = src->height>>1;
 int pos= src->width * src->height;
 pos--;
 Byte *pdes;
 Byte *pdes1;
 Byte *psrc;
 Byte *psrc1;
 
 pdes=(Byte *)des->data[0];
 psrc =(Byte *)(&src->data[0][pos]);
 for (i = 0; i < src->height; i++)
 {
 for (int j = 0; j < src->width; j++) {
 *(pdes++)=*(psrc--);
 }
 }
 //n = 0;
 pos = src->width * src->height>>2;
 pos--;
 
 pdes =(Byte *)des->data[1];
 pdes1 =(Byte *)des->data[2];
 
 psrc =(Byte *)(&src->data[1][pos]);
 psrc1 =(Byte *)(&src->data[2][pos]);
 for (i = 0; i < hh;i++)
 {
 for (int j = 0; j < hw;j++)
 {
 *(pdes++)= *(psrc--);
 *(pdes1++)= *(psrc1--);
 }
 }
 
 des->linesize[0] = src->width;
 des->linesize[1] = src->width>>1;
 des->linesize[2] = src->width>>1;
 
 des->width = src->width;
 des->height = src->height;
 des->format = src->format;
 
 des->pts = src->pts;
 //des->pkt_pts = src->pkt_pts;
 des->pkt_dts = src->pkt_dts;
 des->key_frame = src->key_frame;
 }
 */
-(UIImage *)YUVtoUIImage:(AVFrame *)myframe1 SAVE:(BOOL)bsave{
    
    int w = myframe1->width;
    int h = myframe1->height;
    AVFrame *myframe = av_frame_alloc();
    myframe->width=w;
    myframe->height=h;
    av_image_alloc(myframe->data, myframe->linesize, w,h,AV_PIX_FMT_YUV420P,4);
    
    if(bsave && self.dispView && self.dispView.nDispStyle !=0)
    {
        uint8 *pbufferA =(uint8 *) malloc(w*4*h);
        uint8 *pbuffer = pbufferA;
        memset(pbuffer,0,w*4*h);
        I420ToABGR(myframe1->data[0], myframe1->linesize[0],
                   myframe1->data[1], myframe1->linesize[1],
                   myframe1->data[2], myframe1->linesize[2],
                   pbuffer,w*4,
                   w,h);
        RGBA_STRUCT df = {0,0,0,0};
        int nDispStyle = self.dispView.nDispStyle;
        {
            int r,g,b;
            if (nDispStyle == 2) {
                df.r = 255;
                df.g = 0;
                df.b = 0;
                df.a = 20; //= {255, 0, 0, 20};
            } else if (nDispStyle == 3) {
                df.r = 255;
                df.g = 255;
                df.b = 0;
                df.a = 20; // {255, 255, 0, 20};
            } else if (nDispStyle == 4) {
                df.r = 0;
                df.g = 255;
                df.b = 0;
                df.a = 20; // {0, 255, 0, 20};
            } else if (nDispStyle == 5) {
                df.r = 128;
                df.g = 69;
                df.b = 9;
                df.a = 50; // {128, 69, 9, 50};
            }
            else if (nDispStyle == 6) {
                df.r = 0;
                df.g = 0;
                df.b = 255;
                df.a = 20; //{0, 0, 255, 20};
            }
            
            RGBA_STRUCT *buffer;
            uint8 dat =0;
            float ap = df.a/100.0f;
            for(int y=0;y<h;y++)
            {
                for(int x=0;x<w;x++)
                {
                    buffer =(RGBA_STRUCT *)pbuffer;
                    if(nDispStyle==1)
                    {
                        dat =(uint8) (((*buffer).r*38 + (*buffer).g*75 + (*buffer).b*15) >> 7);
                        (*buffer).r = dat;
                        (*buffer).g = dat;
                        (*buffer).b = dat;
                    }
                    else {
                        
                        r = (int) (ap * df.r + (1 - ap) * (*buffer).r);
                        g = (int) (ap * df.g + (1 - ap) * (*buffer).g);
                        b = (int) (ap * df.b + (1 - ap) * (*buffer).b);
                        
                        if(r>255)
                        r = 255;
                        if(r<0)
                        r=0;
                        if(g>255)
                        g = 255;
                        if(g<0)
                        g=0;
                        if(b>255)
                        b = 255;
                        if(b<0)
                        b=0;
                        (*buffer).r = (uint8)r;
                        (*buffer).g = (uint8)g;
                        (*buffer).b = (uint8)b;
                    }
                    pbuffer+=4;
                }
            }
            pbuffer = pbufferA;
            ABGRToI420((uint8_t *) pbuffer, myframe1->width * 4,
                                     myframe1->data[0], myframe1->linesize[0],
                                     myframe1->data[1], myframe1->linesize[1],
                                     myframe1->data[2], myframe1->linesize[2],
                                     myframe1->width, myframe1->height);
            
        }
        free(pbufferA);
    }
    
    I420ToNV12(myframe1->data[0], myframe1->linesize[0],
               myframe1->data[1], myframe1->linesize[1],
               myframe1->data[2], myframe1->linesize[2],
               myframe->data[0], myframe->linesize[0],
               myframe->data[1], myframe->linesize[1]*2,
               w,h);
    
    
    CVPixelBufferRef pixelBufferA = NULL;
    OSType KVideoPixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    CVReturn result = CVPixelBufferCreate(NULL, w, h, KVideoPixelFormatType, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBufferA);
    if (result != kCVReturnSuccess) {
        NSLog(@"Unable to create cvpixelbuffer %d", result);
        return nil;
    }
    
    CVPixelBufferLockBaseAddress(pixelBufferA,0);
    unsigned char *yDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBufferA, 0);
    memcpy(yDestPlane,myframe->data[0],myframe->linesize[0]*h);
    unsigned char *uvDestPlane = CVPixelBufferGetBaseAddressOfPlane(pixelBufferA, 1);
    memcpy(uvDestPlane, myframe->data[1],w * h/2);
    CVPixelBufferUnlockBaseAddress(pixelBufferA, 0);
    
    
    CIImage *coreImage= [CIImage imageWithCVPixelBuffer:pixelBufferA];
    CIContext *MytemporaryContext = [CIContext contextWithOptions:nil];
    CGImageRef MyvideoImage = [MytemporaryContext createCGImage:coreImage
                                                       fromRect:CGRectMake(0, 0, w, h)];
    
    // UIImage Conversion
    UIImage *Mynnnimage = [[UIImage alloc] initWithCGImage:MyvideoImage
                                                     scale:1.0
                                               orientation:UIImageOrientationUp];
    
    CVPixelBufferRelease(pixelBufferA);
    CGImageRelease(MyvideoImage);
    if(myframe!=NULL)
    {
        av_freep(&myframe->data[0]);
        av_frame_free(&myframe);
        myframe = NULL;
    }
    return Mynnnimage;
}


-(int )GetBmp:(AVFrame *)frame bSave:(BOOL)bSave
{
    AVFrame *tmpFrame1 = av_frame_alloc();
    tmpFrame1->width=_nRecordWidth;
    tmpFrame1->height=_nRecordHeight;
    av_image_alloc(tmpFrame1->data, tmpFrame1->linesize, _nRecordWidth,
                   _nRecordHeight,
                   AV_PIX_FMT_YUV420P,4);
    
    I420Scale(frame->data[0], frame->linesize[0],
              frame->data[1], frame->linesize[1],
              frame->data[2], frame->linesize[2],
              frame->width,frame->height,
              tmpFrame1->data[0], tmpFrame1->linesize[0],
              tmpFrame1->data[1], tmpFrame1->linesize[1],
              tmpFrame1->data[2], tmpFrame1->linesize[2],
              _nRecordWidth,_nRecordHeight,
              kFilterBilinear);
    {
        UIImage *myimage=nil;
        if(self.bNeedSave2Photo && self.bSaveCompelete && bSave)
        {
            self.bSaveCompelete = NO;
            
            myimage = [self YUVtoUIImage:tmpFrame1 SAVE:YES];
            if(myimage)
            {
                
                if(self.sSavePathPhoto==nil)
                {
                    [self F_SaveImage2PhotoAlbum:myimage];
                }
                else
                {
                    if( [UIImagePNGRepresentation(myimage) writeToFile:self.sSavePathPhoto atomically:YES])
                    {
                        if([self.delegate respondsToSelector:@selector(SnapPhotoCompelete:)])
                        {
                            [self.delegate SnapPhotoCompelete:YES];
                        }
                    }
                    else
                    {
                        if([self.delegate respondsToSelector:@selector(SnapPhotoCompelete:)])
                        {
                            [self.delegate SnapPhotoCompelete:NO];
                        }
                    }
                    self.bSaveCompelete = YES;
                    
                }
            }
            else
            {
                self.bSaveCompelete = YES;
                if([self.delegate respondsToSelector:@selector(SnapPhotoCompelete:)])
                {
                    [self.delegate SnapPhotoCompelete:NO];
                }
            }
        }
        self.bNeedSave2Photo = NO;
        if(!bSave)
        {
            if(myimage==nil)
            {
                myimage = [self YUVtoUIImage:tmpFrame1 SAVE:NO];
            }
            self.imgSNT =myimage;
        }
    }
    
    if(tmpFrame1!=NULL)
    {
        av_freep(&tmpFrame1->data[0]);
        av_frame_free(&tmpFrame1);
        tmpFrame1 = NULL;
    }
    return 0;
}

-(void)F_StartAdjDispFps
{
    __weak JH_WifiCamera *weakself = self;
    _isCancelled = NO;
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        int nn=0;
        while(!weakself.isCancelled)
        {
            if(nn>=100)
            {
                nn = 0;
                @synchronized (weakself)
                {
                    weakself.nDispFps=(int)weakself.nFrameCount;
                    weakself.nFrameCount=0;
                }
            }
            nn++;
            usleep(1000*10);
        }
        NSLog(@"Exit FPS!!!!!");
    });
}

-(int)naGetFps
{
    return _nDispFps;
}
-(int)PlatformDisplay:(AVFrame *)frame
{
    
    @synchronized (self)
    {
        _nFrameCount++;
    }
    
    self.bConnectedOK = YES;
    if((self.nSdStatus & Status_Connected) == 0)
    {
        self.nSdStatus |= Status_Connected;
        [self F_SentStatus];
    }
    if(self.bSNT)
    {
        [self GetBmp:frame bSave:NO];
        self.bNormalStop = YES;
        self.bPlaying = NO;
        return 0;
    }
    
    if(self.bNeedCreateNotify)
    {
        self.bNeedCreateNotify=NO;
        [self F_GetSDStatus_A];
    }
    
    if([self.delegate respondsToSelector:@selector(ReceiveImg:)])
    {
        [self.delegate ReceiveImg: [self YUVtoUIImage:frame SAVE:NO]];
        return 0;
    }
    
    if(!self.dispView)
        return -1;
    if(!_bNoDisp)
        [self.dispView displayYUV420pData:frame->data[0] width:(NSInteger)frame->width    height:(NSInteger)frame->height];
    
    return 0;
}


-(int)F_SavePhoto:(AVFrame *)frameA
{
#if 0
    if([self.delegate respondsToSelector:@selector(ReceiveImg:)])
    {
        [self.delegate ReceiveImg: [self YUVtoUIImage:frame SAVE:NO]];
    }
#endif
    if(self.bNeedSave2Photo)
    {
        @synchronized(_my_snapframe)
        {
            AVFrame *frame = _my_snapframe->pFrame;
            if(frame!=NULL)
                [self GetBmp:frame bSave:YES];
        }
    }
    return 0;
}

-(void)naSetVrBackground:(BOOL)bWhitea
{
    _bWhite = bWhitea;
}

-(void)naSetAlbumName:(NSString *)sAlbumName
{
    self.sAlbumName = sAlbumName;
}


-(void)F_SaveImage2PhotoAlbum:(UIImage *)imageA
{
    ALAuthorizationStatus authStatus = [ALAssetsLibrary authorizationStatus];
    if (authStatus == ALAuthorizationStatusRestricted || authStatus ==ALAuthorizationStatusDenied)
    {
        return;
    }
    
    __weak JH_WifiCamera *myself = self;
    __block UIImage *image =imageA;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        [assetsLibrary saveImage:image toAlbum:myself.sAlbumName completion:^(NSURL *assetURL, NSError *error)
         {
             if (!error)
             {
                 myself.bSaveCompelete = YES;
                 //NSLog(@"Wrie Photo OK!");
                 if([self.delegate respondsToSelector:@selector(SnapPhotoCompelete:)])
                 {
                     [self.delegate SnapPhotoCompelete:YES];
                 }
             }
             else{
                 //NSLog(@"%s: Error  :  %@",
                 //      __PRETTY_FUNCTION__, [error localizedDescription]);
                 myself.bSaveCompelete = YES;
                 if([self.delegate respondsToSelector:@selector(SnapPhotoCompelete:)])
                 {
                     [self.delegate SnapPhotoCompelete:NO];
                 }
             }
         }
                         failure:^(NSError *error)
         {
             //NSLog(@"%s: Error  :  %@",
             //      __PRETTY_FUNCTION__,  [error localizedDescription]);
             myself.bSaveCompelete = YES;
             if([self.delegate respondsToSelector:@selector(SnapPhotoCompelete:)])
             {
                 [self.delegate SnapPhotoCompelete:NO];
             }
         }];
    });
}


-(void)naClearDispFlag
{
    bDisping = NO;
}


-(void)StopSaveVideo
{
    m_bSaveVideo = false;
    NSLog(@"Stop Rrecord");
}


#define NUM_ADTS_SAMPLING_RATES    16
uint32_t AdtsSamplingRates[NUM_ADTS_SAMPLING_RATES] = {
    96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050,
    16000, 12000, 11025, 8000, 7350, 0, 0, 0
};

uint8_t MP4AdtsFindSamplingRateIndex(uint32_t samplingRate)
{
    uint8_t i;
    for(i = 0; i < NUM_ADTS_SAMPLING_RATES; i++) {
        if (samplingRate == AdtsSamplingRates[i]) {
            return i;
        }
    }
    return NUM_ADTS_SAMPLING_RATES - 1;
}
bool MY_MP4AacGetConfiguration(uint8_t** ppConfig,
                            uint32_t* pConfigLength,
                            uint8_t profile,
                            uint32_t samplingRate,
                            uint8_t channels)
{
    /* create the appropriate decoder config */
    
    uint8_t* pConfig = (uint8_t*)malloc(2);
    
    if (pConfig == NULL) {
        return false;
    }
    
    uint8_t samplingRateIndex = MP4AdtsFindSamplingRateIndex(samplingRate);
    
    pConfig[0] =(uint8_t) (((profile) << 3) | ((samplingRateIndex & 0xe) >> 1));
    pConfig[1] = (uint8_t)(((samplingRateIndex & 0x1) << 7) | (channels << 3));
    *ppConfig = pConfig;
    *pConfigLength = 2;
    return true;
}




#pragma mark - 设置音频

-(void)configureAudio
{
    _session = [AVAudioSession sharedInstance];
    
    BOOL success;
    NSError* error;
    
    
    success = [_session setCategory:AVAudioSessionCategoryRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionMixWithOthers error:&error];
    
    if (self.liveRecorder.releaseMethod == XDXRecorderReleaseMethodAudioUnit)
    {
        [_session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionMixWithOthers error:&error];
        [_session setPreferredIOBufferDuration:0.01 error:&error]; // 10ms采集一次
        [_session setPreferredSampleRate:44100 error:&error];  // 需和XDXRecorder中对应
        [_session setPreferredInputNumberOfChannels:2 error:&error];
        [_session setPreferredOutputNumberOfChannels:2 error:&error];
        [_session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        //[_session setPreferredHardwareSampleRate:44100 error:&error];
    }
    
    //set USB AUDIO device as high priority: iRig mic HD
    /*
     for (AVAudioSessionPortDescription *inputPort in [_session availableInputs])
     {
     if([inputPort.portType isEqualToString:AVAudioSessionPortUSBAudio])
     {
     [_session setPreferredInput:inputPort error:&error];
     [_session setPreferredInputNumberOfChannels:1 error:&error];
     break;
     }
     }
     */
    
    success = [_session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
    
    /*
     if(!success)
     NSLog(@"AVAudioSession error setCategory = %@",error.debugDescription);
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChanged:) name:AVAudioSessionRouteChangeNotification object:nil];
     //Restrore default audio output to BuildinReceiver
     AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
     for (AVAudioSessionPortDescription *portDesc in [currentRoute outputs])
     {
     if([portDesc.portType isEqualToString:AVAudioSessionPortBuiltInReceiver])
     {
     [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
     break;
     }
     }
     */
    success = [_session setActive:YES error:&error];
    
}
- (void)audioRouteChanged:(NSNotification*)notify {
    NSDictionary *dic = notify.userInfo;
    AVAudioSessionRouteDescription *currentRoute = [[AVAudioSession sharedInstance] currentRoute];
    AVAudioSessionRouteDescription *oldRoute = [dic objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
    NSNumber *routeChangeReason = [dic objectForKey:AVAudioSessionRouteChangeReasonKey];
    NSLog(@"audio route changed: reason: %@\n input:%@->%@, output:%@->%@",routeChangeReason,oldRoute.inputs,currentRoute.inputs,oldRoute.outputs,currentRoute.outputs);
    
}



- (void)setupAudioCapture {
    
    
#if 1
    if(!self.liveRecorder)
    {
        _liveRecorder = [[XDXRecorder alloc] init];
        _liveRecorder.delegate = self;
    }
    [self configureAudio];
    
#else
    NSError *error = nil;
    self.aacEncoder = [[AACEncoder alloc] init];
    self.session = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    
    
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:&error];
    
    if (error) {
        NSLog(@"Error getting audio input device:%@",error.description);
    }
    
    if ([self.session canAddInput:audioInput]) {
        [self.session addInput:audioInput];
    }
    
    self.AudioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    if(!self.audioOutput)
        self.audioOutput = [AVCaptureAudioDataOutput new];
    
    [self.audioOutput setSampleBufferDelegate:self queue:self.AudioQueue];
    
    if ([self.session canAddOutput:self.audioOutput])
    {
        [self.session addOutput:self.audioOutput];
    }
    self.audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
#endif
}

-(void)F_StartAudio:(BOOL)bStart
{
    if(bStart)
    {
        [self setupAudioCapture];
        [self.liveRecorder startAudioUnitRecorder];
    }
    else
    {
        if (_session)
        {
            [self.liveRecorder stopAudioUnitRecorder];
            NSError *error=nil;
            [_session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker|AVAudioSessionCategoryOptionAllowBluetooth|AVAudioSessionCategoryOptionMixWithOthers error:&error];
            [_session setActive:NO error:&error];
        }
    }
}


#pragma mark - 实现 AVCaptureOutputDelegate：

-(void)ReceiveAAC_Data:(NSData *)data
{
    [self writeAudio:data];
}

/*
 - (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
 if (connection == _audioConnection)
 {
 // 音频
 __weak JH_WifiCamera *weakself =self;
 [self.aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
 if (encodedData)
 {
 [weakself writeAudio:encodedData];
 }else {
 NSLog(@"Error encoding AAC: %@", error);
 }
 }];
 }
 }
 */


-(void)writeAudio:(NSData *)encodedData
{
    if(fileHandle != MP4_INVALID_FILE_HANDLE && audio_trkid !=MP4_INVALID_TRACK_ID && video !=MP4_INVALID_TRACK_ID )
    {
        uint8_t *data =(uint8_t *) [encodedData bytes];
        int nLen =(int) encodedData.length;
        MP4WriteSample(self->fileHandle, self->audio_trkid,(const uint8_t*)data,(uint32_t)nLen, MP4_INVALID_DURATION, 0, 1);
    }
}



// 编码回调，每当系统编码完一帧之后，会异步掉用该方法，此为c语言方法

#pragma mark  编码回调
void encodeOutputCallback(void *userData, void *sourceFrameRefCon, OSStatus status, VTEncodeInfoFlags infoFlags,
                          CMSampleBufferRef sampleBuffer )
{
    if (status != noErr) {
        //NSLog(@"didCompressH264 error: with status %d, infoFlags %d", (int)status, (int)infoFlags);
        return;
    }
    if (!CMSampleBufferDataIsReady(sampleBuffer))
    {
        //NSLog(@"didCompressH264 data is not ready ");
        return;
    }
    JH_WifiCamera *myself = (__bridge JH_WifiCamera *)userData;
    // 判断当前帧是否为关键帧
    bool keyframe = !CFDictionaryContainsKey( (CFArrayGetValueAtIndex(CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true), 0)), kCMSampleAttachmentKey_NotSync);
    // 获取sps & pps数据. sps pps只需获取一次，保存在h264文件开头即可
    if (keyframe && !myself->_spsppsFound)
    {
        size_t spsSize, spsCount;
        size_t ppsSize, ppsCount;
        const uint8_t *spsData, *ppsData;
        CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
        OSStatus err0 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 0, &spsData, &spsSize, &spsCount, 0 );
        OSStatus err1 = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(formatDesc, 1, &ppsData, &ppsSize, &ppsCount, 0 );
        if (err0==noErr && err1==noErr)
        {
            myself->_spsppsFound = 1;
            myself->video = MP4AddH264VideoTrack(myself->fileHandle,90000,90000/myself->nFps,myself->_nRecordWidth, myself->_nRecordHeight, spsData[1], spsData[2], spsData[3], 3);
            if (myself->video == MP4_INVALID_TRACK_ID) {
                MP4Close(myself->fileHandle, 0);
                myself->fileHandle = MP4_INVALID_FILE_HANDLE;
            }
            else
            {
                MP4AddH264SequenceParameterSet(myself->fileHandle, myself->video, spsData, spsSize);
                MP4AddH264PictureParameterSet(myself->fileHandle, myself->video, ppsData, ppsSize);
            }
            
            if(myself.bG_Audio)
            {
                myself->audio_trkid = MP4AddAudioTrack(myself->fileHandle, 44100, 1024, MP4_MPEG4_AUDIO_TYPE);
                //MP4SetAudioProfileLevel(myself->fileHandle, 0x0F);
                MP4SetAudioProfileLevel(myself->fileHandle, 0x02);
                int samplesPerSecond = 44100;
                int profile = 2; //AAC_LC
                int channelConfig = 2;
                uint8_t *pConfig = NULL;
                uint32_t configLength = 0;
                MY_MP4AacGetConfiguration(&pConfig, &configLength, profile, samplesPerSecond, channelConfig);
                MP4SetTrackESConfiguration(myself->fileHandle, myself->audio_trkid, pConfig, configLength);
                if(pConfig!=NULL)
                {
                    free(pConfig);
                }
            }
            NSLog(@"got sps/pps data. Length: sps=%zu, pps=%zu", spsSize, ppsSize);
        }
    }
    
    size_t lengthAtOffset, totalLength;
    char *data;
    
    CMBlockBufferRef dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
    OSStatus error = CMBlockBufferGetDataPointer(dataBuffer, 0, &lengthAtOffset, &totalLength, &data);
    
    if (error == noErr) {
        
        if(!myself->_bCanWrite)
        {
            if(keyframe)
            {
                myself->_bCanWrite = YES;
            }
        }
        if(myself->_bCanWrite )
        {
            size_t offset = 0;
            const int lengthInfoSize = 4; // 返回的nalu数据前四个字节不是0001的startcode，而是大端模式的帧长度length
            int ds = 90000/(myself->nFps);  //   (1000/nfps*90000)/1000
            // 循环获取nalu数据    因为有可能编码出来不止一帧。（当然，在本项目中，出来的就是一帧数据）
            while (offset < totalLength - lengthInfoSize)
            {
                uint32_t naluLength = 0;
                memcpy(&naluLength, data + offset, lengthInfoSize); // 获取nalu的长度，
                // 大端模式转化为系统端模式
                naluLength = CFSwapInt32BigToHost(naluLength);
                if(myself->video)
                {
                    Byte type= data[offset+4] & 0x1F;
                    if(type != 7 &&
                       type != 8 &&
                       type != 6)
                    {
                        MP4WriteSample(myself->fileHandle,  myself->video,(const uint8_t *)(data+offset), naluLength+4, ds, 0, keyframe);
                        myself->_nRecTime++;
                    }
                }
                offset += lengthInfoSize + naluLength;
            }
        }
        
    }
}

- (int)startEncodeSession:(int)width height:(int)height framerate:(int)fps bitrate:(int)bt
{
    
    _frameCount = 0;
    _bCanWrite = NO;
    _spsppsFound = NO;
    
#if TARGET_OS_SIMULATOR
    NSLog(@"VideoToolbox H264 codec is not supported on simulators");
#else
    OSStatus status;
    OSType KVideoPixelFormatType = kCVPixelFormatType_420YpCbCr8Planar;
    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey : @{}};
    //CVPixelBufferRef pixelBuffer;
    if(pixelBuffer!=NULL)
    {
        CVPixelBufferRelease(pixelBuffer);
    }
    CVPixelBufferCreate(NULL, width, height, KVideoPixelFormatType, (__bridge CFDictionaryRef)(pixelBufferAttributes), &pixelBuffer);
    
    
    VTCompressionOutputCallback cb = encodeOutputCallback;
    CFMutableDictionaryRef source_attrs = CFDictionaryCreateMutable (NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFNumberRef number;
    
    number = CFNumberCreate (NULL, kCFNumberSInt16Type, &width);
    CFDictionarySetValue (source_attrs, kCVPixelBufferWidthKey, number);
    CFRelease (number);
    
    number = CFNumberCreate (NULL, kCFNumberSInt16Type, &height);
    CFDictionarySetValue (source_attrs, kCVPixelBufferHeightKey, number);
    CFRelease (number);
    
    OSType pixelFormat = kCVPixelFormatType_420YpCbCr8Planar;
    number = CFNumberCreate (NULL, kCFNumberSInt32Type, &pixelFormat);
    CFDictionarySetValue (source_attrs, kCVPixelBufferPixelFormatTypeKey, number);
    CFRelease (number);
    
    CFDictionarySetValue(source_attrs, kCVPixelBufferOpenGLESCompatibilityKey, kCFBooleanTrue);
    
    status = VTCompressionSessionCreate(kCFAllocatorDefault, width, height, kCMVideoCodecType_H264, NULL, source_attrs, NULL, cb, (__bridge void *)(self), &_encodeSesion);
    CFRelease(source_attrs);
    if (status != noErr) {
        NSLog(@"VTCompressionSessionCreate failed. ret=%d", (int)status);
        return -1;
    }
    
    
    // 设置实时编码输出，降低编码延迟
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue);
    NSLog(@"set realtime  return: %d", (int)status);
    // h264 profile, 直播一般使用baseline，可减少由于b帧带来的延时
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Baseline_AutoLevel);
    NSLog(@"set profile   return: %d", (int)status);
    
    // 设置编码码率(比特率)，如果不设置，默认将会以很低的码率编码，导致编码出来的视频很模糊
    status  = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_AverageBitRate, (__bridge CFTypeRef)@(bt)); // bps
    status += VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_DataRateLimits, (__bridge CFArrayRef)@[@(bt*2/8), @1]); // Bps
    NSLog(@"set bitrate   return: %d", (int)status);
    
    // 设置帧率，只用于初始化session，不是实际FPS
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_ExpectedFrameRate, (__bridge CFTypeRef)@(fps));
    NSLog(@"set framerate return: %d", (int)status);
    
    // 设置关键帧间隔，即gop size
    status = VTSessionSetProperty(_encodeSesion, kVTCompressionPropertyKey_MaxKeyFrameInterval, (__bridge CFTypeRef)@(fps));
    
    // 开始编码
    status = VTCompressionSessionPrepareToEncodeFrames(_encodeSesion);
    NSLog(@"start encode  return: %d", (int)status);
#endif
    return 0;
}


- (void) stopEncodeSession
{
    if(_encodeSesion!=NULL)
    {
        VTCompressionSessionCompleteFrames(_encodeSesion, kCMTimeInvalid);
        VTCompressionSessionInvalidate(_encodeSesion);
        usleep(1000*10);
        CFRelease(_encodeSesion);
        _encodeSesion = NULL;
        NSLog(@"Close Mp4V2!");
    }
    _bCanWrite = NO;
}

/*
 - (void)encodeFrame:(CMSampleBufferRef )sampleBuffer
 {
 
 CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
 // pts,必须设置，否则会导致编码出来的数据非常大，原因未知
 CMTime pts = CMTimeMake(_frameCount, nFps);
 CMTime duration = kCMTimeInvalid;
 _frameCount++;
 VTEncodeInfoFlags flags;
 // 送入编码器编码
 OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSesion,
 imageBuffer,
 pts, duration,
 NULL, NULL, &flags);
 if (statusCode != noErr)
 {
 NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
 return;
 }
 }
 */

-(int64_t)naGetRecordTime
{
    if(nFps!=0)
    {
        uint64_t nT = _nRecTime * 1000/nFps;
        return nT;
    }
    return 0;
}

-(int)StartSaveVideo
{
    _spsppsFound = NO;
    NSString *movBasePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear| NSCalendarUnitMonth| NSCalendarUnitDay| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponents = [curCalendar components:unitFlags fromDate:[NSDate date]];
    if(self.sSavePath && self.sSavePath.length>0)
    {
        m_VideoPath = self.sSavePath;
    }
    else
    {
        m_VideoPath = [movBasePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%ld-%02ld-%02ld-%02ld-%02ld-%02ld.mp4",(long)dateComponents.year,(long)dateComponents.month,(long)dateComponents.day,(long)dateComponents.hour, (long)dateComponents.minute, (long)dateComponents.second ]];
    }
    
    if(m_VideoPath)
    {
        m_VideoPath = [NSString  stringWithFormat:@"%@.part",m_VideoPath];
    }
    
    if(fileHandle!=MP4_INVALID_FILE_HANDLE)
    {
        MP4Close(fileHandle, 0);
        fileHandle = MP4_INVALID_FILE_HANDLE;
    }
    //创建mp4文件
    fileHandle = MP4Create([m_VideoPath UTF8String] , 0);
    if(fileHandle ==MP4_INVALID_FILE_HANDLE)
    {
        return -1;
    }
    MP4SetTimeScale(fileHandle, 90000);
    
    int nbit = (int)(_nRecordWidth*_nRecordHeight*4.5);
    
    [self startEncodeSession:_nRecordWidth height:_nRecordHeight framerate:nFps bitrate:nbit];
    [self ClearQueue];
    
    
    self.nRecTimePreStart = 0;
    self.nRecTime = 0;
    NSLog(@"Reset nRecTime");
    
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakself writeVideo];
    });
    
    
    return 0;
}


-(int)writeVideo
{
#if 0
    m_bSaveVideo = true;
#else
    __weak JH_WifiCamera *weakself = self;
    m_bSaveVideo = true;
    //MyFrame *mFrame = [[MyFrame alloc] init];
    
    AVFrame *mFrame;
    
    AVFrame *mWriteFrame = NULL;
    
    AVFrame *pFrame = NULL;
    
    //MyFrame *MyFrameX = nil;
    
    MyFrame *MyFrame = nil;
    
    int64_t T1 = 0;
    
    int64_t T2;
    T1 = av_gettime()/1000;
    int  delay = 1000/nFps -3;
    mFrame = av_frame_alloc();
    av_image_alloc(
                   mFrame->data, mFrame->linesize, _nRecordWidth,
                   _nRecordHeight,
                   AV_PIX_FMT_YUV420P, 4);
    mFrame->width=_nRecordWidth;
    mFrame->height=_nRecordHeight;
    while(m_bSaveVideo)   // && m_Status== E_PlayerStatus_Playing)
    {
        pFrame = NULL;
        @synchronized(videoFrames)
        {
            if(videoFrames.count>0)
            {
                MyFrame = videoFrames[0];
                pFrame = MyFrame->pFrame;
            }
            if(pFrame==NULL)
            {
                T1 = av_gettime()/1000;
                usleep(1000*10);
                continue;
            }
            if(pFrame->width != mFrame->width ||
               pFrame->height != mFrame->height)
            {
                I420Scale(pFrame->data[0], pFrame->linesize[0],
                          pFrame->data[1], pFrame->linesize[1],
                          pFrame->data[2], pFrame->linesize[2],
                          pFrame->width,pFrame->height,
                          mFrame->data[0], mFrame->linesize[0],
                          mFrame->data[1], mFrame->linesize[1],
                          mFrame->data[2], mFrame->linesize[2],
                          mFrame->width, mFrame->height,
                          kFilterLinear);
                mWriteFrame =  mFrame;
            }
            else
            {
                /*
                I420Copy(pFrame->data[0], pFrame->linesize[0],
                         pFrame->data[1], pFrame->linesize[1],
                         pFrame->data[2], pFrame->linesize[2],
                         mFrame->data[0], mFrame->linesize[0],
                         mFrame->data[1], mFrame->linesize[1],
                         mFrame->data[2], mFrame->linesize[2],
                         mFrame->width, mFrame->height);
                 */
                mWriteFrame =  pFrame;
            }
            
            
            
            //if([self writeFrame:mFrame]!=0)
            if([self writeFrame:mWriteFrame]!=0)
                m_bSaveVideo = false;
            
            if(videoFrames.count>1)
            {
                [videoFrames removeObjectAtIndex:0];
                av_freep(&(pFrame->data[0]));
                av_frame_free(&pFrame);
            }
            
        }
        
        
        T2 =av_gettime()/1000;
        int tt = (int)(T2-T1);
        tt = delay-tt;
        if(tt>0)
        {
            usleep(tt*1000);
        }
        T1 = av_gettime()/1000;
    }
    
    [self stopEncodeSession];
    
    av_freep(&(mFrame->data[0]));
    av_frame_free(&(mFrame));
    
    NSLog(@"Exit Write Frame!!!!");
    while(videoFrames.count>0)
    {
        MyFrame = videoFrames[0];
        pFrame = MyFrame->pFrame;
        [videoFrames removeObjectAtIndex:0];
        av_freep(&(pFrame->data[0]));
        av_frame_free(&pFrame);
    }
    
    
    if(pixelBuffer!=NULL)
    {
        CVPixelBufferRelease(pixelBuffer);
        pixelBuffer = NULL;
    }
    usleep(1000*10);
    MP4Close(fileHandle,0);
    fileHandle = MP4_INVALID_FILE_HANDLE;
    video=MP4_INVALID_TRACK_ID;
    audio_trkid=MP4_INVALID_TRACK_ID;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    if(self.sSavePath) //储存在 沙盒中
    {
        if([fileManager moveItemAtPath:m_VideoPath toPath:self.sSavePath error:&error])
        {
            NSLog(@"Save OK3");
        }
        self.sSavePath = nil;
        return 0;
    }
    //如果不储存在沙盒中，就移到系统相册中去
    NSString *path = [m_VideoPath stringByDeletingPathExtension];
    if([fileManager moveItemAtPath:m_VideoPath toPath:path error:&error])
    {
        BOOL re = UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path);
        if(re)
        {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_global_queue(0, 0), ^(void)
                           {
                               ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                               [library saveVideo:[NSURL fileURLWithPath:path] toAlbum:weakself.sAlbumName completion:^(NSURL *assetURL, NSError *error){
                                   if (!error)
                                   {
                                       NSFileManager *defaultManager;
                                       defaultManager = [NSFileManager defaultManager];
                                       [defaultManager removeItemAtPath:path error:nil];
                                   }
                                   else{
                                       NSLog(@"video Library Error1");
                                   }
                               }
                                          failure:^(NSError *error)
                                {
                                    NSLog(@"video Library Error2");
                                }];
                           });
        }
    }
    else
    {
        NSFileManager *defaultManager;
        defaultManager = [NSFileManager defaultManager];
        [defaultManager removeItemAtPath:path error:nil];
        NSLog(@"error : %@",_sAlbumName);
    }
    
#endif
    return 0;

}


-(void)ClearQueue
{
    @synchronized(videoFrames)
    {
        for(MyFrame *frame in videoFrames)
        {
            AVFrame *pFrame = frame->pFrame;
            av_freep(&(pFrame->data[0]));
            
            av_frame_free(&pFrame);
        }
        [videoFrames removeAllObjects];
    }
}





-(CVPixelBufferRef) copyDataFromBuffer:(AVFrame* )frame toYUVPixelBufferWithWidth:(size_t)w Height:(size_t)h
{
    //AV_PIX_FMT_YUV420P
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    size_t d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    unsigned char* dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int y=0;
    for(y=0;y<h;y++)
    {
        memcpy(dst,frame->data[0]+y*frame->linesize[0],frame->linesize[0]);
        dst+=d;
    }
    
    d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    
    h>>=1;
    for(y=0;y<h;y++)
    {
        memcpy(dst,frame->data[1]+y*frame->linesize[1],frame->linesize[1]);
        dst+=d;
    }
    
    d = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 2);
    dst = (unsigned char *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 2);
    for(y=0;y<h;y++)
    {
        memcpy(dst,frame->data[2]+y*frame->linesize[2],frame->linesize[2]);
        dst+=d;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return pixelBuffer;
}

-(int)writeFrame:(AVFrame* )pOutFrame
{
    
    CVPixelBufferRef imageBuffer = [self copyDataFromBuffer:pOutFrame toYUVPixelBufferWithWidth:_nRecordWidth Height:_nRecordHeight];
    CMTime pts = CMTimeMake(_frameCount, nFps);
    CMTime duration = kCMTimeInvalid;
    VTEncodeInfoFlags flags;
    // 送入编码器编码
    OSStatus statusCode = VTCompressionSessionEncodeFrame(_encodeSesion,
                                                          imageBuffer,
                                                          pts, duration,
                                                          NULL, NULL, &flags);
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);
        [self stopEncodeSession];
        return -1;
    }
    _frameCount++;
    return 0;
}


#pragma mark My_Socket_Recv_Delegate
-(int)F_FindGPSOCKET
{
    
    int nLen =(int) _RevData.length;
    if(nLen<8)
    {
        return -1;
    }
    Byte *dat = (Byte *)[_RevData bytes];
    int ix;
    for(ix=0;ix<nLen-7;ix++)
    {
        if(dat[ix+0]=='G' &&
           dat[ix+1]=='P' &&
           dat[ix+2]=='S' &&
           dat[ix+3]=='O' &&
           dat[ix+4]=='C' &&
           dat[ix+5]=='K' &&
           dat[ix+6]=='E' &&
           dat[ix+7]=='T' )
        {
            return ix;
        }
    }
    return -1;
}

-(int )F_ConnectToGP
{
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1 ;
        }
    }
    usleep(1000*10);
    return 0;
}

-(int)F_GP_SetMode:(int)nMode
{
    while (self.bGp_GetStatusing) {
        ;
    }
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
    cmd[10] = 0x00;
    cmd[11] = 0x00;
    cmd[12] = (Byte)nMode;
    NSData *data = [[NSData alloc] initWithBytes:cmd length:13];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)        {
            return -1 ;
        }
    }
    NSLog(@"Write Mode");
    [_gpCmd_Socket Write:data];
    return -1;
}


-(NSData *)F_GP_GetStatus
{
    if(self.nGp_CurrentMode!=0)
    {
        self.bGp_GetStatusing=NO;
        return nil;
    }
    
    self.bGp_GetStatusing = YES;
    
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
    
    cmd[10] = 0x00;
    cmd[11] = 0x01;    //GetStatus
    
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:12];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            self.bGp_GetStatusing = NO;
            return nil ;
        }
    }
    
    [_gpCmd_Socket Write:data];
    
    NSData *data_rev = [_gpCmd_Socket Read:14 timeout:100];
    
    Byte *dat=NULL;
    int nLen=0;
    if(data_rev)
    {
        if(data_rev.length==14)
        {
            dat = (Byte *)[data_rev bytes];
            if(dat[8]== 0x02 && dat[9]== 0x00)  //ACK
            {
                if(dat[10]== 0x00 && dat[11]== 0x01)
                {
                    nLen = dat[13]*0x100+dat[12];
                    data_rev=nil;
                    if(nLen>0)
                        data_rev = [_gpCmd_Socket Read:nLen timeout:200];
                    [_gpCmd_Socket Read:242 timeout:10];
                    //dat = (Byte *)[data_rev bytes];
                    self.bGp_GetStatusing = NO;
                    return data_rev;
                }
            }
        }
    }
    //[_gpCmd_Socket Read:242 timeout:20];
    self.bGp_GetStatusing = NO;
    return nil;
}

-(NSData *)F_GP_GetXML:(int)nLanguage
{
    while (self.bGp_GetStatusing) {
        ;
    }
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
    
    cmd[10] = 0x00;
    cmd[11] = 0x02;    //GetXML
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:12];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return nil ;
        }
    }
    [_gpCmd_Socket Write:data];
    usleep(10000);
    BOOL  bRe=YES;
    NSData *data_rev;
    NSMutableData  *revData = [[NSMutableData alloc] init];
    while(bRe)
    {
        
        data_rev = [_gpCmd_Socket Read:14 timeout:800];
        if(data_rev)
        {
            if(data_rev.length==14)
            {
                dat = (Byte *)[data_rev bytes];
                if(dat[10]== 0x00 && dat[11]== 0x02)
                {
                    nLen = dat[13]*0x100+dat[12];
                    data_rev=nil;
                    if(nLen>0)
                    {
                        data_rev = [_gpCmd_Socket Read:nLen timeout:500];
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
            bRe = NO;
        }
    }
    nLen = (int)revData.length;
    [_gpCmd_Socket Read:6*1024 timeout:150];
    if(nLen==0)
        return nil;
    return  revData;
}

-(int)F_GP_RestartStreaming
{
    while (self.bGp_GetStatusing) {
        ;
    }
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
    cmd[10] = 0x00;
    cmd[11] = 0x04;    //RestartString
    NSData *data = [[NSData alloc] initWithBytes:cmd length:12];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1 ;
        }
    }
    [_gpCmd_Socket Write:data];
    [_gpCmd_Socket Read:242 timeout:10];
    return 0;
}


-(NSData *)F_GP_AuthDevice:(NSData *)dataA
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = (Byte *)[dataA bytes];
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
    
    cmd[10] = 0x00;
    cmd[11] = 0x05;    //AuthDevice
    
    
    cmd[12]=dat[0];
    cmd[13]=dat[1];
    cmd[14]=dat[2];
    cmd[15]=dat[3];
    
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:16];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return nil ;
        }
    }
    [_gpCmd_Socket Write:data];
    usleep(5000);
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        data = [[NSData alloc] initWithBytes:dat+14 length:2];
        [_gpCmd_Socket Read:242 timeout:10];
        return data;
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return nil;
}


-(int)F_GP_Record_Cmd
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x01;     //Mode Record
    cmd[11] = 0x00;    // Record Start Or Stop
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:12];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            [_gpCmd_Socket Read:242 timeout:10];
            return 0;
        }
        else
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return dat[12]+dat[13]*0x100;
            }
        }
        
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
}


-(int)F_GP_Record_AutioCmd:(BOOL)bOnOff
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x01;     //Mode Record
    cmd[11] = 0x01;    // Audio
    if(bOnOff)
        cmd[12]=1;
    else
        cmd[12]=0;
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:13];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            [_gpCmd_Socket Read:242 timeout:10];
            return 0;
        }
        else
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return dat[12]+dat[13]*0x100;
            }
        }
        
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
}

-(int)F_GP_Capture
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x02;     //Mode Capture
    cmd[11] = 0x00;    //
    
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:12];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            [_gpCmd_Socket Read:242 timeout:10];
            return 0;
        }
        else
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return dat[12]+dat[13]*0x100;
            }
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
}

-(int)F_GP_PlayBack:(int)fileInx
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x03;     //Mode Playback
    cmd[11] = 0x00;     //
    
    cmd[12]=(Byte)fileInx;
    cmd[13]=(Byte)(fileInx>>8);
    
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:14];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            [_gpCmd_Socket Read:242 timeout:10];
            return 0;
        }
        else
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return dat[12]+dat[13]*0x100;
            }
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
    
    
}

-(int)F_GP_PlayBackPause:(int)nType
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x03;     //Mode Playback
    cmd[11] = 0x01;     //
    
    if(nType!='J')
        nType = 'A';
    cmd[12]=(Byte)nType;
    
    
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:13];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            [_gpCmd_Socket Read:242 timeout:10];
            return 0;
        }
        else
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return dat[12]+dat[13]*0x100;
            }
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
    
    
}

-(int)F_GP_PlayBackStop:(int)nType
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x03;     //Mode Playback
    cmd[11] = 0x06;     //
    
    if(nType!='J')
        nType = 'A';
    cmd[12]=(Byte)nType;
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:13];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            [_gpCmd_Socket Read:242 timeout:10];
            return 0;
        }
        else
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return dat[12]+dat[13]*0x100;
            }
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
    
}


-(void)F_GP_GetAllFile:(SDFiles_GP)Files
{
    while (self.bGp_GetStatusing) {
        ;
    }
    self.SDFiles = Files;
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int nCount = [self F_GP_GetFileCount];
        int readCount = 0;
        if(nCount==0)
        {
            weakself.SDFiles(nil);
            return;
        }
        Byte cmd[3];
        cmd[0]=1;
        cmd[1]=0;
        cmd[2]=0;
        
        while(nCount!=0)
        {
            
            NSData *data =[[NSData alloc] initWithBytes:cmd length:3];
            NSData *revData = [weakself F_GP_GetNameList:data];
            Byte *dat;
            if(revData)
            {
                int nfiles=0;
                dat = (Byte *)[revData bytes];
                nfiles = dat[0];
                readCount+=dat[0];
                dat+=1;
                int x;
                for(x=0;x<nfiles;x++)
                {
                    
                    NSData *sData = [[NSData alloc] initWithBytes:dat+x*13 length:13];
                    weakself.SDFiles(sData);
                }
                x--;
                if(x>=0)
                {
                    cmd[0]=0;
                    cmd[1]=dat[x*13+1];
                    cmd[2]=dat[x*13+2];
                }
                nCount-=nfiles;
            }
            else
            {
                nCount=0;
            }
        }
        weakself.SDFiles(nil);
    });
    
}

-(int)F_GP_GetFileCount
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = NULL;
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
    
    cmd[10] = 0x03;     //Mode Playback
    cmd[11] = 0x02;     //
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:12];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1;
        }
    }
    [_gpCmd_Socket Write:data];
    NSData *dataB = [_gpCmd_Socket Read:16 timeout:250];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        int reACK = dat[8]+dat[9]*0x100;
        if(reACK==0x0002)
        {
            if(dataB.length>=14)
            {
                [_gpCmd_Socket Read:242 timeout:10];
                int nCount = dat[14]+dat[15]*0x100;
                return nCount;
            }
            else
            {
                [_gpCmd_Socket Read:242 timeout:10];
                return -4;
            }
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -3;
}

-(NSData *)F_GP_GetNameList:(NSData *)dataA
{
    while (self.bGp_GetStatusing) {
        ;
    }
    /*
     Byte[0]:  0x00 = Get list by File index
     0x01 = Get list from 1st file
     Byte[1~2]: The file index in file attribute. The last File index in previous
     */
    
    Byte *dat = (Byte *)[dataA bytes];
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
    
    cmd[10] = 0x03;     //Mode Playback
    cmd[11] = 0x03;     //
    
    cmd[12]=dat[0];
    cmd[13]=dat[1];
    cmd[14]=dat[2];
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:15];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return nil;
        }
    }
    [_gpCmd_Socket Write:data];
    int nLen=0;
    NSData *dataB = [_gpCmd_Socket Read:14 timeout:500];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        if(dataB.length==14)
        {
            nLen = dat[12]+dat[13]*0x100;
            dataB = [_gpCmd_Socket Read:nLen timeout:250];
            [_gpCmd_Socket Read:242 timeout:10];
            return dataB;
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return nil;
}



-(void)F_GP_GetRawData:(int)fileInx FileSize:(UInt32)filesize Progress:(Progress_GP)Progress
{
    self.Progress=Progress;
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [weakself F_GP_GetRawDataA:fileInx FileSize:filesize];
    });
}

-(int)F_GP_GetRawDataA:(int)fileInx FileSize:(UInt32)filesize
{
    
    while (self.bGp_GetStatusing) {
        ;
    }
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
    cmd[11] = 0x05;    //GetRawData
    
    cmd[12] = fileInx;
    cmd[13] = fileInx>>8;
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:14];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1 ;
        }
    }
    [_gpCmd_Socket Write:data];
    usleep(10000);
    BOOL  bRe=YES;
    NSData *data_rev;
    NSMutableData  *revData = [[NSMutableData alloc] init];
    UInt32  nCount=0;
    while(bRe)
    {
        data_rev = [_gpCmd_Socket Read:14 timeout:800];
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
                        data_rev = [_gpCmd_Socket Read:nLen timeout:500];
                        if(data_rev)
                        {
                            [revData appendData:data_rev];
                        }
                        if(nLen<242)
                        {
                            bRe = NO;
                        }
                        nCount+=data_rev.length;
                        int nPre = ((nCount/1000)*100)/filesize;
                        self.Progress(nPre,data_rev);
                    }
                }
            }
        }
        else
        {
            bRe = NO;
        }
    }
    // nLen = (int)revData.length;
    [_gpCmd_Socket Read:10*1024 timeout:200];
    self.Progress(100,data_rev);
    return  0;
}

//GetParameter
-(int)F_GP_GetParameter:(int32_t)cmdid
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat=NULL;
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
    
    cmd[10] = 0x04;         //Menu
    cmd[11] = 0x00;    //
    
    cmd[12] = (Byte)(cmdid>>0);
    cmd[13] = (Byte)(cmdid>>8);
    cmd[14] = (Byte)(cmdid>>16);
    cmd[15] = (Byte)(cmdid>>24);
    
    NSData *data = [[NSData alloc] initWithBytes:cmd length:16];
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1 ;
        }
    }
    [_gpCmd_Socket Write:data];
    int resAck;
    NSData *dataB = [_gpCmd_Socket Read:15 timeout:100];
    if(dataB)
    {
        dat = (Byte *)[dataB bytes];
        if(dataB.length>=14)
        {
            resAck = dat[8]+dat[9]*0x100;
            if(resAck == 0x0002)
            {
                if(dat[10] == 0x04 && dat[11]==0x00)
                {
                    [_gpCmd_Socket Read:242 timeout:10];
                    return dat[14];
                }
            }
        }
    }
    [_gpCmd_Socket Read:242 timeout:10];
    return -1;
}

//SetParameter
-(int)F_GP_SetParameter:(int32_t)cmdid  Data:(NSData *)writeData
{
    while (self.bGp_GetStatusing) {
        ;
    }
    Byte *dat = (Byte *)[writeData bytes];
    Byte cmd[255];
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
    
    cmd[10] = 0x04;         //Menu
    cmd[11] = 0x01;    //
    
    cmd[12] = (Byte)(cmdid>>0);
    cmd[13] = (Byte)(cmdid>>8);
    cmd[14] = (Byte)(cmdid>>16);
    cmd[15] = (Byte)(cmdid>>24);
    
    cmd[16] =(Byte) writeData.length;
    for(int i=0;i<writeData.length;i++)
    {
        if(i<254-17)
        {
            cmd[17+i]=dat[i];
        }
        else
        {
            break;
        }
    }
    NSData *data = [[NSData alloc] initWithBytes:cmd length:17+writeData.length];
    
    if(!self.gpCmd_Socket.bConnected)
    {
        if([_gpCmd_Socket Connect:self.sSerVerIP PORT:8081]<0)
        {
            return -1 ;
        }
    }
    [_gpCmd_Socket Write:data];
    [_gpCmd_Socket Read:242 timeout:10];
    return 0;
}

-(void)F_GP_StopGetStatus
{
    self.bGp_GetStatus = NO;
}

-(void)F_GP_StartGetStatus
{
    self.bGp_GetStatus=YES;
    __weak JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Byte *dat;
        /*
         Byte dat[15];
         dat[14]=(Byte)1;
         dat[0]=0;
         dat[1]=0;
         */
        int nIxon= 0;
        while(weakself.bGp_GetStatus)
        {
            nIxon++;
            if(nIxon>=50)
            {
                nIxon=0;
                NSData *data =  [weakself F_GP_GetStatus];
                if(data)
                {
                    
                    dat = (Byte *)[data bytes];
                    
                    if(dat[14] !=0)
                    {
                        weakself.nSdStatus |=SD_Ready;
                    }
                    if(dat[0]== 0 && (dat[1]&0x01)!=0)
                    {
                        weakself.nSdStatus |=SD_Recording;
                    }
                    else
                    {
                        weakself.nSdStatus &=(SD_Recording^0xFF);
                    }
                    [weakself F_SentStatus];
                }
                
                usleep(1000*10);
            }
        }
    });
}


#pragma mark GPRTP
- (int)createVideoSocket_RTP {
    self.videofd = -1;
    uartCommandfd=-1;
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000*10;
    
    struct sockaddr_in myaddr;
    if ((self.videofd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        printf("Failed to create socket\n");
        return -1;
    }
    
    bzero((char *)&myaddr, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    myaddr.sin_port = htons(10900);
    
    
    //chinwei 20160503
#if 0
    int value = 1;
    int status = 0;
    
    status = setsockopt(self.videofd, SOL_SOCKET, SO_REUSEADDR, &value, sizeof(value));
    /*
     if (status) {
     fprintf(stderr, "SO_REUSEADDR failed! (%s)\n", strerror(errno));
     shutdown(self.videofd, 2);
     close(self.videofd);
     self.videofd = -1;
     return -3;
     
     }
     */
    value = 1;
    status = setsockopt(self.videofd, SOL_SOCKET, SO_REUSEPORT, &value, sizeof(value));
    /*
     if (status) {
     fprintf(stderr, "SO_REUSEPORT failed! (%s)\n", strerror(errno));
     shutdown(self.videofd, 2);
     close(self.videofd);
     self.videofd = -1;
     return -4;
     
     }
     */
    
#endif
    if (bind(self.videofd, (struct sockaddr *)&myaddr,sizeof(myaddr)) < 0) {
        fprintf(stderr, "bind failed! (%s)\n", strerror(errno));
        shutdown(self.videofd, 2);
        close(self.videofd);
        self.videofd = -1;
        return -5;
    }
    
    return 0;
}

-(JPEG_BUFFER *)F_FindJpegBuffer:(int)njpginx
{
    if(self.jpg0.nJpegInx == njpginx)
        return self.jpg0;
    else if(self.jpg1.nJpegInx == njpginx)
        return self.jpg1;
    else if(self.jpg2.nJpegInx == njpginx)
        return self.jpg2;
    else if(self.jpg0.nJpegInx == 0) {
        [self.jpg0 Clear];
        return self.jpg0;
    }
    else if(self.jpg1.nJpegInx == 0) {
        [self.jpg1 Clear];
        return self.jpg1;
    }
    else if(self.jpg2.nJpegInx == 0) {
        [self.jpg2 Clear];
        return self.jpg2;
    }
    else
    {
        int ix0= self.jpg0.nJpegInx;
        int ix1= self.jpg1.nJpegInx;
        int ix2= self.jpg2.nJpegInx;
        if(ix0>ix1)
        {
            if(ix1>ix2)
            {
                [self.jpg2 Clear];
                return self.jpg2;
            }
            else
            {
                [self.jpg1 Clear];
                return self.jpg1;
            }
        }
        else
        {
            if(ix0<ix2)
            {
                [self.jpg0 Clear];
                return self.jpg0;
            }
            else
            {
                [self.jpg2 Clear];
                return self.jpg2;
            }
        }
    }
}



-(void)doReceiveGPRTP{
    memset(_readRtpBuffer, 0, 1600);
    NSLog(@"Start read RTPB data~~~");
    if(self.nIC_Type == IC_GPRTPB)
    {
        if(self.jpg0==nil)
        {
            self.jpg0 = [[JPEG_BUFFER alloc] init];
        }
        if(self.jpg1==nil)
        {
            self.jpg1 = [[JPEG_BUFFER alloc] init];
        }
        if(self.jpg2==nil)
        {
            self.jpg2 = [[JPEG_BUFFER alloc] init];
        }
    }
    
    
    if(_jpgbuffer!=NULL)
    {
        free(_jpgbuffer);
        _jpgbuffer=NULL;
    }
    if(_databuffer!=NULL)
    {
        free(_databuffer);
        _databuffer=NULL;
    }
    _databuffer =(char *) malloc(1450*32);//new char[1450*32];
    int LEN_Buffer = (1280*720*3)/2;
    _jpgbuffer = (char *) malloc(LEN_Buffer);
    __block int64_t  nTime1_pre=av_gettime()/1000;
    __block int64_t  nTime1_current;
    
    
    _isCancelled = NO;
    __weak JH_WifiCamera  *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        int size;
        NSMutableArray *dataList = [[NSMutableArray alloc] init];
        NSMutableArray *datalistDisp = [[NSMutableArray alloc] init];
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 1000*5;
        fd_set read_fd;
        ssize_t nbytes;
        __block  BOOL  bStart=NO;
        NSComparator cmptr = ^(id obj1a, id obj2a){
            NSData *obj1 = (NSData *)obj1a;
            NSData *obj2 = (NSData *)obj2a;
            Byte  *t1;
            Byte *t2;
            t1 =(Byte *)[obj1 bytes];
            t2 =(Byte *)[obj2 bytes];
            uint16_t i1 = t1[3]+t1[2]*0x100;
            uint16_t i2 = t2[3]+t2[2]*0x100;
            if (i1 > i2) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            else if (i1 < i2) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            else
                return (NSComparisonResult)NSOrderedSame;
        };
        NSData  *dataB;
        
        uint16_t jpginx=0;
        uint8_t jpg_pack_count=0;
        uint8_t jpg_udp_inx = 0;
        struct sockaddr_in servaddr;
        
        while (!weakself.isCancelled)
        {
            memset(&servaddr, 0, sizeof(servaddr));
            nTime1_current = av_gettime()/1000;
            if(nTime1_current-nTime1_pre>1000*2)
            {
                [weakself F_SentRTPHeartBeep];
                nTime1_pre = nTime1_current;
            }
            tv.tv_sec = 0;
            tv.tv_usec = 1000*5;
            FD_ZERO(&read_fd);
            FD_SET(weakself.videofd, &read_fd);
            int ret=select(weakself.videofd + 1, &read_fd, NULL, NULL, &tv);
            if(ret>0)
            {
                if (FD_ISSET(weakself.videofd, &read_fd))
                {
                    size = sizeof(servaddr);
                    nbytes = recvfrom(weakself.videofd, weakself.readRtpBuffer, 1600, 0, (struct sockaddr*)&servaddr, (socklen_t *)&size);
                    [weakself.packetLock lock];
                    weakself.nRelinkTime = 0;
                    [weakself.packetLock unlock];
                    if(self.nIC_Type == IC_GPRTPB)
                    {
                        //@autoreleasepool
                        {
                            if (nbytes >= 9)
                            {
                                jpginx =  weakself.readRtpBuffer[1] * 0x100 + weakself.readRtpBuffer[0];
                                jpg_pack_count = (uint8_t) weakself.readRtpBuffer[2];
                                jpg_udp_inx = (uint8_t) weakself.readRtpBuffer[3];
                                if(jpg_udp_inx>100)
                                    continue;
                                JPEG_BUFFER *jpg = [self F_FindJpegBuffer:jpginx];
                                if(jpg.nJpegInx== 0 || jpg.nJpegInx == jpginx) {
                                    jpg.nJpegInx = jpginx;
                                }
                                else
                                {
                                    NSLog(@"Find packed error!");
                                }
                                if (jpg_udp_inx * (1045-8) + (1450-8) < 60*1024)
                                {
                                    if(jpg->mInx[jpg_udp_inx] == 0)
                                    {
                                        jpg->mInx[jpg_udp_inx] = 1;
                                        
                                        if(jpg_udp_inx * (1450 - 8)+1450 - 8 < 400*1024)     //防止图片太大出现溢出
                                        {
                                            memcpy(jpg.buffer + jpg_udp_inx * (1450 - 8), weakself.readRtpBuffer + 8,1450 - 8);
                                        }
                                        jpg.nCount++;
                                    }
                                    else
                                    {
                                        ;
                                        // NSLog(@"Duplicate Recivied  packet  %d of %d",jpg_udp_inx,jpginx);
                                    }
                                    if (jpg.nCount >= jpg_pack_count)
                                    {
                                        bool bOK=true;
                                        for(int ix=0;ix<jpg_pack_count;ix++)
                                        {
                                            if(jpg->mInx[ix]==0)
                                            {
                                                bOK=false;
                                                break;
                                            }
                                        }
                                        if(bOK)
                                        {
                                            NSData *frame_ = [NSData  dataWithBytes:jpg.buffer length:jpg_pack_count * (1450 - 8)];
                                            [weakself DecordData_Mjpeg:frame_];
                                        }
                                        else
                                        {
                                            NSLog(@"receive error!");
                                        }
                                        [jpg Clear];
                                        
                                    }
                                }
                                
                            }
                        }
                        
                        
                    }
                    
                    if(self.nIC_Type == IC_GPRTP)
                    {
                        if(nbytes>20)
                        {
                            @autoreleasepool
                            {
                                NSData  *data = nil;
                                
                                data = [NSData dataWithBytes:weakself.readRtpBuffer length:nbytes];
                                [dataList addObject:data];
                                if(dataList.count>20)
                                {
                                    [dataList sortUsingComparator:cmptr];
                                    
                                    while(dataList.count>0)
                                    {
                                        dataB = dataList[0];
                                        Byte *buff=(Byte *)[dataB bytes];
                                        if(buff[1] & 0x80)
                                        {
                                            if(bStart)
                                            {
                                                [datalistDisp addObject:dataB];
                                                BOOL  bOK=YES;
                                                int nStartInx=0;
                                                int nCurrentInx=0;
                                                for(int i=0;i<datalistDisp.count;i++)
                                                {
                                                    NSData *da = datalistDisp[i];
                                                    Byte *dabuff =(Byte *)[da bytes];
                                                    if(i==0)
                                                    {
                                                        nStartInx = dabuff[3]+ dabuff[2]*0x100;
                                                    }
                                                    else
                                                    {
                                                        nCurrentInx = dabuff[3]+ dabuff[2]*0x100;
                                                        if(nCurrentInx-nStartInx!=1)
                                                        {
                                                            bOK = NO;
                                                            //NSLog(@"Loss packet!");
                                                            break;
                                                        }
                                                        nStartInx = nCurrentInx;
                                                    }
                                                }
                                                if(bOK)
                                                {
                                                    int ix=0;
                                                    for(int i=0;i<datalistDisp.count;i++)
                                                    {
                                                        NSData *da = datalistDisp[i];
                                                        Byte *dabuff =(Byte *)[da bytes];
                                                        if(ix+da.length-20<LEN_Buffer)
                                                        {
                                                            memcpy(weakself.jpgbuffer+ix,&(dabuff[20]),da.length-20);
                                                            ix+=da.length-20;
                                                        }
                                                        else
                                                        {
                                                            bOK = NO;
                                                            break;
                                                        }
                                                    }
                                                    if(bOK)
                                                    {
                                                        NSData *frame_ = [NSData  dataWithBytes:weakself.jpgbuffer length:ix];
                                                        [weakself DecordData_Mjpeg:frame_];
                                                    }
                                                }
                                            }
                                            
                                            [datalistDisp removeAllObjects];
                                            bStart = YES;
                                        }
                                        else
                                        {
                                            if(bStart)
                                            {
                                                [datalistDisp addObject:dataB];
                                            }
                                        }
                                        [dataList removeObjectAtIndex:0];
                                    } //while
                                }
                            }
                        }
                    }
                }
            }
            usleep(1000*1.5);
        }
        [weakself F_SentRTPStop];
        usleep(1000*5);
        [weakself F_SentRTPStop];
        
        if(weakself.jpgbuffer!=NULL)
        {
            free(weakself.jpgbuffer);
            weakself.jpgbuffer=NULL;
        }
        if(weakself.databuffer!=NULL)
        {
            free(weakself.databuffer);
            weakself.databuffer=NULL;
        }
        
        [datalistDisp removeAllObjects];
        [dataList removeAllObjects];
        NSLog(@"Exit ReadThread");
        
    });
}


-(void)F_SentRTPStop
{
    Byte cmd[20];
    
    cmd[0] = 'J';
    cmd[1] = 'H';
    cmd[2] = 'C';
    cmd[3] = 'M';
    cmd[4] = 'D';
    cmd[5] = 0xD0;
    cmd[6] = 0x02;
    
    NSData *dat = [[NSData alloc] initWithBytes:cmd length:7];
    
    [self F_SentUdp:dat Server:self.sSerVerIP Port:20000];
    
}


-(void)F_SentRTPHeartBeep
{
    Byte cmd[20];
    
    cmd[0] = 'J';
    cmd[1] = 'H';
    cmd[2] = 'C';
    cmd[3] = 'M';
    cmd[4] = 'D';
    cmd[5] = 0xD0;
    cmd[6] = 0x01;
    
    NSData *dat = [[NSData alloc] initWithBytes:cmd length:7];
    
    [self F_SentUdp:dat Server:self.sSerVerIP Port:20000];
    
}

#pragma mark  SONix
- (int)createVideoSocket {
    
    self.videofd = -1;
    uartCommandfd=-1;
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000*10;
    
    struct sockaddr_in myaddr;
    if ((self.videofd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        printf("Failed to create socket\n");
        return -1;
    }
    
    // set timeout to 1 seconds.
    //struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 500000;
    
    if (setsockopt(self.videofd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
        printf("Failed to setsockopt\n");
        shutdown(self.videofd, 2);
        close(self.videofd);
        self.videofd = -1;
        return -2;
        
    }
    
    bzero((char *)&myaddr, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    myaddr.sin_port = htons(VIDEO_SOCKET_PORT);
    
    
    //chinwei 20160503
    //int value = 1;
    int status = 0;
    //status = setsockopt(videofd, SOL_SOCKET, SO_REUSEADDR, &value, sizeof(value));
    
    if (status) {
        fprintf(stderr, "SO_REUSEADDR failed! (%s)\n", strerror(errno));
        shutdown(self.videofd, 2);
        close(self.videofd);
        self.videofd = -1;
        return -3;
        
    }
    //status = setsockopt(videofd, SOL_SOCKET, SO_REUSEPORT, &value, sizeof(value));
    if (status) {
        fprintf(stderr, "SO_REUSEPORT failed! (%s)\n", strerror(errno));
        shutdown(self.videofd, 2);
        close(self.videofd);
        self.videofd = -1;
        return -4;
        
    }
    
    if (bind(self.videofd, (struct sockaddr *)&myaddr,
             sizeof(myaddr)) < 0) {
        fprintf(stderr, "bind failed! (%s)\n", strerror(errno));
        shutdown(self.videofd, 2);
        close(self.videofd);
        self.videofd = -1;
        return -5;
    }
    
    return 0;
    
}

- (void)doReceive
{
    _isCancelled = NO;
    __weak JH_WifiCamera  *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        char buf_[PACKET_SIZE];  /*server response */
        struct sockaddr_in servaddr; /* the server's full addr */
        bzero((char *)&servaddr, sizeof(servaddr));
        ssize_t nbytes; /* the number of read **/
        int size;    /* the length of servaddr */
        
        
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 1000;
        
        fd_set read_fd;
        
        
        
        while (!weakself.isCancelled)
        {
            FD_ZERO(&read_fd);
            FD_SET(weakself.videofd, &read_fd);
            
            tv.tv_sec = 0;
            tv.tv_usec = 1000*5;
            select(weakself.videofd + 1, &read_fd, NULL, NULL, &tv);
            if (FD_ISSET(weakself.videofd, &read_fd)) {
                memset(buf_, 0, PACKET_SIZE);
                size = sizeof(servaddr);
                if ((nbytes = recvfrom(weakself.videofd, &buf_, PACKET_SIZE, 0, (struct sockaddr*)&servaddr, (socklen_t *)&size)) < 0) {
                    usleep(2);
                    continue;
                }
                NSData *recv_ = [NSData dataWithBytes:buf_ length:nbytes];
                [weakself.packetLock lock];
                [weakself.packets addObject:recv_];
                [weakself.packetLock unlock];
            }
        }
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (!weakself.isCancelled)
        {
            @autoreleasepool {
                NSData *packet_ = nil;
                [weakself.packetLock lock];
                if (weakself.packets.count) {
                    packet_ = [[weakself.packets objectAtIndex:0] copy];
                    [weakself.packets removeObjectAtIndex:0];
                }
                [weakself.packetLock unlock];
                if(packet_)
                    [weakself parsePacket:packet_ length:packet_.length];
                usleep(100);
            }
        }
    });
}


- (void)stopReceive
{
    self.isCancelled = YES;
}

-(void)ClearData
{
    _packData = _packDataA;
    _packData_Inx = 0;
    
}

-(int)F_Append:(Byte *)bytes length:(int)nLen
{
    if(self.packData_Inx+nLen>1024*1024*2)
    {
        return -1;
    }
    memcpy(_packData, bytes, nLen);
    _packData+=nLen;
    self.packData_Inx+=nLen;
    return self.packData_Inx;
    
}

- (void)parsePacket:(NSData *)packeta length:(NSInteger)length
{
    if (length != PACKET_SIZE) {
        //NSLog(@"size error %zd",length);
        return;
    }
    
    
    @autoreleasepool
    {
        
        Byte packet_[PACKET_SIZE];
        [packeta getBytes:packet_ length:PACKET_SIZE];
        
        if (packet_[PACKET_SIZE -3 ] == 0xda && packet_[PACKET_SIZE-4] == 0xff )
        {
            [self ClearData];
            [self F_Append:packet_ length:(PACKET_SIZE - 4)];
            mIsFirstPacket = YES;
            indexForPacket = 1;
            return;
        }
        if(mIsFirstPacket)
        {
            if (packet_[PACKET_SIZE +1-4 ] == 0xdd && packet_[PACKET_SIZE-4] == 0xff )
            {
                NSInteger nPack = ((int)((packet_[PACKET_SIZE - 2])<<8) | packet_[PACKET_SIZE - 1]);
                if(indexForPacket==nPack)
                {
                    [self F_Append:packet_ length:(PACKET_SIZE - 4)];
                    indexForPacket++;
                }
                else
                {
                    mIsFirstPacket = NO;
                }
            }
            else if(packet_[PACKET_SIZE +1-4 ] == 0xd9)
            {
                NSInteger nPack = ((int)((packet_[PACKET_SIZE - 2])<<8) | packet_[PACKET_SIZE - 1]);
                if(indexForPacket==nPack)
                {
                    [self F_Append:packet_ length:(PACKET_SIZE - 4)];
                    mIsFirstPacket = NO;
                    _qValue = packet_[PACKET_SIZE - 4] * 5 + 5;
                    
                    NSData *header = nil;
                    if (_qValue == 10) {
                        header = self.header10;
                    }else if (_qValue == 15) {
                        header = self.header15;
                    }else if (_qValue == 20) {
                        header = self.header20;
                    }else if (_qValue == 25) {
                        header = self.header25;
                    }else if (_qValue == 30) {
                        header = self.header30;
                    }else if (_qValue == 35) {
                        header = self.header35;
                    }else if (_qValue == 40) {
                        header = self.header40;
                    }else if (_qValue == 45) {
                        header = self.header45;
                    }else if (_qValue == 50) {
                        header = self.header50;
                    }
                    if(self.packData_Inx>212)
                    {
                        Byte *tmp = _packDataA+212;
                        NSData *payload_ = [NSData dataWithBytes:tmp  length:_packData_Inx-212];
                        [self merageMJPGHeader:header payload:payload_];
                        //[self ClearData];
                    }
                }
                else
                {
                    mIsFirstPacket=NO;
                }
            }
        }
    }
}

-(UIImage *)image:(UIImage *)image rotation:(UIImageOrientation)orientation
{
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    return newPic;
}


- (void)merageMJPGHeader:(NSData *)header payload:(NSData *)payload
{
    @autoreleasepool
    {
        [self.mjpgFrame setLength:0];
        if(header)
            [self.mjpgFrame appendData:header];
        if(payload)
            [self.mjpgFrame appendData:payload];
        Byte EOI[]={0xff,0xd9};
        [self.mjpgFrame appendBytes:EOI length:2];
        __block NSData *frame_ = [NSData dataWithData:self.mjpgFrame];
        [self DecordData_Mjpeg:frame_];
    }
}

- (void)closeVideoSocket {
    
    
    self.isCancelled = YES;
    usleep(1000*20);
    if (self.videofd > 0) {
        NSLog(@"videosocket close!");
        shutdown(self.videofd, 2);
        close(self.videofd);
        self.videofd = -1;
    }
}


- (void)createCommandSocket {
    
    commandfd = -1;
    struct sockaddr_in myaddr;
    
    
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000*10;
    
    //if(uartCommandfd<0)
    {
        uartCommandfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if(uartCommandfd>=0)
        {
            setsockopt(uartCommandfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));
        }
    }
    
    
    /* Create the UDP socket */
    if ((commandfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) < 0) {
        printf("Failed to create socket\n");
        return;
    }
    
    // set timeout to 1 seconds.
    tv.tv_sec = 0;
    tv.tv_usec = 500000;
    
    if (setsockopt(commandfd, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv)) < 0) {
        printf("Failed to setsockopt\n");
        shutdown(commandfd, 2);
        close(commandfd);
        commandfd = -1;
        return;
    }
    
    //chinwei 20160503
    int value = 1;
    int status;
    status = setsockopt(commandfd, SOL_SOCKET, SO_REUSEADDR, &value, sizeof(value));
    
    if (status) {
        fprintf(stderr, "SO_REUSEADDR failed! (%s)\n", strerror(errno));
        shutdown(commandfd, 2);
        close(commandfd);
        commandfd = -1;
        
        return;
    }
    status = setsockopt(commandfd, SOL_SOCKET, SO_REUSEPORT, &value, sizeof(value));
    if (status) {
        fprintf(stderr, "SO_REUSEPORT failed! (%s)\n", strerror(errno));
        shutdown(commandfd, 2);
        close(commandfd);
        commandfd = -1;
        
        return;
    }
    
    bzero((char *)&myaddr, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    myaddr.sin_port = htons(0);
    
    if (bind(commandfd, (struct sockaddr *)&myaddr,
             sizeof(myaddr)) <0) {
        printf("CommandSocket bind failed!\n");
        shutdown(commandfd, 2);
        close(commandfd);
        commandfd = -1;
        return;
    }
    _alreadyBind = YES;
    _isWaiting = YES;
}


- (void)closeCommandSocket {
    _isWaiting = NO;
    _alreadyBind = NO;
    
    if(commandfd<0)
        return;
    
    if (commandfd > 0) {
        NSLog(@"command close!");
        shutdown(commandfd, 2);
        close(commandfd);
        
        commandfd = -1;
        
    }
    
}


-(BOOL)naGetConnected;  //bConnectedO
{
    return self.bConnectedOK;
}

- (void)sendCommand_SN:(NSData *)command length:(NSInteger)length {
    
    
    int udpsocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(udpsocket<0)
        return;
    
    unsigned int size;    /* the length of servaddr */
    struct sockaddr_in servaddr; /* the server's full addr */
    char data[1024];  /* request */
    
    memset(data, 0, 1024);
    memcpy(data, [command bytes], length);
    
    bzero((char *)&servaddr, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(COMMAND_SOCKET_PORT);
    servaddr.sin_addr.s_addr = inet_addr([self.sSerVerIP UTF8String]);
    
    size = sizeof(servaddr);
    ssize_t res = sendto(udpsocket, data, length, 0, (struct sockaddr *)&servaddr, size);
    if (res < 0) {
        perror("write error");
    }
    close(udpsocket);
    
    
}


-(void)naSentStopCtrol
{
    if(commandfd<0)
        return;
    Byte buf_[2] = {COMMAND_TAG, COMMAND_STOPCTROL};
    NSData *cmd_ = [NSData dataWithBytes:buf_ length:sizeof(buf_)];
    
    for (int i = 0; i < 2; i++)
    {
        [self sendCommand_SN:cmd_ length:cmd_.length];
        usleep(4000);
    }
}

- (void)sendStart {
    if(commandfd<0)
        return;
    // NSLog(@"%s",__func__);
    Byte buf_[2] = {COMMAND_TAG, COMMAND_START};
    NSData *cmd_ = [NSData dataWithBytes:buf_ length:sizeof(buf_)];
    
    //for (int i = 0; i < 5; i++)
    {
        [self sendCommand_SN:cmd_ length:cmd_.length];
    }
}

- (void)sendGetCfg_Cmd {
    if(commandfd<0)
        return;
    // NSLog(@"%s",__func__);
    Byte buf_[2] = {COMMAND_TAG, COMMAND_GETCFG};
    NSData *cmd_ = [NSData dataWithBytes:buf_ length:sizeof(buf_)];
    //for (int i = 0; i < 5; i++)
    {
        [self sendCommand_SN:cmd_ length:cmd_.length];
    }
}


- (void)sendStop {
    if(commandfd<0)
        return;
    //NSLog(@"%s",__func__);
    
    Byte buf_[2] = {COMMAND_TAG, COMMAND_STOP};
    NSData *cmd_ = [NSData dataWithBytes:buf_ length:sizeof(buf_)];
    
    //for (int i = 0; i < 5; i++)
    {
        [self sendCommand_SN:cmd_ length:cmd_.length];
    }
    
}



-(void)F_DispBack:(UIImage  *)image
{
    if(!image)
        return;
    if(!self.dispView)
        return;
    
    AVFrame *frame_rec;
    AVFrame *back_frame;
    AVFrame  *frame_aa;
    AVFrame  *frame_bb;
    struct SwsContext *img_convert_ctx_half_aa;
    img_convert_ctx_half_aa = sws_getContext(640, 360, AV_PIX_FMT_YUV420P,
                                             640/2, 360/2, AV_PIX_FMT_YUV420P, SWS_FAST_BILINEAR, NULL, NULL, NULL); //
    
    
    // if(m_bSaveVideo && m_outFmt!=NULL && frame_rec!=NULL)
    {
        CGImageRef newCgImage = image.CGImage;          // [image CGImageForProposedRect:nil context:nil hints:nil];
        if(newCgImage==NULL)
            return;
        
        
        CGImageGetBitsPerComponent(newCgImage);
        CGImageGetBitsPerPixel(newCgImage);
        int  nLinexBytes = (int)CGImageGetBytesPerRow(newCgImage);
        int  h =(int) CGImageGetHeight(newCgImage);
        int  w =(int) CGImageGetWidth(newCgImage);
        
        frame_bb = av_frame_alloc();
        frame_bb->format = AV_PIX_FMT_YUV420P;
        frame_bb->width = 640/2;
        frame_bb->height = 360/2;
        av_image_alloc(frame_bb->data, frame_bb->linesize, 640/2,
                       360/2,
                       AV_PIX_FMT_YUV420P,4);
        
        frame_aa = av_frame_alloc();
        frame_aa->format = AV_PIX_FMT_YUV420P;
        frame_aa->width = 640;
        frame_aa->height = 360;
        av_image_alloc(frame_aa->data, frame_aa->linesize, 640,
                       360,
                       AV_PIX_FMT_YUV420P,4);
        
        frame_rec = av_frame_alloc();
        back_frame = av_frame_alloc();
        back_frame->format = AV_PIX_FMT_YUV420P;
        back_frame->width = 640;
        back_frame->height = 360;
        av_image_alloc(back_frame->data, back_frame->linesize, 640,
                       360,
                       AV_PIX_FMT_YUV420P, 4);
        
        
        frame_rec->format = AV_PIX_FMT_BGRA;
        frame_rec->width = w;
        frame_rec->height = h;
        av_image_alloc(frame_rec->data, frame_rec->linesize, frame_rec->width,
                       frame_rec->height,
                       AV_PIX_FMT_BGRA, 4);
        
        
        struct SwsContext *back_sws = sws_getContext(
                                                     frame_rec->width,
                                                     frame_rec->height,
                                                     AV_PIX_FMT_BGRA,
                                                     640,
                                                     360,
                                                     AV_PIX_FMT_YUV420P,
                                                     SWS_FAST_BILINEAR, NULL, NULL, NULL);
        
        CGDataProviderRef dataProvider = CGImageGetDataProvider(newCgImage);
        CFDataRef bitmapData = CGDataProviderCopyData(dataProvider);
        uint8_t *buffera = (uint8_t *)CFDataGetBytePtr(bitmapData);
        
        frame_rec->linesize[0] =(int)nLinexBytes;
        memcpy(&(frame_rec->data[0][0]), &(buffera[0]), nLinexBytes*h);
        CFRelease(bitmapData);
        
        //int nLine =
        sws_scale(back_sws,
                  (const uint8_t *const *)(frame_rec->data),
                  frame_rec->linesize,
                  0,
                  frame_rec->height,
                  back_frame->data,
                  back_frame->linesize);
        
        if(!self.bSetDispBack_VerB)
        {
            if(self.bFlip)
            {
                //[self frame_rotate_180:back_frame DesFrame:frame_aa];
                //av_frame_copy(back_frame, frame_aa);
                I420Rotate(back_frame->data[0], back_frame->linesize[0],
                           back_frame->data[1], back_frame->linesize[1],
                           back_frame->data[2], back_frame->linesize[2],
                           frame_aa->data[0], frame_aa->linesize[0],
                           frame_aa->data[1], frame_aa->linesize[1],
                           frame_aa->data[2], frame_aa->linesize[2],
                           frame_aa->width, frame_aa->height,kRotate180);
                
                
                I420Copy(frame_aa->data[0], frame_aa->linesize[0],
                         frame_aa->data[1], frame_aa->linesize[1],
                         frame_aa->data[2], frame_aa->linesize[2],
                         back_frame->data[0], back_frame->linesize[0],
                         back_frame->data[1], back_frame->linesize[1],
                         back_frame->data[2], back_frame->linesize[2],
                         frame_aa->width, frame_aa->height);
            }
        }
        
        if(self.b3D)
        {
#if 1
            I420Scale(back_frame->data[0], back_frame->linesize[0],
                      back_frame->data[1], back_frame->linesize[1],
                      back_frame->data[2], back_frame->linesize[2],
                      back_frame->width, back_frame->height,
                      frame_bb->data[0], frame_bb->linesize[0],
                      frame_bb->data[1], frame_bb->linesize[1],
                      frame_bb->data[2], frame_bb->linesize[2],
                      frame_bb->width, frame_bb->height, kFilterBilinear);
            
#else
            
            sws_scale(img_convert_ctx_half_aa,
                      (const uint8_t *const *) back_frame->data,
                      back_frame->linesize, 0,
                      360,
                      frame_bb->data, frame_bb->linesize);
#endif
            
            [self frame_link2frame:frame_bb DES:back_frame];;
        }
        
        
        [self.dispView displayYUV420pData:back_frame->data[0] width:640 height:360];
        
        av_freep(&frame_rec->data[0]);
        av_freep(&back_frame->data[0]);
        
        av_freep(&frame_aa->data[0]);
        av_freep(&frame_bb->data[0]);
        
        
        av_frame_free(&back_frame);
        av_frame_free(&frame_rec);
        av_frame_free(&frame_aa);
        av_frame_free(&frame_bb);
        sws_freeContext(back_sws);
        sws_freeContext(img_convert_ctx_half_aa);
        
    }
    
}

#pragma mark GK
#if 0
#endif
//*****

-(int)naSet3DA:(BOOL)b3D
{
    self.b3D = b3D;
    self.b3DA = NO;
    if(!self.bConnectedOK)
    {
        [self  F_DispBack:self.dispBackImg];
    }
    return 0;
}


-(int)naSet3D:(BOOL)b3D
{
    self.b3D = b3D;
    self.b3DA = YES;
    if(!self.bConnectedOK)
    {
        [self  F_DispBack:self.dispBackImg];
    }
    return 0;
}

-(int)naSetFilp:(BOOL)bFlipa
{
    self.bFlip = bFlipa;
    if(!self.bConnectedOK)
    {
        [self  F_DispBack:self.dispBackImg];
    }
    return 0;
}

-(int)naSetUartConfig:(int32_t )nSpeed  bitlen:(int32_t)nLen  stopLen:(int32_t)nStopLen   verifi:(char)cVeerifi
{
    if(self.nIC_Type == IC_GKA)
    {
        //if(!self.bVaild)
        //    return -100;
        
        T_NET_CMD_MSG Cmd;
        T_NET_CONFIG  configA;
        T_NET_SERIAL_INFO  config;
        if(nSpeed != 2400 && nSpeed != 4800 && nSpeed != 9600 && nSpeed != 19200 && nSpeed != 38400 && nSpeed != 115200)
        {
            return -2;
        }
        //NOPARITY、ODDPARITY、EVENPARITY、MARKPARITY、SPACEPARITY，分别表示无校验、奇校验、偶校验、校验置位（标记校验）、校验清零。
        if(cVeerifi !='N' && cVeerifi !='O'  && cVeerifi !='E' &&  cVeerifi !='M'  && cVeerifi !='S' &&
           cVeerifi !='n' && cVeerifi !='o'  && cVeerifi !='e' &&  cVeerifi !='m'  && cVeerifi !='s')
        {
            return -3;
        }
        if(self.session_id<=0)
        {
            return -4;
        }
        
        
        
        Cmd.type=CMD_SET_CONFIG;
        Cmd.session_id = self.session_id;
        
        configA.type = CONFIG_SERIAL;
        configA.res = 0;
        
        config.nSpeed = nSpeed;
        config.nBits = nLen;
        config.nStop = nStopLen;
        config.nEvent = cVeerifi;
        
        NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
        NSData *data =  [NSData dataWithBytes:&configA length:sizeof(T_NET_CONFIG)];
        NSData *data1 = [NSData dataWithBytes:&config length:sizeof(T_NET_SERIAL_INFO)];
        [sendData appendData:data];
        [sendData appendData:data1];
        //[self.GK_tcp_SendSocket1 Write:sendData];
        //[self F_ReadAck];
        
        [_GKA_Cmd_Socket Write:sendData];
        [self F_ReadAck:150];
        //[self.GK_tcp_SendSocket writeData:sendData withTimeout:100 tag:Tag_SetUart];
        return 0;
    }
    else
    {
        NSLog(@"No support config uart!");
        return -1;
    }
}




-(void)SaveVideo{
    
    if(m_bSaveVideo)
    {
        MyFrame *mFrame = [[MyFrame alloc] init];
        mFrame->pFrame = av_frame_alloc();
        mFrame->pFrame->width=_nRecordWidth;
        mFrame->pFrame->height=_nRecordHeight;
        av_image_alloc(
                       mFrame->pFrame->data, mFrame->pFrame->linesize, _nRecordWidth,
                       _nRecordHeight,
                       AV_PIX_FMT_YUV420P, 4);
        if(pFrameYUV->width != _nRecordWidth || pFrameYUV->height!=_nRecordHeight)
        {
            I420Scale(pFrameYUV->data[0], pFrameYUV->linesize[0],
                      pFrameYUV->data[1], pFrameYUV->linesize[1],
                      pFrameYUV->data[2], pFrameYUV->linesize[2],
                      pFrameYUV->width, pFrameYUV->height,
                      mFrame->pFrame->data[0], mFrame->pFrame->linesize[0],
                      mFrame->pFrame->data[1], mFrame->pFrame->linesize[1],
                      mFrame->pFrame->data[2], mFrame->pFrame->linesize[2],
                      mFrame->pFrame->width, mFrame->pFrame->height, kFilterBilinear);
        }
        else
        {
            I420Copy(pFrameYUV->data[0], pFrameYUV->linesize[0],
                     pFrameYUV->data[1], pFrameYUV->linesize[1],
                     pFrameYUV->data[2], pFrameYUV->linesize[2],
                     mFrame->pFrame->data[0], mFrame->pFrame->linesize[0],
                     mFrame->pFrame->data[1], mFrame->pFrame->linesize[1],
                     mFrame->pFrame->data[2], mFrame->pFrame->linesize[2],
                     mFrame->pFrame->width, mFrame->pFrame->height);
        }
        @synchronized(videoFrames)
        {
            if(videoFrames.count>=5)
            {
                MyFrame *tempFrame = videoFrames[0];
                [videoFrames removeObjectAtIndex:0];
                av_freep(&(tempFrame->pFrame->data[0]));
                av_frame_free(&(tempFrame->pFrame));
                
            }
            [videoFrames addObject:mFrame];
        }
        
    }
}

-(void)F_SentHeartBeep
{
    T_REQ_MSG *pmsg;
    T_NET_CMD_MSG Cmd;
    NSData *data;
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_KEEP_LIVE;
    data = [NSData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    if(_GKA_Cmd_Socket.bConnected)
    {
        [_GKA_Cmd_Socket Write:data];
        data = [_GKA_Cmd_Socket Read:sizeof(T_REQ_MSG) timeout:200];
        if(data && data.length == sizeof(T_REQ_MSG))
        {
            //[data getBytes:&msg length:sizeof(T_REQ_MSG)];
            pmsg = (T_REQ_MSG *)[data bytes];
            
            if(pmsg->ret == 0)
            {
                self.bVaild = YES;
                self.nVaildT = 0;
            }
            /*
             else
             {
             self.nVaildT++;
             if(self.nVaildT>=10)
             {
             self.nVaildT=10;
             //self.bVaild = NO;
             }
             }
             */
        }
    }
}

-(void)F_StartHeartThread
{
    //[self F_SentHeartBeep];
    __weak JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UInt16  ms = 0;
        while(weakself.GKA_Cmd_Socket.bConnected)
        {
            ms++;
            if(ms>=50)  //50 *10ms == 0.5sec
            {
                ms = 0;
                [weakself F_SentHeartBeep];
            }
            usleep(1000*10);  //10ms
        }
        NSLog(@"stop Send heart");
    });
}


-(int)F_Login
{
    NSMutableData *senddata;
    NSData *data;
    T_NET_CMD_MSG Cmd;
    Cmd.session_id = 0;
    Cmd.type = CMD_LOGIN;
    T_NET_LOGIN user;
    memset(user.passwd, 0, 100);
    memset(user.user, 0, 100);
    if(self.sCustomer)
    {
        if(self.sCustomer.length<255)
        {
            const char *sp=[self.sCustomer UTF8String];
            memcpy(user.user,sp,self.sCustomer.length);
            NSLog(@"set Customer=%@",self.sCustomer);
        }
    }
    senddata = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    data = [NSData dataWithBytes:&user length:sizeof(T_NET_LOGIN)];
    [senddata appendData:data];
    [_GKA_Cmd_Socket Write:senddata];
    return [self F_ReadAck:1200];
    
    
}

-(int)F_AdjTime
{
    T_NET_CMD_MSG Cmd;
    if(self.session_id <=0)
    {
        return -1;
    }
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_ADJUST_TIME;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    T_NET_DATE_TIME date;
    NSCalendar *curCalendar = [NSCalendar currentCalendar];
    NSUInteger unitFlags = NSCalendarUnitYear| NSCalendarUnitMonth| NSCalendarUnitDay| NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *dateComponents = [curCalendar components:unitFlags fromDate:[NSDate date]];
    date.usYear =dateComponents.year;
    date.usMonth=dateComponents.month;
    date.usDay=dateComponents.day;
    date.ucHour=dateComponents.hour;
    date.ucMin =dateComponents.minute;
    date.ucSec =dateComponents.second;
    NSData *data = [NSData dataWithBytes:&date length:sizeof(T_NET_DATE_TIME)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    return [self F_ReadAck:1200];
}

-(int)naYD_SetFps:(int)nFpsA
{
    return [self F_SetFps:_nSetStream FPS:nFpsA];
}

-(int)F_SetFps:(int)nChancel FPS:(int)nFpsA
{
    if(video_info_A.width==0)
        return -1;
    NSLog(@"Reset fps");
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG config;
    
    video_info_A.fps = nFpsA;
    video_info_A.i_interval = nFpsA;
    nFps =nFpsA;
    
    Cmd.session_id = _session_id;
    Cmd.type = CMD_SET_CONFIG;
    config.type = CONFIG_VIDEO;
    config.res = nChancel;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    NSData *data1 = [NSData dataWithBytes:&video_info_A length:sizeof(T_NET_VIDEO_INFO)];
    [sendData appendData:data];
    [sendData appendData:data1];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:1000];
    if(req_msg.ret==0)
    {
        ;
    }
    return 0;
}

-(NSString *)F_GetFirewareVer
{
    GK_NET_VENDOR_CFG  *VENDOR_info;
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG config;
    
    Cmd.session_id = _session_id;
    Cmd.type = CMD_GET_CONFIG;
    config.type = CONFIG_VENDOR_INFO;
    config.res = 0;
    
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    if([self F_ReadAck:1200]==0)
    {
        NSData *dat = [_GKA_Cmd_Socket Read:sizeof(GK_NET_VENDOR_CFG) timeout:1200];
        if(dat && dat.length==sizeof(GK_NET_VENDOR_CFG))
        {
            VENDOR_info =(GK_NET_VENDOR_CFG *)[dat bytes];
            NSString *str =[NSString stringWithUTF8String:(const char *)VENDOR_info->firmware_version];
            return str;
        }
    }
    return @"";
}


-(int)F_GetFps:(int)nChancel
{
    video_info_A.width = 0;
    T_NET_VIDEO_INFO  *video_info;
    
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG config;
    if(self.session_id <=0)
    {
        return -1;
    }
    
    Cmd.session_id = _session_id;
    Cmd.type = CMD_GET_CONFIG;
    
    config.type = CONFIG_VIDEO;
    config.res = nChancel;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    if([self F_ReadAck:1200]==0)
    {
        NSData *dat = [_GKA_Cmd_Socket Read:sizeof(T_NET_VIDEO_INFO) timeout:1000];
        if(dat && dat.length==sizeof(T_NET_VIDEO_INFO))
        {
            video_info =(T_NET_VIDEO_INFO *)[dat bytes];
            if(video_info->fps>30)
            {
                video_info->fps = 30;
            }
            else if(video_info->fps<10)
            {
                video_info->fps = 10;
                
            }
            nFps = video_info->fps;
            memcpy(&video_info_A,video_info,sizeof(T_NET_VIDEO_INFO));
            return 0;
        }
    }
    return -1;
}

-(int)F_OpenDataSocket:(int)nStream
{
    if([_GKA_Data_Socket Connect:GK_ServerIP PORT:GK_Port]<0)
    {
        return -1;
    }
    
    T_NET_CMD_MSG Cmd;
    T_NET_STREAM_CONTROL control;
    
    Cmd.type = CMD_DATA_SOCK;
    Cmd.session_id = _session_id;
    control.stream_type = nStream;
    
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&control length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Data_Socket Write:sendData];
    req_msg.ret = -1;
    NSData *dat = [_GKA_Data_Socket Read:sizeof(T_REQ_MSG) timeout:1000];
    if(dat && dat.length==sizeof(T_REQ_MSG))
    {
        memcpy(&req_msg, [dat bytes], sizeof(T_REQ_MSG));
        return req_msg.ret;
    }
    else
    {
        return -1;
    }
    
}

-(int )F_OpenVideoStream:(int)nStream
{
    T_NET_CMD_MSG Cmd;
    T_NET_STREAM_CONTROL  control;
    
    Cmd.type=CMD_OPEN_STREAM;
    Cmd.session_id = self.session_id;
    control.stream_type = nStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&control length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    return [self F_ReadAck:1200];
}
-(int )F_OpenVideoStream_A:(int)nStream
{
    T_NET_CMD_MSG Cmd;
    Cmd.type=CMD_OPEN_STREAM;
    Cmd.session_id = self.session_id;
    T_NET_STREAM_CONTROL  control;
    control.stream_type = nStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&control length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    //[self.GK_tcp_SendSocket1 Write:sendData];
    [_GKA_Cmd_Socket Write:sendData];
    return 0;
}



-(int )F_CloseVideoStream:(int)nStream
{
    T_NET_CMD_MSG Cmd;
    Cmd.type=CMD_CLOSE_STREAM;
    Cmd.session_id = self.session_id;
    T_NET_STREAM_CONTROL  control;
    control.stream_type = nStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&control length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:1200];
    return 0;
}


-(int )F_CloseVideoStream_A:(int)nStream
{
    T_NET_CMD_MSG Cmd;
    Cmd.type=CMD_CLOSE_STREAM;
    Cmd.session_id = self.session_id;
    T_NET_STREAM_CONTROL  control;
    control.stream_type = nStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&control length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:1000];
    return 0;
}


/*
 -(void)F_GetSDStatus
 {
 T_NET_CMD_MSG Cmd;
 Cmd.session_id = self.session_id;
 Cmd.type = CMD_GET_CONFIG;
 T_NET_CONFIG  config;
 config.type = CONFIG_SD_CARD;
 config.res = 0;
 NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
 NSData *data = [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
 [sendData appendData:data];
 [self.GK_tcp_SendSocket1 Write:sendData];
 int nsize = sizeof(T_NET_SDCARD_INFO)+sizeof(T_REQ_MSG);
 NSData *dat=[self.GK_tcp_SendSocket1 Read:nsize timeout:100];
 if(dat)
 {
 T_REQ_MSG req;
 T_NET_SDCARD_INFO  sdinfo;
 //[dat getBytes:&req length:sizeof(T_REQ_MSG)];
 //NSRange rang = {sizeof(T_REQ_MSG),sizeof(T_NET_SDCARD_INFO)};
 //[dat getBytes:&sdinfo range:rang];
 //NSLog(@"SD info ret = %d  info = %d",req.ret,sdinfo.sd_status);
 }
 [self.GK_tcp_SendSocket1 ReadA:4096];
 }
 */

-(int)F_CMD_FORCE_I
{
    T_NET_CMD_MSG Cmd;
    T_NET_STREAM_CONTROL streeam;
    
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_FORCE_I;
    streeam.stream_type = self.nSetStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data = [NSData dataWithBytes:&streeam length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    return [self F_ReadAck:1200];
}


-(int)F_GetSDStatus
{
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG  config;
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_GET_CONFIG;
    config.type =CONFIG_SD_CARD;
    config.res = 0;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    [sendData appendData:data];
    
    [_GKA_Cmd_Socket Write:sendData];
    
    T_NET_SDCARD_INFO  infoA;
    
    int nLend = sizeof(T_REQ_MSG)+sizeof(T_NET_SDCARD_INFO);
    NSData *dataA = [_GKA_Cmd_Socket Read:nLend timeout:1000];
    if(dataA && dataA.length==nLend)
    {
        [dataA getBytes:&req_msg length:sizeof(T_REQ_MSG)];
        if(req_msg.ret == 0)
        {
            
            
            NSRange rang = {sizeof(T_REQ_MSG),sizeof(T_NET_SDCARD_INFO)};
            [dataA getBytes:&infoA range:rang];
            [self F_AdjStatus:infoA.sd_status];
            return 0;
        }
    }
    return -10;
}

-(void)F_GetSDStatus_A
{
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG  config;
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_GET_CONFIG;
    config.type =CONFIG_SD_CARD;
    config.res = 0;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:1000];
    
}


//SD卡怕照

-(int)F_SD_Snap
{
    T_NET_CMD_MSG Cmd;
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_SNAP_TO_SD;
    T_NET_STREAM_CONTROL contrul;
    contrul.stream_type = 0;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&contrul length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    //[self.GK_tcp_SendSocket writeData:sendData withTimeout:100 tag:Tag_Cmd];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:1000];
    return 0;
}

//SD卡录像
-(int)F_SD_Start_Recrod
{
    T_NET_CMD_MSG Cmd;
    
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_SD_REC_START;
    T_NET_STREAM_CONTROL contrul;
    contrul.stream_type = 0;//self.nSetStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&contrul length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:1000];
    return 0;
}

//停止SD卡录像

-(int)F_SD_Stop_Recrod
{
    T_NET_CMD_MSG Cmd;
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_SD_REC_STOP;
    T_NET_STREAM_CONTROL contrul;
    contrul.stream_type = 0;//self.nSetStream;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&contrul length:sizeof(T_NET_STREAM_CONTROL)];
    [sendData appendData:data];
    [_GKA_Cmd_Socket Write:sendData];
    [self F_ReadAck:200];
    return 0;
}



-(void)F_GetVideos_GK_LangTong
{
#ifdef Langtong
    NSString *sStart = @"---Start Get Rec FILES LIST";
    NSString *sEnd = @"---End Get Rec FILES LIST";
    
    NSString *sUrlStr = @"http://192.168.234.1/sd1/VIDEO";
    NSError * error;
    [self.delegate GetFiles:sStart];
    NSString * dataString = [NSString stringWithContentsOfURL:[NSURL URLWithString:sUrlStr] encoding:NSUTF8StringEncoding error:&error];
    if (dataString != nil)
    {
        
        NSData *htmlData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        MyTFHpple *doc = [[MyTFHpple alloc] initWithHTMLData:htmlData];
        
        
        
        NSString *nodeString = @"//a";
        NSArray *elements  = [doc searchWithXPathQuery:nodeString]; //[xpathParser searchWithXPathQuery:nodeString];
        for (MyTFHppleElement *tempAElement in elements)
        {
            //获得标题
            NSString *fileNameA =  [tempAElement content];
            NSString *fileName = [fileNameA stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            fileName = [fileName uppercaseString];
            NSString *ext =[fileName pathExtension];
            
            if (ext && [ext compare:@"MP4"] == NSOrderedSame)
            {
                fileName = [NSString stringWithFormat:@"http://192.168.234.1/sd1/VIDEO/%@--0",fileName];
                [self.delegate GetFiles:fileName];
            }
        }
    }
    else
    {
        
    }
    [self.delegate GetFiles:sEnd];
#endif
    
}

-(void)F_GetPhotos_GK_LangTong
{
#ifdef Langtong
    NSString *sStart = @"---Start Get SNAP FILES LIST";
    NSString *sEnd = @"---End Get SNAP FILES LIST";
    
    NSString *sUrlStr = @"http://192.168.234.1/sd1/PHOTO";
    NSError * error;
    [self.delegate GetFiles:sStart];
    NSString * dataString = [NSString stringWithContentsOfURL:[NSURL URLWithString:sUrlStr] encoding:NSUTF8StringEncoding error:&error];
    if (dataString != nil)
    {
        
        NSData *htmlData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
        MyTFHpple *doc = [[MyTFHpple alloc] initWithHTMLData:htmlData];
        
        NSString *nodeString = @"//a";
        NSArray *elements  = [doc searchWithXPathQuery:nodeString]; //[xpathParser searchWithXPathQuery:nodeString];
        for (MyTFHppleElement *tempAElement in elements)
        {
            //获得标题
            NSString *fileNameA =  [tempAElement content];
            NSString *fileName = [fileNameA stringByTrimmingCharactersInSet:
                                  [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            fileName = [fileName uppercaseString];
            NSString *ext =[fileName pathExtension];
            
            if (ext && [ext compare:@"JPG"] == NSOrderedSame)
            {
                fileName = [NSString stringWithFormat:@"http://192.168.234.1/sd1/PHOTO/%@--0",fileName];
                [self.delegate GetFiles:fileName];
            }
        }
        
    }
    else
    {
        ;
    }
    [self.delegate GetFiles:sEnd];
#endif
    
}


-(void)GetFiles_GK_LangTong:(TYPE_FILES)ntype
{
    if(ntype == TYPE_SNAP_FILES)
    {
        [self F_GetPhotos_GK_LangTong];
    }
    else
    {
        [self F_GetVideos_GK_LangTong];
    }
    
    
}

-(void)naSetWifiPassword:(char *)sPassword
{
    int nLen =(int)strlen(sPassword);
    if(nLen==0)
        return;
    if(nLen>64)
        return;
    uint8  msg[80];
    msg[0] = 'J';
    msg[1] = 'H';
    msg[2] = 'C';
    msg[3] = 'M';
    msg[4] = 'D';
    msg[5] = 0x30;
    msg[6] = 0x02;
    msg[7] = (uint8)nLen;
    for(int i=0;i<nLen;i++)
    {
        msg[8+i] = (uint8)(sPassword[i]);
    }
    NSData *data = [[NSData  alloc] initWithBytes:msg length:8+nLen];
    [self F_SetOpInfo];
    
    [self F_SentUdp:data Server:self.sSerVerIP Port:20000];
    
}
-(int)naGetFiles:(TYPE_FILES)ntype
{
    __weak JH_WifiCamera *weakself = self;
    if(self.nIC_Type == IC_GK)
    {
        [self GetFiles_GK_LangTong:ntype];
        return 0;
    }
    
    //if(!self.bVaild && self.nIC_Type == IC_GKA)
    //    return -100;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [weakself naGetFiles_A:ntype];
        usleep(1000*200);
    });
    return 0;
}


-(int)naGetFiles_A:(TYPE_FILES)ntype
{
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG   config;
    T_NET_SD_SNAP_FILE_LIST  file_list;
    T_NET_SD_SNAP_FILE_INFO  fileinfo;
    
    NSString *sStart;
    NSString *sEnd;
    
    if(ntype ==0)
    {
        sStart = @"---Start Get SNAP FILES LIST";
        sEnd = @"---End Get SNAP FILES LIST";
        config.type = CONFIG_SD_SNAP_FILE_LIST;
    }
    else
    {
        sStart = @"---Start Get Rec FILES LIST";
        sEnd = @"---End Get Rec FILES LIST";
        config.type = CONFIG_SD_REC_FILE_LIST;
    }
    
    NSLog(@"Get Files List!!!!!!");
    
    int nYear =2000;// [sYear intValue];
    int nMonth =1;//[sMonth intValue];
    int nDay =1;//[sDay intValue];
    
    [self.delegate GetFiles:sStart];
    
    MySocket *serchSocket = [[MySocket alloc] init];
    if([serchSocket Connect:GK_ServerIP PORT:0x7102]<0)
    {
        [self.delegate GetFiles:nil];
        return -1;
    }
    NSData *retDat;
    
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_SEARCH_SOCK;
    NSMutableData  *sendDataA = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    [serchSocket Write:sendDataA];
    // [serchSocket ReadA:128];
    
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_GET_CONFIG;
    config.res = 0;
    
    file_list.type = 255;
    file_list.file_num = 0;
    file_list.send_buf = 0;//NULL;
    
    //2000-1-1 00:00:00  - 2100-1-1 00:00:00           获取所有文件
    file_list.begin_time.dwYear = nYear;
    file_list.begin_time.dwMonth= nMonth;
    file_list.begin_time.dwDay =nDay;
    file_list.begin_time.dwHour = 0;
    file_list.begin_time.dwMinute = 0;
    file_list.begin_time.dwSecond = 0;
    
    file_list.end_time.dwYear = 2099;
    file_list.end_time.dwMonth= 12;
    file_list.end_time.dwDay =  31;
    file_list.end_time.dwHour = 23;
    file_list.end_time.dwMinute = 59;
    file_list.end_time.dwSecond = 59;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
    NSData *data1 =  [NSData dataWithBytes:&file_list length:sizeof(T_NET_SD_SNAP_FILE_LIST)];
    [sendData appendData:data];
    [sendData appendData:data1];
    
    
    [serchSocket Write:sendData];
    
    T_REQ_MSG msg;
    int nLen = sizeof(T_REQ_MSG);
    retDat = [serchSocket Read:nLen timeout:6000];
    if(retDat.length==nLen)
    {
        [retDat getBytes:&msg length:sizeof(T_REQ_MSG)];
        if(msg.ret == 0)
        {
            nLen=sizeof(T_NET_SD_SNAP_FILE_LIST);
            retDat = [serchSocket Read:nLen timeout:5000];
            if(retDat.length == nLen)
            {
                [retDat getBytes:&file_list length:nLen];
                if(file_list.file_num>0)
                {
                    NSLog(@"fine count =%d",file_list.file_num);
                    for(int ix=0;ix<file_list.file_num;ix++)
                    {
                        nLen =sizeof(T_NET_SD_SNAP_FILE_INFO);
                        retDat = [serchSocket Read:sizeof(T_NET_SD_SNAP_FILE_INFO) timeout:1000];
                        if(retDat.length==nLen)
                        {
                            [retDat getBytes:&fileinfo length:nLen];
                            {
                                NSString *filei_info = [NSString stringWithFormat:@"%@--%lld",[NSString stringWithUTF8String:fileinfo.name],fileinfo.size];
                                [self.delegate GetFiles:filei_info];
                            }
                        }
                    }
                    [self.delegate GetFiles:sEnd];
                    [serchSocket DisConnect];
                    return 0;
                }
            }
        }
    }
    [self.delegate GetFiles:sEnd];
    [serchSocket DisConnect];
    return -1;
}



/*
 -(int)naDownloadFile:(NSString *)sPathA ID:(int)nId;
 {
 
 if(!sPathA)
 return -1;
 if(sPathA.length==0)
 return -1;
 
 
 const char *path = [sPathA UTF8String];
 __weak JH_WifiCamera *weakself = self;
 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
 [weakself F_downloadFile:path];
 });
 return 0;
 }
 
 -(int)F_downloadFile:(const char *)sPathA
 {
 
 MySocket  *DownSocket = [[MySocket alloc] init];
 if([DownSocket Connect:GK_ServerIP PORT:0x7102]<0)
 {
 return -1;
 }
 DownSocket.nID = 0;
 [self.downArray addObject:DownSocket];
 T_NET_CMD_MSG Cmd;
 T_NET_DOWNLOAD_CONTROL downCtrol;
 
 Cmd.session_id = self.session_id;
 Cmd.type = CMD_DOWNLOAD_SOCK;
 
 downCtrol.dl_type =  DL_SNAP_FILE;
 downCtrol.one_packet_size = 4096*2;
 memcpy(downCtrol.name,(const void *)sPathA,strlen(sPathA)+1);
 
 NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
 NSData *data =  [NSData dataWithBytes:&downCtrol length:sizeof(T_NET_DOWNLOAD_CONTROL)];
 [sendData appendData:data];
 DownSocket.delegate = self;
 [DownSocket Write:sendData];
 NSData *dat =  [DownSocket Read:8];
 T_REQ_MSG msg;
 [dat getBytes:&msg length:8];
 [DownSocket StartReadThread:4096*2+sizeof(T_NET_DL_PACKET_HEADER)];
 return 0;
 }
 */
/*
 -(int)F_SetNotifySocketCmd
 {
 T_NET_CMD_MSG Cmd;
 Cmd.session_id=self.session_id;
 Cmd.type = CMD_NOTICE_SOCK;
 NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
 [self.GK_tcp_NoticeSocket writeData:sendData withTimeout:100 tag:Tag_Notify];
 return 0;
 }
 */
/*
 -(int)F_OpenNoticeSocket
 {
 NSError *error;
 if([self.GK_tcp_NoticeSocket connectToHost:GK_ServerIP onPort:GK_Port error:&error])
 return 0;
 return -1;
 }
 */


- (int)naGetRssi{
#if 0
    UIApplication *app = [UIApplication sharedApplication];
    NSArray *subviews = [[[app valueForKey:@"statusBar"] valueForKey:@"foregroundView"] subviews];
    id dataNetworkItemView = nil;
    
    /*
     for (id subview in subviews) {
     if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarSignalStrengthItemView") class]]) {
     dataNetworkItemView_B = subview;
     signalStrengthB = [[dataNetworkItemView_B valueForKey:@"_signalStrengthBars"] intValue];
     break;
     }
     }
     */
    for (id subview in subviews) {
        if([subview isKindOfClass:[NSClassFromString(@"UIStatusBarDataNetworkItemView") class]]) {
            dataNetworkItemView = subview;
            break;
        }
    }
    int signalStrength = [[dataNetworkItemView valueForKey:@"_wifiStrengthBars"] intValue];
    int networkType = [[dataNetworkItemView valueForKeyPath:@"dataNetworkType"] intValue];
    if(networkType != 5)
        return 0;
    
    //NSLog(@"signal %d", signalStrength);
    
    return signalStrength;
#else
    return -1;
#endif
}



-(int)Connect_gk_c
{
    //self.bNeedCreateNotify = YES;
    //__weak JH_WifiCamera *weakself = self;
    self.bCheckLink=NO;
    self.session_id=-1;
    self.bSima = NO;
    [self Connect_gk];
    return 0;
}

-(void)DisConnect_GPH264A
{
    
}

-(void)DisConnect
{
    
    self.bIsConnect = NO;
    self.bCheckLink = NO;
    [_GKA_Data_Socket DisConnect];
    [_GKA_Notice_Socket DisConnect];
    [_GKA_Cmd_Socket DisConnect];
    [self naCancelDownload];
}

-(int)F_ReadAck:(int)ms
{
    memset(&req_msg,0,sizeof(T_REQ_MSG));
    req_msg.ret = -1;
    NSData *dat = [_GKA_Cmd_Socket Read:sizeof(T_REQ_MSG) timeout:ms];
    if(dat && dat.length==sizeof(T_REQ_MSG))
    {
        memcpy(&req_msg, [dat bytes], sizeof(T_REQ_MSG));
        return req_msg.ret;
    }
    else
    {
        return -1;
    }
    
}

-(void)F_StartReadNotice
{
    
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSData *dat;
        while(weakself.GKA_Notice_Socket.bConnected)
        {
            dat = [weakself.GKA_Notice_Socket Read:sizeof(int) timeout:50];
            if(dat)
            {
                int status;
                NSRange rang = {0,sizeof(int)};
                [dat getBytes:&status range:rang];
                if((status & 0xFF) == 0xFF)
                    status = 0;
                [weakself F_AdjStatus:status];
                // NSLog(@"Notice status= 0x%02X",status);
            }
            usleep(1000*100); //10ms
        }
    });
    
}

-(void)F_StartReadData
{
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        fd_set   set;
        //int64_t ad = av_gettime();
        NSLog(@"Start Read Data!!!!");
        // while(weakself.GKA_Data_Socket.bConnected)
        self.isCancelled=false;
        while(!self.isCancelled)
        {
            struct timeval timeoutA = {0,1000};     //10ms
            FD_ZERO(&set); // 在使用之前总是要清空
            FD_SET(weakself.GKA_Data_Socket.socketfd, &set); // 把socka放入要测试的描述符集中
            // 开始使用select
            int nRet = select(weakself.GKA_Data_Socket.socketfd+1, &set, NULL, NULL, &timeoutA);  // 检测是否有套接口是否可读+1, &rfd, NULL, NULL, &timeoutA);// 检测是否有套接口是否可读
            if(nRet<=0)
            {
                continue;
            }
            if (!(FD_ISSET(weakself.GKA_Data_Socket.socketfd, &set)))
            {
                continue;
            }
            int nLen =(int) recv(weakself.GKA_Data_Socket.socketfd,weakself.pBuffer,VideoPackLen,0);
            {
                if(nLen>0)
                {
                    //NSLog(@"ReadData!!!!");
                    [weakself.packetLock lock];
                    self.nRelinkTime = 0;
                    [weakself.packetLock unlock];
                    if(weakself.bSendDecordGKA)
                    {
                        [weakself DecordData_H264:nLen];
                    }
                }
            }
            usleep(1000*1);
        }
        NSLog(@"Exit ReadData Thread!");
        
    });
}



-(int)naDeleteSDFile:(NSString *)sFullPath;
{
    
    T_NET_CMD_MSG Cmd;
    T_NET_CONFIG   config;
    T_NET_SD_FILE_INFO fileinfo;
    const char *sfile;
    if(sFullPath)
    {
        sfile = [sFullPath UTF8String];
        if(strlen(sfile)>=40)
            return -1;
    }
    else
    {
        return -2;
    }
    
    
    
    MySocket  *socket = [[MySocket alloc] init];
    if ([socket Connect:GK_ServerIP PORT:GK_Port]<0)
    {
        return -1;
    }
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_SEARCH_SOCK;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    [socket Write:sendData];
    NSData *data;
    //= [socket Read:sizeof(T_REQ_MSG) timeout:200];
    
    // if(data && data.length == sizeof(T_REQ_MSG))
    {
        //  memcpy(&req_msg, [data bytes], sizeof(T_REQ_MSG));
        // if(req_msg.ret == 0 && req_msg.session_id == _session_id)
        {
            Cmd.session_id = _session_id;
            Cmd.type=CMD_SET_CONFIG;
            config.res = 0;
            config.type = CONFIG_SD_RM_FILE;
            memcpy(fileinfo.name,sfile,strlen(sfile));
            sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
            data = [NSData dataWithBytes:&config length:sizeof(T_NET_CONFIG)];
            [sendData appendData:data];
            data = [NSData dataWithBytes:&fileinfo length:sizeof(T_NET_SD_FILE_INFO)];
            [sendData appendData:data];
            [socket Write:sendData];
            data = [socket Read:sizeof(T_REQ_MSG) timeout:150];
            if(data && data.length == sizeof(T_REQ_MSG))
            {
                memcpy(&req_msg, [data bytes], sizeof(T_REQ_MSG));
                if(req_msg.ret == 0 && req_msg.session_id == _session_id)
                {
                    [socket DisConnect];
                    return 0;
                }
            }
        }
    }
    [socket DisConnect];
    return -1;
}


-(void)F_SetChekRelink:(int)mS100
{
    self.bStartinit = NO;
    self.bCheckLink = NO;
    self.nRelinkTime = 0;
    self.nRelinkTime_Set = mS100; //uint 100ms
    self.bCheckLink = YES;
    self.bStartinit = YES;
    self.bCanCheckRelink = YES;
}
-(int)ConnectGPH264A
{
    [self F_SetChekRelink:80];
    if ([_GKA_Data_Socket Connect:_sSerVerIP PORT:8080] < 0)
    {
        return -1;
    }
    self.bSendDecordGKA = YES;
    [self F_StartReadData];
    [self F_SetChekRelink:80];
    return 0;
}

-(void)F_CloseAllSocket
{
    [_GKA_Cmd_Socket DisConnect];
    [_GKA_Notice_Socket DisConnect];
    [_GKA_Data_Socket DisConnect];
    
}

-(NSString *)naGetControlType
{
    return self.sver;
}

-(int)Connect_gk
{
    NSLog(@"Start GKA ------------------ 1");
    if(m_parser!=NULL)
    {
        av_parser_close(m_parser);
        m_parser = NULL;
        m_parser = av_parser_init(AV_CODEC_ID_H264);
    }
    else
    {
        m_parser = av_parser_init(AV_CODEC_ID_H264);
    }
    
    [self F_SetChekRelink:80];
    [self DisConnect];
    self.bSendDecordGKA = NO;
    [self F_SetChekRelink:80];
    if ([_GKA_Cmd_Socket Connect:GK_ServerIP PORT:GK_Port]<0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    
    if ([_GKA_Notice_Socket Connect:GK_ServerIP PORT:GK_Port]<0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    
    if([self F_Login]<0)
    {
        [self F_CloseAllSocket];
        NSLog(@"Login error!");
        [self F_SetChekRelink:5];
        return -1;
    }
    self.session_id = req_msg.session_id;
    if(self.session_id == 0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    NSLog(@"Login OK  session_id=%d",req_msg.session_id);
    if([self F_AdjTime]<0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    
    
    nFps=20;
    
    if([self F_GetFps:self.nSetStream] !=0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    
    
    [self F_SetChekRelink:80];
    self.sver = [self F_GetFirewareVer];
    if(req_msg.ret != 0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    
    
    if([self F_OpenDataSocket:self.nSetStream]!=0)
    {
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    _GKA_Data_Socket.pBuffer = _pBuffer;
    self.bSendDecordGKA = YES;
    [self F_StartReadData];
    [self F_SetChekRelink:80];
    if([self F_OpenVideoStream:self.nSetStream]<0)
    {
        NSLog(@"Open VideoStream error!");
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    
    
    if([self F_CMD_FORCE_I]!=0)
    {
        NSLog(@"Force I error!");
        [self F_CloseAllSocket];
        [self F_SetChekRelink:5];
        return -1;
    }
    T_NET_CMD_MSG Cmd;
    Cmd.session_id = _session_id;
    Cmd.type = CMD_NOTICE_SOCK;
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    [_GKA_Notice_Socket Write:sendData];
    NSData *data = [_GKA_Notice_Socket Read:sizeof(T_REQ_MSG) timeout:1000];
    memcpy(&req_msg, [data bytes], sizeof(T_REQ_MSG));
    [self F_StartReadNotice];
    [self F_StartHeartThread];
    [self F_GetSDStatus];
    [self F_SetChekRelink:80];
    NSLog(@"Init End!!!");
    _bGKA_ConnOK = YES;
    return 0;
}


-(void)F_StartCheckConnect
{
    self.bCheckLink = NO;
    if(self.nIC_Type == IC_SN)
    {
        self.nRelinkTime_Set = 30;               //40*100 = 4Secs;
    }
    else
    {
        self.nRelinkTime_Set = 30;
    }
    self.nRelinkTime=0;
    self.bCheckLink = YES;
    //[self F_CheckConnect_A];
}





-(void)F_InitFrame
{
    if(pFrameYUV != NULL)
        return ;
    NSLog(@"Init AA2");
    pix_format = AV_PIX_FMT_YUV420P;
    
    disp_pix_format =  AV_PIX_FMT_BGR24;
    dispCodeID = AV_CODEC_ID_BMP;
    
    
    if(m_codecCtx!=NULL)
    {
        if(m_codecCtx->width==0 || m_codecCtx->height==0)
            return;
    }
    
    pFrameYUV=av_frame_alloc();
    //pFrameRGB=av_frame_alloc();
    
    pFrameYUV->format = pix_format;
    pFrameYUV->width = m_codecCtx->width;
    pFrameYUV->height = m_codecCtx->height;
    
    av_image_alloc(pFrameYUV->data, pFrameYUV->linesize, m_codecCtx->width,
                   m_codecCtx->height,
                   pix_format, 4);
    
    /*
     pFrameRGB->format = disp_pix_format;
     pFrameRGB->width =_nRecordWidth;// m_codecCtx->width;
     pFrameRGB->height =_nRecordHeight;// m_codecCtx->height;
     
     av_image_alloc( pFrameRGB->data, pFrameRGB->linesize, _nRecordWidth,
     _nRecordHeight,
     disp_pix_format, 4);
     */
    img_convert_ctx = sws_getContext(m_codecCtx->width, m_codecCtx->height, m_codecCtx->pix_fmt,
                                     m_codecCtx->width, m_codecCtx->height, pix_format, SWS_FAST_BILINEAR, NULL, NULL, NULL); //
    
    
    // img_convert_ctxBmp = sws_getContext(m_codecCtx->width, m_codecCtx->height, pix_format,
    //                                   m_codecCtx->width,m_codecCtx->height,disp_pix_format, SWS_FAST_BILINEAR, NULL, NULL, NULL); //
    
    img_convert_ctxBmp = sws_getContext(m_codecCtx->width, m_codecCtx->height, pix_format,
                                        _nRecordWidth,_nRecordHeight,disp_pix_format, SWS_FAST_BILINEAR, NULL, NULL, NULL); //
    
    
    
    img_convert_ctx_half = sws_getContext(m_codecCtx->width, m_codecCtx->height, pix_format,
                                          m_codecCtx->width/2, m_codecCtx->height/2, pix_format, SWS_FAST_BILINEAR, NULL, NULL, NULL); //
    
    /*
     img_convert_ctx_Rec =  sws_getContext(m_codecCtx->width, m_codecCtx->height, pix_format,
     _nRecordWidth, _nRecordHeight, pix_format, SWS_FAST_BILINEAR, NULL, NULL, NULL); //
     */
    
    
    
    
    if(frame_a==NULL)
    {
        frame_a = av_frame_alloc();
        frame_a->format = AV_PIX_FMT_YUV420P;
        frame_a->width = m_codecCtx->width;
        frame_a->height = m_codecCtx->height;
        
        av_image_alloc(frame_a->data, frame_a->linesize, m_codecCtx->width,
                       m_codecCtx->height,
                       AV_PIX_FMT_YUV420P,4);
    }
    
    
    if(frame_b==NULL)
    {
        frame_b = av_frame_alloc();
        frame_b->format = AV_PIX_FMT_YUV420P;
        frame_b->width = m_codecCtx->width/2;
        frame_b->height = m_codecCtx->height/2;
        
        av_image_alloc(frame_b->data, frame_b->linesize, frame_b->width,
                       frame_b->height,
                       AV_PIX_FMT_YUV420P,4);
    }
    
}


-(int)InitMediaSN:(BOOL)b480
{
    if(_nIC_Type == IC_SN)
    {
        _nDispWidth = 640;
        _nDispHeight = 360;
        if(b480)
            _nDispHeight = 480;
    }
    
    if(m_decodedFrame == NULL)
    {
        m_decodedFrame = av_frame_alloc();
        codec = avcodec_find_decoder(AV_CODEC_ID_MJPEG);
        m_codecCtx = avcodec_alloc_context3(codec);
        m_codecCtx->width = _nDispWidth;
        m_codecCtx->height = _nDispHeight;
        m_codecCtx->codec_id = AV_CODEC_ID_MJPEG;
        m_codecCtx->pix_fmt = AV_PIX_FMT_YUVJ422P;
        m_codecCtx->time_base.den = 1;
        m_codecCtx->time_base.num = 1;
        int ret = avcodec_open2(m_codecCtx, codec, NULL);
        return ret;
    }
    [self F_InitFrame];
    
    return 0;
}

-(void)naSetRecordWH:(int)w Height:(int)h
{
    _bSetRecordWH = YES;
    _nRecordWidth = w;
    _nRecordHeight = h;
    
}

-(int)InitMediaGKA
{
    if(m_decodedFrame == NULL)
    {
        NSLog(@"Init AA1");
        m_decodedFrame = av_frame_alloc();
        codec = avcodec_find_decoder(AV_CODEC_ID_H264);
        m_codecCtx = avcodec_alloc_context3(codec);
        m_codecCtx->codec_id = AV_CODEC_ID_H264;
        m_parser = av_parser_init(AV_CODEC_ID_H264);
        int ret = avcodec_open2(m_codecCtx, codec, NULL);
        if (ret != 0){
            ;
        }
        return 0;
    }
    [self F_InitFrame];
    
    return 0;
}

#pragma mark  TCP_CallBack

-(void)F_SentStatus
{
    if(self.delegate)
    {
        __weak JH_WifiCamera  *weakself = self;
#if 1
        dispatch_async(dispatch_get_main_queue(), ^{
            if([weakself.delegate respondsToSelector:@selector(StatusChanged:)])
            {
                [weakself.delegate StatusChanged:self.nSdStatus & 0xFF];
            }
            
        });
#endif
    }
}

-(void)F_AdjStatus:(int)nStatus
{
    int status = nStatus;
    NSLog(@"Status_SDK=0x%02X",nStatus);
    if(status & 0x01)
    {
        self.nSdStatus |= SD_Ready;
    }
    else
    {
        self.nSdStatus &= (SD_Ready^0xFFFF);
        self.nSdStatus &=(SD_SNAP^0xFFFF);
        self.nSdStatus &=(SD_Recording^0xFFFF);
    }
    if(self.nSdStatus & SD_Ready)
    {
        if(status & 0x08)
        {
            self.nSdStatus |= SD_Recording;
        }
        else
        {
            self.nSdStatus &=(SD_Recording^0xFFFF);
        }
        
        if(status & 0x10)
        {
            self.nSdStatus |= SD_SNAP;
        }
        else
        {
            self.nSdStatus &=(SD_SNAP^0xFFFF);
        }
    }
    [self F_SentStatus];
    
}



-(void)naSetCustomer:(NSString *)sCustomer
{
    self.sCustomer =sCustomer;
}

-(void)naSetCheckT:(int)nDealy
{
    self.nRelinkTime = 0;
    self.nRelinkTime_Set = self.nRelinkTime_Set1 = nDealy;
}




-(void)naGKA_Pause
{
    //self.bNoCheckRelink = YES;
    // [self F_CloseVideoStream_A:self.nSetStream];
}

-(void)naGKA_Resume
{
#if 0
    //[self F_OpenDataSocket:self.nSetStream];
    self.bNoDisp = YES;
    [self F_OpenVideoStream_A:self.nSetStream];
    self.bNeedCreateNotify = YES;
    //self.bNoCheckRelink = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.bNoDisp = NO;
    });
#endif
}



- (int)typeOfNalu:(NSData *)data
{
    char first = *(char *)[data bytes];
    return first & 0x1f;
}

- (int)startCodeLenth:(NSData *)data
{
    char temp = *((char *)[data bytes] + [data length] - 4);
    return temp == 0x00 ? 4 : 3;
}


- (void)saveStartCode:(NSData *)data
{
    int startCodeLen = [self startCodeLenth:data];
    NSRange startCodeRange = {[data length] - startCodeLen, (NSUInteger)startCodeLen};
    self.lastStartCode = [data subdataWithRange:startCodeRange];
}

-(void)naSetScale:(float)n
{
    _nScale = n;
}


#pragma mark  解码
//解码自定义协议传输H264
-(void)DecordData_H264:(int )length
{
    self.nRelinkTime = 0;
    if(length<=0)
        return ;
    
    uint8_t *outbuff = NULL;
    int ret;
    //int frameFinished = 0;
    
    int size = 0;
    int len;
    //int in_len =(int)data.length;
    
    int in_len =(int)length;
    
    uint8_t  *in_data;// =(uint8_t  *)malloc(in_len);
    in_data = _pBuffer;
    int nKeyFrame = 0;
    while(in_len>0)
    {
        len = av_parser_parse2(m_parser, m_codecCtx, &outbuff, &size, in_data, in_len, 0, 0, 0);
        in_data += len;
        in_len -= len;
        if (size>0)
        {
            //NSLog(@"ReadData %d",av_gettime()/1000);
            AVPacket packetA = {0};
            av_init_packet(&packetA);
            packetA.data = outbuff;
            packetA.size = size;
            ret = -1;
#if 0
            int frameFinished=-1;
            ret = avcodec_decode_video2(m_codecCtx, m_decodedFrame, &frameFinished, &packetA);
            if(ret<0 || frameFinished == 0)
                ret = -1;
            else
                ret = 0;
#else
            
            
            //av_frame_unref(m_decodedFrame);
            if (avcodec_send_packet(m_codecCtx, &packetA) == 0)
            {
                if (avcodec_receive_frame(m_codecCtx, m_decodedFrame) != 0) {
                    ret = -1;
                } else {
                    ret = 0;
                }
            }
            else
            {
                ret = -1;
            }
#endif
            if(ret!=0)
            {
                self.nErrorFrame++;
                if([self.delegate respondsToSelector:@selector(GetErrorFrame:)])
                {
                    [self.delegate GetErrorFrame:self.nErrorFrame];
                }
            }
            if(ret == 0)
            {
                _nDispWidth = m_codecCtx->width;
                _nDispHeight = m_codecCtx->height;
                if(!_bSetRecordWH)
                {
                    _nRecordWidth = _nDispWidth;
                    _nRecordHeight = _nDispHeight;
                }
                
                nKeyFrame = m_decodedFrame->key_frame;
                [self InitMediaGKA];
                sws_scale(img_convert_ctx,
                          (const uint8_t *const *) m_decodedFrame->data,
                          m_decodedFrame->linesize, 0,
                          m_codecCtx->height,
                          pFrameYUV->data, pFrameYUV->linesize);
                
                int dd = (int)(_nScale*100);
                
                if(dd <=100) //不放大
                {
                    if(pFrameSnap==NULL)
                    {
                        pFrameSnap = av_frame_alloc();
                        pFrameSnap->format = AV_PIX_FMT_YUV420P;
                        pFrameSnap->width = _nDispWidth;
                        pFrameSnap->height =_nDispHeight;
                        ret = av_image_alloc(
                                             pFrameSnap->data, pFrameSnap->linesize, pFrameSnap->width,
                                             pFrameSnap->height,
                                             AV_PIX_FMT_YUV420P, 4);
                        _my_snapframe->pFrame = pFrameSnap;
                    }
                }
                else
                {
                    AVFrame *pFrameYUV_D = av_frame_alloc();
                    pFrameYUV_D->format = AV_PIX_FMT_YUV420P;
                    pFrameYUV_D->width = (int)(_nDispWidth*_nScale);
                    pFrameYUV_D->height = (int)(_nDispHeight*_nScale);
                    ret = av_image_alloc(
                                         pFrameYUV_D->data, pFrameYUV_D->linesize, pFrameYUV_D->width,
                                         pFrameYUV_D->height,
                                         AV_PIX_FMT_YUV420P, 4);
                    I420Scale(pFrameYUV->data[0],pFrameYUV->linesize[0],
                              pFrameYUV->data[1],pFrameYUV->linesize[1],
                              pFrameYUV->data[2],pFrameYUV->linesize[2],
                              pFrameYUV->width,pFrameYUV->height,
                              pFrameYUV_D->data[0],pFrameYUV_D->linesize[0],
                              pFrameYUV_D->data[1],pFrameYUV_D->linesize[1],
                              pFrameYUV_D->data[2],pFrameYUV_D->linesize[2],
                              pFrameYUV_D->width,pFrameYUV_D->height,
                              kFilterLinear);
                    
                    
                    
                    av_freep(&(pFrameYUV->data[0]));
                    av_frame_free(&pFrameYUV);
                    pFrameYUV = av_frame_alloc();
                    
                    pFrameYUV->format = AV_PIX_FMT_YUV420P;
                    pFrameYUV->width = _nDispWidth;
                    pFrameYUV->height =_nDispHeight;
                    ret = av_image_alloc(
                                         pFrameYUV->data, pFrameYUV->linesize, pFrameYUV->width,
                                         pFrameYUV->height,
                                         AV_PIX_FMT_YUV420P, 4);
                    
                    if(pFrameSnap==NULL)
                    {
                        pFrameSnap = av_frame_alloc();
                        pFrameSnap->format = AV_PIX_FMT_YUV420P;
                        pFrameSnap->width = _nDispWidth;
                        pFrameSnap->height =_nDispHeight;
                        ret = av_image_alloc(
                                             pFrameSnap->data, pFrameSnap->linesize, pFrameSnap->width,
                                             pFrameSnap->height,
                                             AV_PIX_FMT_YUV420P, 4);
                        _my_snapframe->pFrame = pFrameSnap;
                    }
                    
                    int cx =  pFrameYUV_D->width/2;
                    int cy =  pFrameYUV_D->height/2;
                    
                    int lx = cx-(pFrameYUV->width/2);
                    lx=(lx+1)/2;
                    lx*=2;
                    
                    
                    int ly = cy-(pFrameYUV->height/2);
                    ly = (ly+1)/2;
                    ly*=2;
                    
                    Byte *psrc;
                    Byte *pdes;
                    
                    Byte *pSrcStart = pFrameYUV_D->data[0]+ly*pFrameYUV_D->linesize[0]+lx;
                    pdes =(Byte*) pFrameYUV->data[0];
                    
                    for(int yy=0;yy<pFrameYUV->height;yy++)
                    {
                        psrc =(Byte*)pSrcStart+yy*pFrameYUV_D->linesize[0];
                        memcpy(pdes+yy*pFrameYUV->linesize[0],psrc,(size_t)(pFrameYUV->linesize[0]));
                    }
                    
                    
                    
                    pSrcStart = pFrameYUV_D->data[1]+ly/2*pFrameYUV_D->linesize[1]+lx/2;
                    pdes = pFrameYUV->data[1];
                    
                    for(int yy=0;yy<pFrameYUV->height/2;yy++)
                    {
                        psrc = pSrcStart+yy*pFrameYUV_D->linesize[1];
                        memcpy(pdes+yy*pFrameYUV->linesize[1],psrc,(size_t )pFrameYUV->linesize[1]);
                        
                    }
                    
                    pSrcStart = pFrameYUV_D->data[2]+ly/2*pFrameYUV_D->linesize[2]+lx/2;
                    pdes = pFrameYUV->data[2];
                    
                    for(int yy=0;yy<pFrameYUV->height/2;yy++)
                    {
                        psrc = pSrcStart+yy*pFrameYUV_D->linesize[2];
                        memcpy(pdes+yy*pFrameYUV->linesize[1],psrc,(size_t )pFrameYUV->linesize[2]);
                    }
                    av_freep(&(pFrameYUV_D->data[0]));
                    av_frame_free(&pFrameYUV_D);
                }
                
                if(self.bFlip)
                {
                    
                    I420Rotate(pFrameYUV->data[0], pFrameYUV->linesize[0],
                               pFrameYUV->data[1], pFrameYUV->linesize[1],
                               pFrameYUV->data[2], pFrameYUV->linesize[2],
                               frame_a->data[0], frame_a->linesize[0],
                               frame_a->data[1], frame_a->linesize[1],
                               frame_a->data[2], frame_a->linesize[2],
                               frame_a->width, frame_a->height,kRotate180);
                    
                    
                    I420Copy(frame_a->data[0], frame_a->linesize[0],
                             frame_a->data[1], frame_a->linesize[1],
                             frame_a->data[2], frame_a->linesize[2],
                             pFrameYUV->data[0], frame_a->linesize[0],
                             pFrameYUV->data[1], frame_a->linesize[1],
                             pFrameYUV->data[2], frame_a->linesize[2],
                             frame_a->width, frame_a->height);
                }
                
                if(self.b3D)
                {
                    I420Scale(pFrameYUV->data[0], pFrameYUV->linesize[0],
                              pFrameYUV->data[1], pFrameYUV->linesize[1],
                              pFrameYUV->data[2], pFrameYUV->linesize[2],
                              pFrameYUV->width, pFrameYUV->height,
                              frame_b->data[0], frame_b->linesize[0],
                              frame_b->data[1], frame_b->linesize[1],
                              frame_b->data[2], frame_b->linesize[2],
                              frame_b->width, frame_b->height, kFilterBilinear);
                    [self frame_link2frame:frame_b DES:pFrameYUV];;
                }
                [self SaveVideo];
                pFrameYUV->key_frame= nKeyFrame;
                if(pFrameSnap!=NULL)
                {
                    @synchronized(_my_snapframe)
                    {
                        I420Copy(pFrameYUV->data[0], pFrameYUV->linesize[0],
                                 pFrameYUV->data[1], pFrameYUV->linesize[1],
                                 pFrameYUV->data[2], pFrameYUV->linesize[2],
                                 pFrameSnap->data[0], pFrameSnap->linesize[0],
                                 pFrameSnap->data[1], pFrameSnap->linesize[1],
                                 pFrameSnap->data[2], pFrameSnap->linesize[2],
                                 pFrameYUV->width, pFrameYUV->height);
                    }
                }
                [self PlatformDisplay:pFrameYUV];
            }
            av_packet_unref(&packetA);
            self.bPlaying = YES;
        }
    }
    
}
//解码rtsp http 标准协议传输H264
-(void)DecordData_ffmpeg
{
    
    if(self.nIC_Type == IC_SN)
        return;
    if(self.nIC_Type == IC_GKA)
        return;
    int ret;
    //bool  bMMisRTP = false;
    bFindKeyFrame = YES;
    self.nLost = 0;
    self.nRelinkCount = 0;
    
    int64_t subt;
    NSTimeInterval t1 = [[NSDate date] timeIntervalSince1970] * 1000;
    NSTimeInterval t2;
    
    AVPacket pkt = {0};
    av_init_packet(&pkt);
    pkt.data = NULL;
    pkt.size = 0;
    [self F_SetTimeout:2000];
    while(self.bPlaying)
    {
        
        if(self.bSetpause)   // && self.imageView)
        {
            usleep(1000*10);
            continue;
        }
        [self F_SetTimeout:0];
        int  nKeyFrame = NO;
        if(av_read_frame(m_formatCtx, &pkt)>=0)
        {
            [self F_SetTimeout:0];
            
            ret = -1;
            
            if (avcodec_send_packet(m_codecCtx, &pkt) == 0)
            {
                if (avcodec_receive_frame(m_codecCtx, m_decodedFrame) != 0) {
                    ret = -1;
                } else {
                    ret = 0;
                }
            }
            else
            {
                ret = -1;
            }
            
            /*
             
             int frameFinished = 0;
             ret = avcodec_decode_video2(m_codecCtx, m_decodedFrame, &frameFinished, &pkt);
             if(ret<0 || frameFinished == 0)
             {
             ret = -1;
             }
             else
             {
             ret = 0;
             }
             */
            
            if(ret == 0 )//&& !bFindKeyFrame)
            {
                nKeyFrame =m_decodedFrame->key_frame;
                self.nRelinkTime = 0;
                if(pkt.stream_index == m_videoStream)
                {
                    if(ret == 0)
                    {
                        sws_scale(img_convert_ctx,
                                  (const uint8_t *const *) m_decodedFrame->data,
                                  m_decodedFrame->linesize, 0,
                                  m_codecCtx->height,
                                  pFrameYUV->data, pFrameYUV->linesize);
                        
                        int dd = (int)(_nScale*100);
                        if(dd <=100) //不放大
                        {
                            if(pFrameSnap==NULL)
                            {
                                pFrameSnap = av_frame_alloc();
                                pFrameSnap->format = AV_PIX_FMT_YUV420P;
                                pFrameSnap->width = m_codecCtx->width;
                                pFrameSnap->height =m_codecCtx->height;
                                ret = av_image_alloc(
                                                     pFrameSnap->data, pFrameSnap->linesize, pFrameSnap->width,
                                                     pFrameSnap->height,
                                                     AV_PIX_FMT_YUV420P, 4);
                                _my_snapframe->pFrame = pFrameSnap;
                            }
                        }
                        else
                        {
                            AVFrame *pFrameYUV_D = av_frame_alloc();
                            pFrameYUV_D->format = AV_PIX_FMT_YUV420P;
                            pFrameYUV_D->width = (int)(m_codecCtx->width*_nScale);
                            pFrameYUV_D->height = (int)(m_codecCtx->height*_nScale);
                            ret = av_image_alloc(
                                                 pFrameYUV_D->data, pFrameYUV_D->linesize, pFrameYUV_D->width,
                                                 pFrameYUV_D->height,
                                                 AV_PIX_FMT_YUV420P, 4);
                            I420Scale(pFrameYUV->data[0],pFrameYUV->linesize[0],
                                      pFrameYUV->data[1],pFrameYUV->linesize[1],
                                      pFrameYUV->data[2],pFrameYUV->linesize[2],
                                      pFrameYUV->width,pFrameYUV->height,
                                      pFrameYUV_D->data[0],pFrameYUV_D->linesize[0],
                                      pFrameYUV_D->data[1],pFrameYUV_D->linesize[1],
                                      pFrameYUV_D->data[2],pFrameYUV_D->linesize[2],
                                      pFrameYUV_D->width,pFrameYUV_D->height,
                                      kFilterLinear);
                            av_freep(&(pFrameYUV->data[0]));
                            av_frame_free(&pFrameYUV);
                            pFrameYUV = av_frame_alloc();
                            
                            pFrameYUV->format = AV_PIX_FMT_YUV420P;
                            pFrameYUV->width = m_codecCtx->width;
                            pFrameYUV->height =m_codecCtx->height;
                            ret = av_image_alloc(
                                                 pFrameYUV->data, pFrameYUV->linesize, pFrameYUV->width,
                                                 pFrameYUV->height,
                                                 AV_PIX_FMT_YUV420P, 4);
                            
                            if(pFrameSnap==NULL)
                            {
                                pFrameSnap = av_frame_alloc();
                                pFrameSnap->format = AV_PIX_FMT_YUV420P;
                                pFrameSnap->width = m_codecCtx->width;
                                pFrameSnap->height =m_codecCtx->height;
                                ret = av_image_alloc(
                                                     pFrameSnap->data, pFrameSnap->linesize, pFrameSnap->width,
                                                     pFrameSnap->height,
                                                     AV_PIX_FMT_YUV420P, 4);
                                _my_snapframe->pFrame = pFrameSnap;
                            }
                            
                            int cx =  pFrameYUV_D->width/2;
                            int cy =  pFrameYUV_D->height/2;
                            
                            int lx = cx-(pFrameYUV->width/2);
                            lx=(lx+1)/2;
                            lx*=2;
                            
                            
                            int ly = cy-(pFrameYUV->height/2);
                            ly = (ly+1)/2;
                            ly*=2;
                            
                            Byte *psrc;
                            Byte *pdes;
                            
                            Byte *pSrcStart = pFrameYUV_D->data[0]+ly*pFrameYUV_D->linesize[0]+lx;
                            pdes =(Byte*) pFrameYUV->data[0];
                            
                            for(int yy=0;yy<pFrameYUV->height;yy++)
                            {
                                psrc =(Byte*)pSrcStart+yy*pFrameYUV_D->linesize[0];
                                memcpy(pdes+yy*pFrameYUV->linesize[0],psrc,(size_t)(pFrameYUV->linesize[0]));
                            }
                            
                            
                            
                            pSrcStart = pFrameYUV_D->data[1]+ly/2*pFrameYUV_D->linesize[1]+lx/2;
                            pdes = pFrameYUV->data[1];
                            
                            for(int yy=0;yy<pFrameYUV->height/2;yy++)
                            {
                                psrc = pSrcStart+yy*pFrameYUV_D->linesize[1];
                                memcpy(pdes+yy*pFrameYUV->linesize[1],psrc,(size_t )pFrameYUV->linesize[1]);
                                
                            }
                            
                            pSrcStart = pFrameYUV_D->data[2]+ly/2*pFrameYUV_D->linesize[2]+lx/2;
                            pdes = pFrameYUV->data[2];
                            
                            for(int yy=0;yy<pFrameYUV->height/2;yy++)
                            {
                                psrc = pSrcStart+yy*pFrameYUV_D->linesize[2];
                                memcpy(pdes+yy*pFrameYUV->linesize[1],psrc,(size_t )pFrameYUV->linesize[2]);
                            }
                            av_freep(&(pFrameYUV_D->data[0]));
                            av_frame_free(&pFrameYUV_D);
                        }
                        
                        
                        if(self.bFlip)
                        {
                            //[self frame_rotate_180:pFrameYUV DesFrame:frame_a];
                            //av_frame_copy(pFrameYUV, frame_a);
                            I420Rotate(pFrameYUV->data[0], pFrameYUV->linesize[0],
                                       pFrameYUV->data[1], pFrameYUV->linesize[1],
                                       pFrameYUV->data[2], pFrameYUV->linesize[2],
                                       frame_a->data[0], frame_a->linesize[0],
                                       frame_a->data[1], frame_a->linesize[1],
                                       frame_a->data[2], frame_a->linesize[2],
                                       frame_a->width, frame_a->height,kRotate180);
                            
                            
                            I420Copy(frame_a->data[0], frame_a->linesize[0],
                                     frame_a->data[1], frame_a->linesize[1],
                                     frame_a->data[2], frame_a->linesize[2],
                                     pFrameYUV->data[0], frame_a->linesize[0],
                                     pFrameYUV->data[1], frame_a->linesize[1],
                                     pFrameYUV->data[2], frame_a->linesize[2],
                                     frame_a->width, frame_a->height);
                        }
                        
                        if(self.b3D)
                        {
                            if(self.b3DA)
                            {
                                sws_scale(img_convert_ctx_half,
                                          (const uint8_t *const *) pFrameYUV->data,
                                          pFrameYUV->linesize, 0,
                                          m_codecCtx->height,
                                          frame_b->data, frame_b->linesize);
                                
                                [self frame_link2frame:frame_b DES:pFrameYUV];;
                                [self SaveVideo];
                                pFrameYUV->key_frame = nKeyFrame;
                                if(pFrameSnap!=NULL)
                                {
                                    @synchronized(_my_snapframe)
                                    {
                                        I420Copy(pFrameYUV->data[0], pFrameYUV->linesize[0],
                                                 pFrameYUV->data[1], pFrameYUV->linesize[1],
                                                 pFrameYUV->data[2], pFrameYUV->linesize[2],
                                                 pFrameSnap->data[0], pFrameSnap->linesize[0],
                                                 pFrameSnap->data[1], pFrameSnap->linesize[1],
                                                 pFrameSnap->data[2], pFrameSnap->linesize[2],
                                                 pFrameYUV->width, pFrameYUV->height);
                                    }
                                }
                                
                                //[self F_SavePhoto:pFrameYUV];
                                
                                [self PlatformDisplay:pFrameYUV];
                            }
                            else
                            {
                                [self SaveVideo];
                                pFrameYUV->key_frame = nKeyFrame;
                                
                                if(pFrameSnap!=NULL)
                                {
                                    @synchronized(_my_snapframe)
                                    {
                                        I420Copy(pFrameYUV->data[0], pFrameYUV->linesize[0],
                                                 pFrameYUV->data[1], pFrameYUV->linesize[1],
                                                 pFrameYUV->data[2], pFrameYUV->linesize[2],
                                                 pFrameSnap->data[0], pFrameSnap->linesize[0],
                                                 pFrameSnap->data[1], pFrameSnap->linesize[1],
                                                 pFrameSnap->data[2], pFrameSnap->linesize[2],
                                                 pFrameYUV->width, pFrameYUV->height);
                                    }
                                }
                                
                                //[self F_SavePhoto:pFrameYUV];
                                
                                sws_scale(img_convert_ctx_half,
                                          (const uint8_t *const *) pFrameYUV->data,
                                          pFrameYUV->linesize, 0,
                                          m_codecCtx->height,
                                          frame_b->data, frame_b->linesize);
                                
                                //frame_link2frame(frame_b,pFrameYUV);
                                [self frame_link2frame:frame_b DES:pFrameYUV];;
                                [self PlatformDisplay:pFrameYUV];
                                
                            }
                            
                        }
                        else
                        {
                            [self SaveVideo];
                            pFrameYUV->key_frame= nKeyFrame;
                            if(pFrameSnap!=NULL)
                            {
                                @synchronized(_my_snapframe)
                                {
                                    I420Copy(pFrameYUV->data[0], pFrameYUV->linesize[0],
                                             pFrameYUV->data[1], pFrameYUV->linesize[1],
                                             pFrameYUV->data[2], pFrameYUV->linesize[2],
                                             pFrameSnap->data[0], pFrameSnap->linesize[0],
                                             pFrameSnap->data[1], pFrameSnap->linesize[1],
                                             pFrameSnap->data[2], pFrameSnap->linesize[2],
                                             pFrameYUV->width, pFrameYUV->height);
                                }
                            }
                            //[self F_SavePhoto:pFrameYUV];
                            [self PlatformDisplay:pFrameYUV];
                            
                        }
                        if(self.imageView)
                        {
                            t2 = [[NSDate date] timeIntervalSince1970] * 1000;
                            subt = t2-t1;
                            if(subt<40)
                            {
                                subt= 40-subt;
                                usleep((useconds_t)(subt*1000) );
                            }
                            t1 = [[NSDate date] timeIntervalSince1970] * 1000;
                        }
                    }
                }
                
            }
            av_packet_unref(&pkt);
        }
    }
    [self F_SetTimeout:1];
    if (m_formatCtx!=NULL) {
        m_formatCtx->interrupt_callback.opaque = NULL;
        m_formatCtx->interrupt_callback.callback = NULL;
    }
    self.bPlaying = NO;
    self.bNeedRecon = YES;
    self.nFlag = 3;
    [self Releaseffmpeg];
}

//解码自定义协议传输的mjgpeg
-(void)DecordData_Mjpeg:(NSData *)data
{
    
    self.nRelinkTime = 0;
    uint8_t *outbuff = (uint8_t *)[data bytes];
    if(data.length==0) {
        return ;
    }
    int ret;
    
    // int nKeyFrame = 1;
    int size = (int)data.length;
    {
        if (size>0)
        {
            AVPacket packetA = {0};
            av_init_packet(&packetA);
            packetA.data = outbuff;
            packetA.size = size;
            /*
             int frameFinished = 0;
             ret = avcodec_decode_video2(m_codecCtx, m_decodedFrame, &frameFinished, &packetA);
             if(ret<0 || frameFinished == 0)
             {
             ret = -1;
             }
             else
             {
             ret = 0;
             }
             */
            ret = -1;
            if (avcodec_send_packet(m_codecCtx, &packetA) == 0)
            {
                if (avcodec_receive_frame(m_codecCtx, m_decodedFrame) != 0) {
                    ret = -1;
                } else {
                    ret = 0;
                }
            }
            else
            {
                ret = -1;
            }
            
            if(ret == 0)
            {
                
                [self InitMediaSN:self.b480];
                _nDispWidth = m_codecCtx->width;
                _nDispHeight = m_codecCtx->height;
                if(!_bSetRecordWH)
                {
                    _nRecordWidth = _nDispWidth;
                    _nRecordHeight = _nDispHeight;
                }
                
                sws_scale(img_convert_ctx,
                          (const uint8_t *const *) m_decodedFrame->data,
                          m_decodedFrame->linesize, 0,
                          m_codecCtx->height,
                          pFrameYUV->data, pFrameYUV->linesize);
                
                
                int dd = (int)(_nScale*100);
                if(dd <=100) //不放大
                {
                    if(pFrameSnap==NULL)
                    {
                        pFrameSnap = av_frame_alloc();
                        
                        pFrameSnap->format = AV_PIX_FMT_YUV420P;
                        pFrameSnap->width = _nDispWidth;
                        pFrameSnap->height =_nDispHeight;
                        
                        ret = av_image_alloc(
                                             pFrameSnap->data, pFrameSnap->linesize, pFrameSnap->width,
                                             pFrameSnap->height,
                                             AV_PIX_FMT_YUV420P, 4);
                        _my_snapframe->pFrame = pFrameSnap;
                    }
                }
                else
                {
                    AVFrame *pFrameYUV_D = av_frame_alloc();
                    pFrameYUV_D->format = AV_PIX_FMT_YUV420P;
                    pFrameYUV_D->width = (int)(_nDispWidth*_nScale);
                    pFrameYUV_D->height = (int)(_nDispHeight*_nScale);
                    ret = av_image_alloc(
                                         pFrameYUV_D->data, pFrameYUV_D->linesize, pFrameYUV_D->width,
                                         pFrameYUV_D->height,
                                         AV_PIX_FMT_YUV420P, 4);
                    I420Scale(pFrameYUV->data[0],pFrameYUV->linesize[0],
                              pFrameYUV->data[1],pFrameYUV->linesize[1],
                              pFrameYUV->data[2],pFrameYUV->linesize[2],
                              pFrameYUV->width,pFrameYUV->height,
                              pFrameYUV_D->data[0],pFrameYUV_D->linesize[0],
                              pFrameYUV_D->data[1],pFrameYUV_D->linesize[1],
                              pFrameYUV_D->data[2],pFrameYUV_D->linesize[2],
                              pFrameYUV_D->width,pFrameYUV_D->height,
                              kFilterLinear);
                    
                    av_freep(&(pFrameYUV->data[0]));
                    av_frame_free(&pFrameYUV);
                    pFrameYUV = av_frame_alloc();
                    
                    pFrameYUV->format = AV_PIX_FMT_YUV420P;
                    pFrameYUV->width = _nDispWidth;
                    pFrameYUV->height =_nDispHeight;
                    
                    ret = av_image_alloc(
                                         pFrameYUV->data, pFrameYUV->linesize, pFrameYUV->width,
                                         pFrameYUV->height,
                                         AV_PIX_FMT_YUV420P, 4);
                    
                    if(pFrameSnap==NULL)
                    {
                        pFrameSnap = av_frame_alloc();
                        
                        pFrameSnap->format = AV_PIX_FMT_YUV420P;
                        pFrameSnap->width = _nDispWidth;
                        pFrameSnap->height =_nDispHeight;
                        
                        ret = av_image_alloc(
                                             pFrameSnap->data, pFrameSnap->linesize, pFrameSnap->width,
                                             pFrameSnap->height,
                                             AV_PIX_FMT_YUV420P, 4);
                        _my_snapframe->pFrame = pFrameSnap;
                    }
                    
                    int cx =  pFrameYUV_D->width/2;
                    int cy =  pFrameYUV_D->height/2;
                    
                    int lx = cx-(pFrameYUV->width/2);
                    lx=(lx+1)/2;
                    lx*=2;
                    
                    
                    int ly = cy-(pFrameYUV->height/2);
                    ly = (ly+1)/2;
                    ly*=2;
                    
                    Byte *psrc;
                    Byte *pdes;
                    
                    Byte *pSrcStart = pFrameYUV_D->data[0]+ly*pFrameYUV_D->linesize[0]+lx;
                    pdes =(Byte*) pFrameYUV->data[0];
                    
                    for(int yy=0;yy<pFrameYUV->height;yy++)
                    {
                        psrc =(Byte*)pSrcStart+yy*pFrameYUV_D->linesize[0];
                        memcpy(pdes+yy*pFrameYUV->linesize[0],psrc,(size_t)(pFrameYUV->linesize[0]));
                    }
                    
                    
                    
                    pSrcStart = pFrameYUV_D->data[1]+ly/2*pFrameYUV_D->linesize[1]+lx/2;
                    pdes = pFrameYUV->data[1];
                    
                    for(int yy=0;yy<pFrameYUV->height/2;yy++)
                    {
                        psrc = pSrcStart+yy*pFrameYUV_D->linesize[1];
                        memcpy(pdes+yy*pFrameYUV->linesize[1],psrc,(size_t )pFrameYUV->linesize[1]);
                        
                    }
                    
                    pSrcStart = pFrameYUV_D->data[2]+ly/2*pFrameYUV_D->linesize[2]+lx/2;
                    pdes = pFrameYUV->data[2];
                    
                    for(int yy=0;yy<pFrameYUV->height/2;yy++)
                    {
                        psrc = pSrcStart+yy*pFrameYUV_D->linesize[2];
                        memcpy(pdes+yy*pFrameYUV->linesize[1],psrc,(size_t )pFrameYUV->linesize[2]);
                    }
                    av_freep(&(pFrameYUV_D->data[0]));
                    av_frame_free(&pFrameYUV_D);
                }
                
                
                if(self.bFlip)
                {
                    //[self frame_rotate_180:pFrameYUV DesFrame:frame_a];
                    //av_frame_copy(pFrameYUV, frame_a);
                    I420Rotate(pFrameYUV->data[0], pFrameYUV->linesize[0],
                               pFrameYUV->data[1], pFrameYUV->linesize[1],
                               pFrameYUV->data[2], pFrameYUV->linesize[2],
                               frame_a->data[0], frame_a->linesize[0],
                               frame_a->data[1], frame_a->linesize[1],
                               frame_a->data[2], frame_a->linesize[2],
                               frame_a->width, frame_a->height,kRotate180);
                    
                    
                    I420Copy(frame_a->data[0], frame_a->linesize[0],
                             frame_a->data[1], frame_a->linesize[1],
                             frame_a->data[2], frame_a->linesize[2],
                             pFrameYUV->data[0], pFrameYUV->linesize[0],
                             pFrameYUV->data[1], pFrameYUV->linesize[1],
                             pFrameYUV->data[2], pFrameYUV->linesize[2],
                             frame_a->width, frame_a->height);
                }
                
                if(self.b3D)
                {
                    sws_scale(img_convert_ctx_half,
                              (const uint8_t *const *) pFrameYUV->data,
                              pFrameYUV->linesize, 0,
                              _nDispHeight,
                              frame_b->data, frame_b->linesize);
                    
                    //frame_link2frame(frame_b,pFrameYUV);
                    [self frame_link2frame:frame_b DES:pFrameYUV];;
                }
                [self SaveVideo];
                pFrameYUV->key_frame = 1;
                if(pFrameSnap!=NULL)
                {
                    @synchronized(_my_snapframe)
                    {
                        I420Copy(pFrameYUV->data[0], pFrameYUV->linesize[0],
                                 pFrameYUV->data[1], pFrameYUV->linesize[1],
                                 pFrameYUV->data[2], pFrameYUV->linesize[2],
                                 pFrameSnap->data[0], pFrameSnap->linesize[0],
                                 pFrameSnap->data[1], pFrameSnap->linesize[1],
                                 pFrameSnap->data[2], pFrameSnap->linesize[2],
                                 pFrameYUV->width, pFrameYUV->height);
                    }
                }
                //[self F_SavePhoto:pFrameYUV];
                [self PlatformDisplay:pFrameYUV];
                
            }
            av_packet_unref(&packetA);
            self.bPlaying = YES;
        }
    }
    return;
}

-(void)F_DowLoadFile_GK_LangTong
{
    
}

-(int)naDownloadFile:(NSString *)sPath   Sucess:(Sucess)sucess  Progress:(Progress)Progress  Fail:(Fail)Fail
{
    if(self.nIC_Type == IC_GK)
    {
        
        return 0;
    }
    
    //if(!self.bVaild && self.nIC_Type == IC_GKA)
    //    return -100;
    if(!sPath)
        return -2;
    MyDownLoad_a *download = [[MyDownLoad_a alloc] init];
    [self.downArray addObject:download];
    
    download.session_id = self.session_id;
    download.file_all_size = 0;
    download.nSize = 0;
    
    
    download.VideosFloder = self.VideosFloder;
    download.PhotosFloder = self.PhotosFloder;
    
    //[download F_DownLoad:sPath Sucess:sucess Progress:Progress Fail:Fail];
    __weak JH_WifiCamera *weakself = self;
    [download F_DownLoad:sPath Sucess:^(NSString *tempfile) {
        [weakself.downArray removeObject:download];
        sucess(tempfile);
    } Progress:^(NSInteger precent) {
        Progress(precent);
    } Fail:^{
        if(weakself.downArray.count>0)
            [weakself.downArray removeObject:download];
        Fail();
    }];
    return 0;
}

-(void)naCancelDownload
{
    for(MyDownLoad_a *download in self.downArray)
    {
        [download disconnect];
    }
    
}


-(int)naGetThumb:(NSString *)filename  Sucess:(Thumb_Sucess)sucess
{
    
    NSString *str = [filename lastPathComponent];
    
    if(self.nIC_Type == IC_GP)
    {
        MyThumb  *myThumb =[[MyThumb alloc] init];
        [myThumb download:str  Sucess:sucess];
        return 0;
    }
    //if(!self.bVaild && self.nIC_Type == IC_GKA)
    //    return -100;
    MyThumb  *myThumb =[[MyThumb alloc] init];
    [self.downArray_thumb addObject:myThumb];
    myThumb.session_id = self.session_id;
    
    [myThumb download:str  Sucess:sucess];
    return 0;
}

-(void)naCancelGetThumb
{
    for(MyThumb *download in self.downArray_thumb)
    {
        download.bCancel = YES;
    }
    __weak JH_WifiCamera *weakself = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        [weakself.downArray_thumb removeAllObjects];
    });
    
}

-(void)naSetDownLoadDesFolder:(NSString *)VideosFloder  PhotoFloder:(NSString *)PhotosFloder
{
    self.VideosFloder =VideosFloder;
    self.PhotosFloder =PhotosFloder;
}

-(void)F_StratListenat8001
{
    struct sockaddr_in myaddr;
    self.socket_udp8001= socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(_socket_udp8001 <0) {
        return ;
    }
    bzero((char *) &myaddr, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    myaddr.sin_port = htons(8001);
    
    int value = 1;
    int status;
    status = setsockopt(_socket_udp8001, SOL_SOCKET, SO_REUSEADDR, &value, sizeof(value));
    
    if (status) {
        // fprintf(stderr, "SO_REUSEADDR failed! (%s)\n", strerror(errno));
        shutdown(_socket_udp8001, 2);
        close(_socket_udp8001);
        _socket_udp8001 = -1;
        
        return;
    }
    status = setsockopt(_socket_udp8001, SOL_SOCKET, SO_REUSEPORT, &value, sizeof(value));
    if (status) {
        //fprintf(stderr, "SO_REUSEPORT failed! (%s)\n", strerror(errno));
        shutdown(_socket_udp8001, 2);
        close(_socket_udp8001);
        _socket_udp8001 = -1;
        return;
    }
    
    
    
    if (bind(_socket_udp8001, (struct sockaddr *)&myaddr, sizeof(myaddr)) <0)
    {
        printf("rev_socket bind failed!\n");
        shutdown(_socket_udp8001, 2);
        close(_socket_udp8001);
        _socket_udp8001 = -1;
        return ;
    }
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Byte readBuff[1000];
        int size;
        struct sockaddr_in servaddr;
        while(YES)
        {
            struct timeval timeoutA = {0, 1000 * 10};
            setsockopt(weakself.socket_udp8001, SOL_SOCKET, SO_RCVTIMEO, (char *) &timeoutA,
                       sizeof(struct timeval));
            ssize_t nbytes = recvfrom(weakself.socket_udp8001, readBuff,1000, 0,(struct sockaddr *) &servaddr, (socklen_t *) &size);
            if(nbytes>0)
            {
                NSData *data = [[NSData alloc] initWithBytes:readBuff length:nbytes];
                [weakself F_RevData8001:data];
            }
            usleep(1000*10);
        }
    });
}


-(void)F_StratListenat20000
{
    struct sockaddr_in myaddr;
    _bRead20000 = NO;
    if(_socket_udp20000>0)
        return;
    self.socket_udp20000 = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(_socket_udp20000 <0)
    {
        return;
    }
    
    bzero((char *) &myaddr, sizeof(myaddr));
    myaddr.sin_family = AF_INET;
    myaddr.sin_addr.s_addr = htonl(INADDR_ANY);
    myaddr.sin_port = htons(20000);
    
    int value = 1;
    int status;
    status = setsockopt(_socket_udp20000, SOL_SOCKET, SO_REUSEADDR, &value, sizeof(value));
    status = setsockopt(_socket_udp20000, SOL_SOCKET, SO_REUSEPORT, &value, sizeof(value));
    if (bind(_socket_udp20000, (struct sockaddr *)&myaddr, sizeof(myaddr)) <0)
    {
        shutdown(_socket_udp20000, 2);
        close(_socket_udp20000);
        _socket_udp20000 = -1;
        return ;
    }
    _bRead20000 = YES;
    __weak  JH_WifiCamera *weakself = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        Byte readBuff[50];
        int size;
        struct sockaddr_in servaddr; /* the server's full addr */
        struct timeval tv;
        tv.tv_sec = 0;
        tv.tv_usec = 1000*5;
        fd_set read_fd;
        
        while(weakself.bRead20000)
        {
            if(weakself.socket_udp20000<0)
                break;
            
            tv.tv_sec = 0;
            tv.tv_usec = 1000*10;
            
            FD_ZERO(&read_fd); // 在使用之前总是要清空
            // 开始使用select
            FD_SET(weakself.socket_udp20000, &read_fd); // 把socka放入要测试的描述符集中
            
            int nRet = select(weakself.socket_udp20000+1, &read_fd, NULL, NULL, &tv);
            if(nRet<=0)
            {
                continue;
            }
            if (!(FD_ISSET(weakself.socket_udp20000, &read_fd)))
            {
                continue;
            }
            
            ssize_t nbytes = recvfrom(weakself.socket_udp20000, readBuff,48, 0,(struct sockaddr *) &servaddr, (socklen_t *) &size);
            if(nbytes>0)
            {
                NSData *data = [[NSData alloc] initWithBytes:readBuff length:nbytes];
                if(data.length!=7)
                {
                    [weakself F_Read2000_27Lenght:data];
                }
                else
                {
                    [weakself F_RevData20000:data];
                }
            }
            usleep(1000*5);
        }
    });
    
}

-(void)F_Read2000_27Lenght:(NSData *)data
{
    char *readBuff =(char *)[data bytes];
    if(self.nIC_Type == IC_GKA)
    {
        int nbytes = (int)data.length;
        if(nbytes>sizeof(NET_UTP_DATA))
        {
            NET_UTP_DATA *pHead = (NET_UTP_DATA *) readBuff;
            nbytes -= sizeof(NET_UTP_DATA);
            NSMutableData *readBuffA = [[NSMutableData alloc] init];
            Byte *readBuff = (Byte *)[data bytes];
            [readBuffA appendBytes:&pHead->seq length:4];
            [readBuffA appendBytes:(readBuff+sizeof(NET_UTP_DATA)) length:nbytes];
            if([self.delegate respondsToSelector:@selector(GetWifiData:)])
            {
                [self.delegate GetWifiData:readBuffA];
            }
        }
    }
    else
    {
        if(data.length>=8)
        {
            if(readBuff[0]=='J' && readBuff[1]=='H' &&readBuff[2]=='C' &&readBuff[3]=='M' &&readBuff[4]=='D' && readBuff[5]=='T' &&readBuff[6]=='C')
            {
                if([self.delegate respondsToSelector:@selector(GetWifiData:)])
                {
                    NSData *dat = [NSData dataWithBytes:readBuff+7 length:data.length-7];
                    [self.delegate GetWifiData:dat];
                }
            }
        }
    }
}
-(void)F_RevData20000:(NSData *)data
{
    if(!data)
        return;
    if(data.length!=7)
        return;
    Byte *cmd = (Byte *)[data bytes];
    if(cmd[0]=='J' &&
       cmd[1]=='H' &&
       cmd[2]=='C' &&
       cmd[3]=='M' &&
       cmd[4]=='D' )
    {
        if(cmd[5]==0x00)   //遥控器按键
        {
            if([self.delegate respondsToSelector:@selector(StatusChanged_GP:)])
            {
                self.nSdStatus_GP &=0xFF00;
                self.nSdStatus_GP |=cmd[6];
                [self.delegate StatusChanged_GP:(int)(self.nSdStatus_GP)];
            }
        }
        if(cmd[5]==0x10)   //状态
        {
            
            self.nSdStatus_GP &=0x00FF;
            cmd[6]  ^=0x04;
            if(cmd[6] & 0x01)  //正在录像
            {
                self.nSdStatus_GP |=0x0100;
                self.nSdStatus |=SD_Recording;
            }
            else
            {
                //self.nSdStatus_GP &= (0x0100 ^ 0xFFFF);
                self.nSdStatus &= (SD_Recording^0xFFFF);
            }
            
            if(cmd[6] & 0x02)  //  拍照
            {
                self.nSdStatus_GP |=0x0200;
            }
            else
            {
                //self.nSdStatus_GP &= (0x0200 ^ 0xFFFF);
            }
            
            if(cmd[6] & 0x04)  //SD
            {
                self.nSdStatus_GP |=0x0400;
                self.nSdStatus |= SD_Ready;
            }
            else
            {
                self.nSdStatus &=(SD_Ready ^ 0xFFFF);
            }
            
            if(cmd[6] & 0x08)  //卡满
            {
                self.nSdStatus_GP |=0x0800;
                self.nSdStatus &=(SD_Ready ^ 0xFFFF);
            }
            
            
            if(cmd[6] & 0x10)
            {
                self.nSdStatus_GP |=0x1000;      //低电压
            }
            
            if([self.delegate respondsToSelector:@selector(StatusChanged_GP:)])
            {
                [self.delegate StatusChanged_GP:(int)(self.nSdStatus_GP)];
            }
        }
    }
}

-(void)F_RevData8001:(NSData *)data
{
    if(!data)
        return;
    __weak  JH_WifiCamera  *weakself = self;
    if(data.length>12)
    {
        NSData *data1 = [data subdataWithRange:NSMakeRange(12, data.length-12)];
        NSString *str = [[NSString alloc] initWithData:data1 encoding:NSUTF8StringEncoding];
        str = [str uppercaseString];
        NSLog(@"status:%@",str);
        if([str compare:@"SNAP"] == NSOrderedSame )
        {
            self.nSdStatus |= SD_SNAP;
            self.nSdStatus |= SD_Ready;
            [self F_SentStatus];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                weakself.nSdStatus &= (SD_SNAP^0xFFFF);
                [weakself F_SentStatus];
            });
            
            return;
        }
        else if([str compare:@"REC_ON"] == NSOrderedSame )
        {
            self.nSdStatus |= SD_Ready;
            self.nSdStatus |= SD_Recording;
        }
        else if([str compare:@"REC_OFF"] == NSOrderedSame )
        {
            self.nSdStatus &= (SD_Recording^0xFFFF);
        }
        else if([str compare:@"SD_EXIST"] == NSOrderedSame)
        {
            self.nSdStatus |= SD_Ready;
            self.nSdStatus &= (SD_Recording^0xFFFF);
            self.nSdStatus &= (SD_SNAP^0xFFFF);
            //            NSLog(@"SD Ready");
        }
        else if([str compare:@"SD_UNEXIST"] == NSOrderedSame )
        {
            self.nSdStatus &= (SD_Ready^0xFFFF);
            self.nSdStatus &= (SD_Recording^0xFFFF);
            self.nSdStatus &= (SD_SNAP^0xFFFF);
            //            NSLog(@"NO SD");
        }
        [self F_SentStatus];
    }
    
}

@end
