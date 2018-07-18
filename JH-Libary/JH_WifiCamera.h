//
//  JH_WifiCamera.h
//  JH_WifiCamera
//
//  Created by AivenLau on 16/8/1.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "JH_OpenGLView.h"

//#define   sima

typedef void (^Progress_GP)(NSInteger precent,NSData *data);
typedef void (^SDFiles_GP)(NSData *data);
typedef void (^Thumbnail_GP)(UIImage *img);

typedef void (^Progress)(NSInteger precent);
typedef void (^Sucess)(NSString *tempfile);
typedef void (^Fail)(void);


typedef void (^Thumb_Sucess)(UIImage *img,NSString *sFilename);
typedef void (^Thumb_Fail)(void);

//#define   ABR

typedef enum
{
    Status_Connected=1,
    LocalRecording=2,
    SD_Ready=4,
    SD_Recording=8,
    SD_SNAP=0x10,
    SSID_CHANGED=0x20
}SD_STATUS;


typedef enum
{
    //以下是枚举成员
    IC_NO= -1,
    IC_GK = 0,      //192.168.234.X
    IC_GP,          //192.168.25.X
    IC_SN,          //192.168.123.X
    IC_GKA,             //175.16.10.X
    IC_GPRTSP,   //192.168.26.X
    IC_GPH264,   //192.168.27.X
    IC_GPRTP,    //192.168.28.X
    IC_GPH264A,   //192.168.30.X
    IC_GPRTPB,   //192.168.29.X
    IC_COUNT
}IC_TYPE;


typedef enum
{
    TYPE_SNAP_FILES=0,
    TYPE_REC_FILES
}TYPE_FILES;

typedef enum
{
    TYPE_ONLY_PHONE = 0,
    TYPE_ONLY_SD,
    TYPE_BOTH_PHONE_SD,
}TYPE_SNAP_REC;

typedef enum
{
    TYPE_DEST_SNADBOX= 0,
    TYPE_DEST_GALLERY
}TYPE_DEST;


#define  D_Check_Relinker

#define H264Record

@protocol ReceivedData_Delegate<NSObject>
@optional
-(void)StatusChanged:(int)nStatus;         //返回 wifi 模块状态
-(void)GetFiles:(NSString *)sFilesName;     //返回 SD卡上文件（只针对 国科 模块）
-(void)StatusChanged_GP:(int)nStatus;       //返回 wifi模块上的按键等数据
-(void)ReceiveImg:(UIImage *)image;         // 如果 实现这个代理，SDK内部不显示图像，而有APP上层来显示接受到的图像帧
-(void)GetWifiData:(NSData *)data;          //返回 wifi模块从飞控读取的状态数据
-(void)SnapPhotoCompelete:(BOOL)bSaveOK;    //拍照 返回
-(void)GetErrorFrame:(uint64_t)nErrorFrame;     // 保留
-(void)GetFrameCount:(uint64_t)nCount;    //保留
@end

@interface JH_WifiCamera : NSObject
{
    
}

@property(weak,nonatomic)  id<ReceivedData_Delegate> delegate;

@property(assign,nonatomic)  int nReLinkABC;

-(void)naSetVrBackground:(BOOL)bWhite;              //VR 显示时， 空白部分是否显示 白色
-(void)naSetAlbumName:(NSString *)sAlbumName;       //设定 如果录像拍照到 系统图册时的 相册名称
-(BOOL)naInit:(NSString *)sPath;                   //初始化，开始接受wifi数据，显示图像
-(void)naStop;                                     // 结束
-(void)naSetIcType:(IC_TYPE)nICType;              //设定 wifi 模块 类型（新版本已经废除，在naInit中自动判断）
-(int)naSnapPhoto:(NSString *)sPath SaveTyoe:(TYPE_SNAP_REC)nType Destination:(TYPE_DEST)dest;      //拍照
-(int)naStartRecord:(NSString *)sPath SaveTyoe:(TYPE_SNAP_REC)nType Destination:(TYPE_DEST)dest;    //开始录像
-(int)naStopRecord_All;        //停止所有录像
-(void)naStopRecord:(TYPE_SNAP_REC)nType;    //停止录像
-(int)naSetFilp:(BOOL)bFlip;        //图像是否翻转
-(int)naSet3D:(BOOL)b3D;         // 是否VR显示
-(int)naSet3DA:(BOOL)b3D;     //保留
-(void)naSetDispView:(JH_OpenGLView *)dispView  BackGround:(UIImage *)background;     //设定显示 的 View 以及没有wifi图像时的 背景
-(void)naSetDispViewB:(JH_OpenGLView *)dispView  BackGround:(UIImage *)background; //保留

-(void)naSetCustomer:(NSString *)sCustomer;       //设定 客户 只针对 国科模块， “sima” 表示 客户是司马 ，目前只有这一个设定
-(int)naDeleteSDFile:(NSString *)sFullPath;    //删除 SD 卡上的文件 （只针对 国科模块）

-(void)naSetWifiPassword:(char *)spassword;    //修改wifi密码，只针对 凌通某些模块，需要配合固件


-(int)naGetFiles:(TYPE_FILES)ntype;     //获取 SD 卡文件列表 只针对 国科模块
-(int)naDownloadFile:(NSString *)sPath   Sucess:(Sucess)sucess  Progress:(Progress)Progress  Fail:(Fail)Fail; //开始下载 SD 上的 文件  只针对 国科模块
-(void)naCancelDownload;     //取消下载


-(int)naGetThumb:(NSString *)filename  Sucess:(Thumb_Sucess)sucess;    //获取SD 卡上 视频 文件的 缩率图  只针对 国科模块
-(void)naCancelGetThumb;   //取消 获取
-(BOOL)isPhoneRecording;  //模块是否在录像
-(void)naSetRecordWH:(int)w Height:(int)h; //设定 录像的 宽高
-(int64_t)naGetRecordTime; //返回 正在录像 的时长 ms
-(BOOL)naSentCmd:(NSData *)data; //向飞控发送命令
-(void)naRotation:(int)n;// n = 0 90  -90  显示是否转90度显示，主要是有些APP，需要竖屏显示， 但我们模块返回的图像都是横屏的，所以需要设定才能正常满屏显示
-(void)naSetScale:(float)n;  //n >=1;   目前还只针对  类型 IC_GPRTPB
-(BOOL)naGetConnected;  //是否连上模块

-(void)naSetRecordAudio:(BOOL)bGAudio;  //录像是否录入声音


// 以下保留
//--------------- Reserved Fuction -----
-(void)naGKA_Pause;
-(void)naGKA_Resume;
- (int)naGetRssi;
- (int)naSetRecFps:(int)nFps;
-(int)naGetFps;
-(int)naYD_SetFps:(int)nfps;
-(NSString *)naGetControlType;
-(void)naSetGKA_SentCmdByUDP:(BOOL)bUDP;

-(void)naSetGpLanguage:(int)nLan;
-(UIImage *)naGetThumbnail:(NSString *)sAviFile;
-(void)naSetDownLoadDesFolder:(NSString *)VideosFloder  PhotoFloder:(NSString *)PhotosFloder;
-(void)naSentStopCtrol;
-(int)naPlay;
-(int)naStartCheckSDStatus:(BOOL)bStart;
-(BOOL)naInit:(NSString *)sPath  tcp:(BOOL)bTCP;
-(int)naStopSaveVideo;
-(int)naStartRemoteRec;
-(int)naStopRemoteRec;
-(int)naPlay:(NSString *)sPath  ImageView:(JH_OpenGLView *)imgview;
-(BOOL)naPause;
-(BOOL)naIsValidType;

@end
