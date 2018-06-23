/*!
 ****************************************************************************
 ** FileName     : phone_rl_protocol.h
 **
 ** Description  : interface with RL phone app.
 **
 ** Author       : Bruce <zhaoquanfeng@gokemicro.com>
 ** Create Date  : 2016-05-09
 **
 ** (C) Copyright 2013-2036 by GOKE MICROELECTRONICS CO.,LTD
 **
 *****************************************************************************
 */

/****************************************************************************
 控制命令流程(cmd sock)：
 
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于传输数据
 
 1 手机连接设备成功后，发送数据结构 T_NET_CMD_MSG, type = CMD_LOGIN, session_id 为0.
 然后接着发送 T_NET_LOGIN， 用户名和密码为空(不登录)，
 然后接收 T_REQ_MSG, 里面会有 session_id, 之后发送的结构都填上返回的 session_id; ret 为0 表示成功。
 
 2 发送 T_NET_CMD_MSG, type = CMD_ADJUST_TIME, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_DATE_TIME，(填时间如 2016-4-29 13:40:00)
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 3 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_CONFIG, type = CONFIG_VIDEO，res = 0 对应主码流 res = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 然后接收 T_NET_VIDEO_INFO
 
 4 发送 T_NET_CMD_MSG, type = CMD_OPEN_STREAM, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应主码流 stream_type = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 5 手机界面点下关闭预览(或者离开预览界面)
 发送 T_NET_CMD_MSG, type = CMD_CLOSE_STREAM, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应主码流 stream_type = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 当第4步，发送打开子码流的命令后。设备端会去连接手机，建立新的socket，然后会不停的向该socket发送H264子码流，这样手机端接收到
 子码流后，实时显示在手机端。
 
 对应第3步的获取配置，设置配置步骤如下:
 6 发送 T_NET_CMD_MSG, type = CMD_SET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_CONFIG, type = CONFIG_VIDEO，res = 0 对应主码流 res = 1 对应子码流
 然后发送 T_NET_VIDEO_INFO
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 对应第4，5步，打开关闭流，强制I帧配置步骤如下:
 7 发送 T_NET_CMD_MSG, type = CMD_FORCE_I, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应主码流 stream_type = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 8 手机端点拍照按钮时，在手机端拍照。
 
 9 手机端点开始录像按钮时，手机端开始录像子码流，SD卡开始录像主码流（发送命令到设备端去控制）
 发送 T_NET_CMD_MSG, type = CMD_SD_REC_START, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应主码流 stream_type = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。 SD卡不存在，SD卡格式不是FAT32等等都会 返回 非0,表示SD卡不能录像。
 
 10 手机端点停止录像按钮时，手机端停止录像子码流，SD卡停止录像主码流（发送命令到设备端去控制）
 发送 T_NET_CMD_MSG, type = CMD_SD_REC_STOP, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应主码流 stream_type = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 11 发送 T_NET_CMD_MSG, type = CMD_PTZ_CONTROL, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_PTZ_CONTROL
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 12 发送 T_NET_CMD_MSG, type = CMD_SNAP_TO_SD，session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应抓主码流图片 stream_type = 1 对应抓子码流图片
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 13 发送 T_NET_CMD_MSG, type = CMD_SET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_CONFIG, type = CONFIG_IMAGE，res = 0 对应主码流 res = 1 对应子码流
 然后发送 T_NET_IMAGE_INFO
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 14 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_CONFIG, type = CONFIG_IMAGE，res = 0 对应主码流 res = 1 对应子码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 然后接收 T_NET_IMAGE_INFO
 
 15 发送 T_NET_CMD_MSG, type = CMD_SET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_CONFIG, type = CONFIG_SYSTEM, res 无效
 然后发送 T_NET_SYSTEM_INFO
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 16 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着发送 T_NET_CONFIG, type = CONFIG_SYSTEM，res 无效
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 然后接收 T_NET_SYSTEM_INFO
 
 17 发送 T_NET_CMD_MSG, type = CMD_KEEP_LIVE, session_id 为第一次连接时设备返回的session_id.
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 
 
 ****************************************************************************/
//CONFIG_SD_REC_DIR_LIST


/****************************************************************************
 从SD卡获取录像文件列表
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于查找文件列表
 
 1 手机连接设备成功后，产生新的sock，用于查找文件列表。为了方便区别，我们称之为 search sock, 区别于之前的 cmd sock.
 手机向 search sock 发送数据结构 T_NET_CMD_MSG, type = CMD_SEARCH_SOCK, session_id 为 cmd sock 第一次连接返回的 session_id.
 这样，用 session_id 来对应 cmd sock 和 search sock.
 
 2  获取在某年某月中哪些天是有录像文件的
 手机向 search sock 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着向 search sock 发送 T_NET_CONFIG, type = CONFIG_SD_REC_DAY_LIST
 接着向 search sock 发送 T_NET_SD_REC_DAY_LIST (比其他的 config 多发送个数据结构)，里面填上年(减去2000)，月，type填255
 然后从 search sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后从 search sock 接收 T_NET_SD_REC_DAY_LIST
 
 3  获取从开始时间到结束时间的录像文件的目录信息
 手机向 search sock 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着向 search sock 发送 T_NET_CONFIG, type = CONFIG_SD_REC_DIR_LIST
 接着向 search sock 发送 T_NET_SD_REC_DIR_LIST，里面填上开始时间和结束时间，type填255，num 填0， send_buf 填 NULL;
 然后从 search sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后从 search sock 接收 T_NET_SD_REC_DIR_LIST，里面的num是查找到的文件数目
 然后从 search sock 接收 num 个 T_NET_SD_REC_DIR_INFO，里面有每个录像文件的信息
 
 4  获取从开始时间到结束时间的录像文件的文件信息
 手机向 search sock 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着向 search sock 发送 T_NET_CONFIG, type = CONFIG_SD_REC_FILE_LIST
 接着向 search sock 发送 T_NET_SD_REC_FILE_LIST，里面填上开始时间和结束时间，type填255，num 填0， send_buf 填 NULL;
 然后从 search sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后从 search sock 接收 T_NET_SD_REC_FILE_LIST，里面的num是查找到的文件数目
 然后从 search sock 接收 num 个 T_NET_SD_REC_FILE_INFO，里面有每个录像文件的信息
 
 从SD卡下载录像文件
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于下载文件
 
 1 手机连接设备成功后，产生新的sock，用于下载文件。为了方便区别，我们称之为 download sock, 区别于之前的 cmd sock.
 手机向 download sock 发送数据结构 T_NET_CMD_MSG, type = CMD_DOWNLOAD_SOCK, session_id 为 cmd sock 第一次连接返回的 session_id.
 这样，用 session_id 来对应 cmd sock 和 download sock.
 
 手机接着向 download sock 发送 T_NET_DOWNLOAD_CONTROL, type 表示下载rec还是snap类型，one_packet_size 表示每次接收数据包大小，name 表示下载文件的绝对路径名 (查找所得)
 手机然后从 download sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后手机端用 download sock 保持接收状态。
 
 2 手机端通过 download sock 不停接收数据流。每个包有包头 T_NET_DL_PACKET_HEADER,
 每次包的大小是 T_NET_DOWNLOAD_CONTROL中指定的one_packet_size (最后一次的包小于one_packet_size)
 
 
 ****************************************************************************/


/****************************************************************************
 从SD卡获取抓拍文件列表
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于查找文件列表
 
 1 手机连接设备成功后，产生新的sock，用于查找文件列表。为了方便区别，我们称之为 search sock, 区别于之前的 cmd sock.
 手机向 search sock 发送数据结构 T_NET_CMD_MSG, type = CMD_SEARCH_SOCK, session_id 为 cmd sock 第一次连接返回的 session_id.
 这样，用 session_id 来对应 cmd sock 和 search sock.
 
 2  获取在某年某月中哪些天是有抓拍文件的
 手机向 search sock 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着向 search sock 发送 T_NET_CONFIG, type = CONFIG_SD_SNAP_DAY_LIST
 接着向 search sock 发送 T_NET_SD_SNAP_DAY_LIST (比其他的 config 多发送个数据结构)，里面填上年(减去2000)，月，type填255
 然后从 search sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后从 search sock 接收 T_NET_SD_SNAP_DAY_LIST
 
 3  获取从开始时间到结束时间的抓拍文件的目录信息
 手机向 search sock 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着向 search sock 发送 T_NET_CONFIG, type = CONFIG_SD_SNAP_DIR_LIST
 接着向 search sock 发送 T_NET_SD_SNAP_DIR_LIST，里面填上开始时间和结束时间，type填255，num 填0， send_buf 填 NULL;
 然后从 search sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后从 search sock 接收 T_NET_SD_SNAP_DIR_LIST，里面的num是查找到的文件数目
 然后从 search sock 接收 num 个 T_NET_SD_SNAP_DIR_INFO，里面有每个录像文件的信息
 
 4  获取从开始时间到结束时间的抓拍文件信息
 手机向 search sock 发送 T_NET_CMD_MSG, type = CMD_GET_CONFIG, session_id 为第一次连接时设备返回的session_id.
 接着向 search sock 发送 T_NET_CONFIG, type = CONFIG_SD_SNAP_FILE_LIST
 接着向 search sock 发送 T_NET_SD_SNAP_FILE_LIST，里面填上开始时间和结束时间，type填255，num 填0， send_buf 填 NULL;
 然后从 search sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后从 search sock 接收 T_NET_SD_SNAP_FILE_LIST，里面的num是查找到的文件数目
 然后从 search sock 接收 num 个 T_NET_SD_SNAP_FILE_INFO，里面有每个抓拍文件的信息
 
 从SD卡下载抓拍文件
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于下载文件
 
 1 手机连接设备成功后，产生新的sock，用于下载文件。为了方便区别，我们称之为 download sock, 区别于之前的 cmd sock.
 手机向 download sock 发送数据结构 T_NET_CMD_MSG, type = CMD_DOWNLOAD_SOCK, session_id 为 cmd sock 第一次连接返回的 session_id.
 这样，用 session_id 来对应 cmd sock 和 download sock.
 
 手机接着向 download sock 发送 T_NET_DOWNLOAD_CONTROL, type 表示下载rec还是snap类型，one_packet_size 表示每次接收数据包大小，name 表示 下载文件的绝对路径名 (查找所得)
 手机然后从 download sock 接收 T_REQ_MSG, ret 为0 表示成功。
 然后手机端用 download sock 保持接收状态。
 
 2 手机端通过 download sock 不停接收数据流。每个包有包头 T_NET_DL_PACKET_HEADER,
 每次包的大小是 T_NET_DOWNLOAD_CONTROL中指定的one_packet_size (最后一次的包小于one_packet_size)
 
 
 ****************************************************************************/



/****************************************************************************
 数据发送流程 (data sock)：
 
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于传输数据
 
 1 手机连接设备成功后，产生新的sock，用于数据传输。为了方便区别，我们称之为 data sock, 区别于之前的 cmd sock.
 手机向 data sock 发送数据结构 T_NET_CMD_MSG, type = CMD_DATA_SOCK, session_id 为 cmd sock 第一次连接返回的 session_id.
 这样，用 session_id 来对应 cmd sock 和 data sock.
 手机接着发送 T_NET_STREAM_CONTROL, stream_type = 0 对应主码流, stream_type = 1 对应子码流, stream_type = 2 对应次码流
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 然后手机端用 data sock 保持接收状态。
 
 2 手机端向 cmd sock 发送 T_NET_CMD_MSG, type = CMD_OPEN_STREAM, session_id 为与cmd sock 和 data sock 对应的 session_id
 (参见控制命令流程中的第4步)
 
 3 手机端通过 data sock 不停接收数据流。每个包有包头 T_NET_FRAME_HEADER
 
 ****************************************************************************/


/****************************************************************************
 通知发送流程 (notice sock)：
 
 #define SERVER_TCP_LISTEN_PORT   0x7102
 设备端监听0x7102， 手机端连接 0x7102，手机端向设备端发送命令
 手机端在cmd sock 存在， session_id 存在的情况下，才能再次去连接 0x7102，与设备建立新的sock 连接，用于传输通知
 
 1 手机连接设备成功后，产生新的sock，用于通知传输。为了方便区别，我们称之为 notice sock, 区别于之前的 cmd sock.
 手机向 notice sock 发送数据结构 T_NET_CMD_MSG, type = CMD_NOTICE_SOCK, session_id 为 cmd sock 第一次连接返回的 session_id.
 这样，用 session_id 来对应 cmd sock 和 notice sock.
 然后接收 T_REQ_MSG, ret 为0 表示成功。
 然后手机端用 notice sock 保持接收状态。
 
 2 一旦设备端有事情发生，比如SD卡被插入或者拔出，会向 notice sock 发送信息T_NET_NOTICE_MSG。
 
 ****************************************************************************/


#ifndef _PHONE_RL_PROTOCOL_H__
#define _PHONE_RL_PROTOCOL_H__

#ifdef __cplusplus
extern "C"
{
#endif
    //校时
    typedef struct tagT_NET_DATE_TIME
    {
        unsigned short	usYear;		// 年
        unsigned short	usMonth;    // 月
        unsigned short	usDay;      // 日
        //unsigned char	ucWeek;     // 星期
        unsigned char	ucHour;     // 时
        unsigned char	ucMin;      // 分
        unsigned char	ucSec;      // 秒
        //unsigned short	usMSec;     // 毫秒
    } T_NET_DATE_TIME;
    
    // 录像打开关闭主码流，子码流
    typedef struct tagT_NET_REC_STREAM_CONTROL
    {
        int rec_stream_type; // 0 主码流， 1 子码流
        int rec_stream_control;  // 0 关闭， 1 打开
    } T_NET_REC_STREAM_CONTROL;
    
    
    // 主码流，子码流
    typedef struct tagT_NET_STREAM_CONTROL
    {
        int stream_type;     // 0 主码流， 1 子码流
    } T_NET_STREAM_CONTROL;
    
    
    typedef enum tagE_NET_DOWNLOAD_TYPE
    {
        DL_REC_FILE = 0,
        DL_SNAP_FILE,
    } E_NET_DOWNLOAD_TYPE;
    
    
    typedef struct tagT_NET_DOWNLOAD_CONTROL
    {
        E_NET_DOWNLOAD_TYPE dl_type;
        char name[256];
        int one_packet_size;
    } T_NET_DOWNLOAD_CONTROL;
    
    typedef struct tagT_NET_DL_PACKET_HEADER
    {
        char name[256]; //文件名
        int size;  //每个包的大小
        int no;   //包的序号
        int md5; // 没用
        
        unsigned long long file_all_size;  // 文件大小
        char reserve[8]; //保留

    } T_NET_DL_PACKET_HEADER;
    
    
    typedef enum tagE_NET_CMD_TYPE
    {
        CMD_LOGIN = 0,
        CMD_REBOOT,
        CMD_ADJUST_TIME,
        CMD_GET_CONFIG,
        CMD_SET_CONFIG,
        CMD_OPEN_STREAM,
        CMD_CLOSE_STREAM,
        CMD_FORCE_I,
        CMD_SNAP_TO_SD,
        CMD_SD_REC_START,
        CMD_SD_REC_STOP,
        CMD_DATA_SOCK,
        CMD_PTZ_CONTROL,
        CMD_KEEP_LIVE,
        CMD_NOTICE_SOCK,
        CMD_DOWNLOAD_SOCK,
        CMD_SEARCH_SOCK,
    } E_NET_CMD_TYPE;
    
    // 网络命令
    typedef struct tagT_NET_CMD_MSG
    {
        int session_id;
        E_NET_CMD_TYPE type;
    } T_NET_CMD_MSG;
    
    
    /*  出版本区别: 720P还是1080P，是什么sensor */
    typedef struct {
        int32_t   is_use_vendor_cfg;    //是否使用用户配置，即用户配置是否生效
        int8_t    is_single_control;    //是否单手机控制权
        int8_t    is_sima;              //是否是司马版本
        int8_t    rec_type;             //对应MMC_REC_TYPE 司马的版本只支持mov
        int8_t    is_rec_audio;         //录像是否带声音，mov目前不支持带声音
        
        int8_t    is_encrypt;           //是否使用加密芯片
        int8_t    is_low_touch;         //是否使用低触发
        int8_t    is_flip;              //左右翻转
        int8_t    is_mirror;            //上下翻转
        
        int16_t   gpio_9;           // 对应 GPIO_CFG_TYPE，可用来做 TX,拍照，录像，拍照并且录像
        int16_t   gpio_10;          // 对应 GPIO_CFG_TYPE, 可用来做 拍照，录像，拍照并且录像
        int32_t   snap_pulse_min;   // 触发抓图脉冲范围的最小值
        int32_t   snap_pulse_max;   // 触发抓图脉冲范围的最大值
        int32_t   rec_pulse_min;    // 触发录像脉冲范围的最小值
        int32_t   rec_pulse_max;    // 触发录像脉冲范围的最大值
        int32_t   snap_start_pulse_len;   // 拍照开始时，输出脉冲长度，单位ms
        int32_t   snap_stop_pulse_len;    // 拍照结束时，输出脉冲长度，单位ms
        int32_t   rec_start_pulse_len;    // 录像开始时，输出脉冲长度，单位ms
        int32_t   rec_stop_pulse_len;     // 录像结束时，输出脉冲长度，单位ms
        
        
        int32_t   uart1_boudrate;    //串口的波特率设置
        int32_t   led_flash_type;    //对应 LED_FLASH_VENDOR_TYPE
        int32_t   flight_ctrl_type;  //对应 FLIGHT_CTRL_TYPE ，飞控的控制协议类型
        
        int16_t   wifi_channel;       //wifi 的信道号
        int16_t   wifi_name_type;     //对应 WIFI_NAME_TYPE
        int8_t    wifi_name_prefix[32];  //WIFI名字前缀，如 "FPV-WIFI-"
        int8_t    wifi_password[32];     //wifi密码，目前没有使用， "000" 表示没有设置密码
        
        int8_t    app_login_name[32];      //登录APP的用户名，目前没有使用，如 "sima"
        int8_t    app_login_password[32];  //登录APP的密码，目前没有使用
        int8_t    firmware_version[32];    //版本号，方便生产时候区分
        int8_t    reserve[32];    //保留
        int32_t   rec_cbr_bps;
        int32_t   wifi_mode; //0,no change; 1 bg; 2 only n1; 3 only n2
    } GK_NET_VENDOR_CFG;
    
#if 0
    typedef enum tagE_NET_SDCARD_STATUS_TYPE
    {
        SDCARD_STATUS_EXIST = 0,    //sd 卡存在
        SDCARD_STATUS_NOT_EXIST,    //sd 卡不存在
        SDCARD_STATUS_OK,           //sd 存在且状态正常
        SDCARD_STATUS_ERROR,        //sd 存在但状态异常,如分区异常,不是FAT32格式
        SDCARD_STATUS_INSERT,       //sd 插入
        SDCARD_STATUS_REMOVE,       //sd 移除
        SDCARD_STATUS_FULL,         //sd 容量满，不够写入
        SDCARD_STATUS_FORMAT_START, //sd 格式化开始
        SDCARD_STATUS_FORMATTING,   //sd 正在格式化
        SDCARD_STATUS_FORMAT_END,   //sd 格式化结束
    } E_NET_SDCARD_STATUS_TYPE;
#endif
    
    typedef enum tagE_NET_SD_STATUS_OFFSET
    {
        SD_STATUS_IS_INSERT_OFFSET = 0,      /* sd 卡是否存在。1 插入；0 移除 */
        SD_STATUS_IS_WRITABLE_OFFSET = 1,    /* sd 存在的情况下，状态是否正常。1 正常；0 异常，如分区异常,不是FAT32格式等。*/
        SD_STATUS_IS_FREE_OFFSET = 2,        /* sd 存在的情况下，容量是否够写，小于20M显示不可写。1 可写；0 不可写，如SD卡满，只读等。*/
        SD_STATUS_IS_REC_OFFSET = 3,         /* sd 存在的情况下，是否正在录像。1 正在录像；0 没有录像。*/
        SD_STATUS_IS_SNAP_OFFSET = 4,        /* sd 存在的情况下，是否正在拍照。1 正在拍照；0 没有拍照。*/
        SD_STATUS_IS_FORMATTING_OFFSET = 5,  /* sd 存在的情况下，是否正在格式化。1 正在格式化；0 没有格式化。*/
    } E_NET_SD_STATUS_OFFSET;
    
    
    typedef struct tagT_NET_SD_FILE_INFO
    {
        char name[40];           //文件名
    } T_NET_SD_FILE_INFO;
    
#define SD_STATUS_IS_INSERT(x)        (x & (1 << SD_STATUS_IS_INSERT_OFFSET))
#define SD_STATUS_IS_WRITABLE(x)      (x & (1 << SD_STATUS_IS_WRITABLE_OFFSET))
#define SD_STATUS_IS_FREE(x)          (x & (1 << SD_STATUS_IS_FREE_OFFSET))
#define SD_STATUS_IS_REC(x)           (x & (1 << SD_STATUS_IS_REC_OFFSET))
#define SD_STATUS_IS_SNAP(x)          (x & (1 << SD_STATUS_IS_SNAP_OFFSET))
#define SD_STATUS_IS_FORMATTING(x)    (x & (1 << SD_STATUS_IS_FORMATTING_OFFSET))
    
#if 0
#define SD_STATUS_SET_INSERT(x)       (x |= (1 << SD_STATUS_IS_INSERT_OFFSET))
#define SD_STATUS_SET_WRITABLE(x)     (x |= (1 << SD_STATUS_IS_WRITABLE_OFFSET))
#define SD_STATUS_SET_FREE(x)         (x |= (1 << SD_STATUS_IS_FREE_OFFSET))
#define SD_STATUS_SET_REC(x)          (x |= (1 << SD_STATUS_IS_REC_OFFSET))
#define SD_STATUS_SET_SNAP(x)         (x |= (1 << SD_STATUS_IS_SNAP_OFFSET))
#define SD_STATUS_SET_FORMATTING(x)   (x |= (1 << SD_STATUS_IS_FORMATTING_OFFSET))
    
#define SD_STATUS_CLR_INSERT(x)       (x &= ~(1 << SD_STATUS_IS_INSERT_OFFSET))
#define SD_STATUS_CLR_WRITABLE(x)     (x &= ~(1 << SD_STATUS_IS_WRITABLE_OFFSET))
#define SD_STATUS_CLR_FREE(x)         (x &= ~(1 << SD_STATUS_IS_FREE_OFFSET))
#define SD_STATUS_CLR_REC(x)          (x &= ~(1 << SD_STATUS_IS_REC_OFFSET))
#define SD_STATUS_CLR_SNAP(x)         (x &= ~(1 << SD_STATUS_IS_SNAP_OFFSET))
#define SD_STATUS_CLR_FORMATTING(x)   (x &= ~(1 << SD_STATUS_IS_FORMATTING_OFFSET))
#endif
    
    typedef struct tagT_NET_NOTICE_MSG
    {
        //int session_id;
        unsigned int sd_status; /* SD卡状态 */
    } T_NET_NOTICE_MSG;
    
    
    typedef struct tagT_NET_SDCARD_INFO
    {
        int all_size;            /* 总容量，MB为单位 */
        int free_size;           /* 可写容量，MB为单位 */
        unsigned int sd_status;  /* SD卡状态 */
    } T_NET_SDCARD_INFO;
    
    typedef struct tagT_NET_LOGIN
    {
        char user[100];
        char passwd[100];
    } T_NET_LOGIN;
    
    typedef struct tagT_NET_PTZ_CONTROL
    {
        int size;
        unsigned char ptz_cmd[32];
    } T_NET_PTZ_CONTROL;
    
    
    typedef struct tagT_REQ_MSG
    {
        int ret;
        int session_id;
        //int test;
    } T_REQ_MSG;
    
    typedef enum tagE_NET_CONFIG_TYPE
    {
        CONFIG_SYSTEM = 0,
        CONFIG_DEVICE_ATTR,
        CONFIG_VIDEO,
        CONFIG_IMAGE,
        CONFIG_SERIAL,
        CONFIG_SD_CARD,
        CONFIG_SD_REC_DAY_LIST,
        CONFIG_SD_REC_FILE_LIST,
        CONFIG_SD_SNAP_DAY_LIST,
        CONFIG_SD_SNAP_FILE_LIST,
        CONFIG_SD_REC_DIR_LIST,
        CONFIG_SD_SNAP_DIR_LIST,
        CONFIG_AUDIO,
        CONFIG_SD_GET_REC_THUMB,
        CONFIG_VENDOR_INFO,
        CONFIG_SD_RM_FILE
    } E_NET_CONFIG_TYPE;
    
    typedef struct tagT_NET_SD_REC_DAY_LIST
    {
        int	year;  //查询年,0~255取值范围，代表2000~2255年
        int	month; //查询月，1~12为取值范围
        int	type;  //文件类型 ：0xff － 全部，0 － 定时录像，1 - 移动侦测，2 － 报警触发，3  － 手动录像
        unsigned int calendar_map; //如: 1号有录像，则 bit 1 为1，否则为 0
    } T_NET_SD_REC_DAY_LIST, T_NET_SD_SNAP_DAY_LIST;
    
    typedef struct tagT_NET_TIME
    {
        unsigned int  dwYear;
        unsigned int  dwMonth;
        unsigned int  dwDay;
        unsigned int  dwHour;
        unsigned int  dwMinute;
        unsigned int  dwSecond;
    } T_NET_TIME;
    
    typedef struct tagT_NET_SD_REC_FILE_LIST
    {
        int	type;  //文件类型 ：0xff － 全部，0 － 定时录像，1 - 移动侦测，2 － 报警触发，3  － 手动录像
        T_NET_TIME  begin_time;  //查找的开始时间
        T_NET_TIME	end_time;    //查找的结束时间
        int file_num; // 查找到的文件数目
        //char *send_buf; // 查找时填 NULL
        uint32_t  send_buf;
    } T_NET_SD_REC_FILE_LIST, T_NET_SD_SNAP_FILE_LIST;
    
    typedef struct tagT_NET_SD_REC_DIR_LIST
    {
        int	type;  //文件类型 ：0xff － 全部，0 － 定时录像，1 - 移动侦测，2 － 报警触发，3  － 手动录像
        T_NET_TIME  begin_time;  //查找的开始时间
        T_NET_TIME	end_time;    //查找的结束时间
        int dir_num; // 查找到的文件数目
        //char *send_buf; // 查找时填 NULL
        uint32_t  send_buf;
    } T_NET_SD_REC_DIR_LIST, T_NET_SD_SNAP_DIR_LIST;
    
    typedef struct tagT_NET_SD_REC_THUMB_LIST
    {
        char file_name[40]; //MOVI0001.mov
        int thumb_size;
        int  send_buf; //
    } T_NET_SD_REC_THUMB_LIST;
    
    
    typedef struct tagT_NET_SD_REC_FILE_INFO
    {
        char name[256];           //文件名
        unsigned long long size;  //文件的大小
    } T_NET_SD_REC_FILE_INFO, T_NET_SD_SNAP_FILE_INFO;
    
    typedef struct tagT_NET_SD_REC_FILE_INFOa
    {
        char path[256];           //目录名
        unsigned long long file_num;  //目录中文件的个数
    } T_NET_SD_REC_DIR_INFO, T_NET_SD_SNAP_DIR_INFO;
    
    
    typedef struct tagT_NET_CONFIG
    {
        E_NET_CONFIG_TYPE type;
        int res;
    } T_NET_CONFIG;
    
    typedef struct tagT_NET_VIDEO_INFO
    {
        int stream_type;   // 0 为主码流， 1为子码流
        int fps;           // 帧率
        int i_interval;    // I 帧间隔
        int brc_mode;      // 0: CBR 固定码率; 1: VBR 可变码率
        int cbr_avg_bps;   // 固定码率
        int vbr_min_bps;   // 可变码率下限
        int vbr_max_bps;   // 可变码率上限
        int width;         // 分辨率宽
        int height;        // 分辨率高
    } T_NET_VIDEO_INFO;
    
    typedef struct tagT_NET_IMAGE_INFO
    {
        int	    flipEnabled; //垂直 翻转
        int	    mirrorEnabled; // 水平 翻转
        
        int    brightness; /* 0 ~ 100 */
        int    saturation; /* 0 ~ 100  */
        int    contrast;   /* 0 ~ 100 */
        int    sharpness;  /* 0 ~ 100 */
        int    hue;        /* 0 ~ 100 */
    } T_NET_IMAGE_INFO;
    
    typedef struct tagT_NET_SYSTEM_INFO
    {
        int	  isTwoMainStream;
    } T_NET_SYSTEM_INFO;
    
    typedef struct tagT_NET_SERIAL_INFO
    {
        int nSpeed;   /* 波特率 */
        int nBits;    /* 数据位 */
        char nEvent;  /* 奇偶校验位 */
        int nStop;    /* 停止位 */
    } T_NET_SERIAL_INFO;
    
    typedef enum {
        NET_FRAME_TYPE_I = 0,
        NET_FRAME_TYPE_P = 1,
        NET_FRAME_TYPE_A = 2,
    } E_NET_FRAME_TYPE;
    
    typedef enum {
        NET_VIDEO_ENC_H264 = 0,
    } E_NET_VIDEO_ENC_TYPE;
    
    typedef struct {
        unsigned int    magic;
        unsigned int frame_no;
        unsigned int frame_size;//u
        unsigned short width;
        unsigned short height;
        E_NET_FRAME_TYPE frame_type;//U
        E_NET_VIDEO_ENC_TYPE venc_type;//U h264
        unsigned int frame_rate;
        unsigned int sec;//U
        unsigned int usec;//U
        unsigned int pts;
    } T_NET_FRAME_HEADER;
    
    
#define SERVER_TCP_LISTEN_PORT   0x7102
#define REC_LIMIT_SIZE (10)
    
    /* 以下是网络库模块化用到的 */
    
    // 报警类型
    typedef enum tagE_NET_ALARM_TYPE
    {
        NET_ALARM_TYPE_LOSE_VIDEO	= 100,	// 视频丢失
        NET_ALARM_TYPE_MOTION		= 101,	// 移动检测
        NET_ALARM_TYPE_SENSOR		= 102,	// 探头报警信号
    } E_NET_ALARM_TYPE;
    
    typedef enum {
        NET_PT_RL = 33,
        NET_PT_BUTT,
    } E_NET_PT_TYPE_E;
    
    // IP设备属性
    typedef struct
    {
        int		iChannelNum;		// 通道数量
        int		iAlarmInNum;		// 报警输入数量
        int		iAlarmOutNum;		// 报警输出数量
        int		bStorage;			// 是否支持存储
        int		bVoice;				// 是否支持对讲
        char	szSn[64];			// 设备序列号
    } T_DEV_ATTR;
    
    
    typedef struct tagT_NET_UTP_PTZ_CONTROL
    {
        unsigned int flag;      //fix: 0x12345678
        unsigned int seq;
        int sid;
        unsigned int size;
        unsigned char ptz_cmd[32];
    } T_NET_UTP_PTZ_CONTROL;

    
    
    typedef enum {
        UDP_DATA_UNINT = 0,
        UDP_DATA_SIMA_CTL_FLY = 0x12345678,
        UDP_DATA_SIMA_GPS,
        UDP_DATA_UDIRC,
    } UDP_DATA_TYPE;
    
    typedef struct NET_UTP_DATA__ {
        unsigned int type;
        unsigned int seq;
        unsigned int size;
        unsigned int  data_addr;
    } NET_UTP_DATA;
    
    
    //=======================================================
    // 网络服务提供的接口（我方提供给你调用的）
    //=======================================================
    typedef struct tagT_NET_CB_ENTRY
    {
        /**********************************************************************
         * 函数功能： 初始化，库加载的时候调用一次
         * 参数1:     (in)制造商ID，由我方提供(定值)
         * 参数2:     (in)设备型号
         * 参数3:     (in)设备云ID号,每个设备唯一(由我方提供)
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/
        int (*Initialize)(int iManuID, const char *szModel, const char *szCloudID);
        
        
        /**********************************************************************
         * 函数功能： 释放资源，在系统退出时调用
         * 返回值:    无
         **********************************************************************/
        int (*Cleanup)(void);
        
        
        /**********************************************************************
         * 函数功能： 报警消息
         * 参数1:     (in)报警类型
         * 参数2:     (in)第几路或是第几个端口报警，从0开始
         * 参数3:     (in)TRUE为报警，FALSE为报警解除
         * 返回值:    无
         **********************************************************************/
        int (*AlarmMsg)(E_NET_ALARM_TYPE eStyle, int iPort, int bAlarm);
        
        /**********************************************************************
         * 函数功能： 音视频数据
         * 参数1:     (in)通道编号，从0开始
         * 参数2:     (in)数据缓冲区指针
         * 参数3:     (in)数据长度
         * 参数4:     (in)帧类型
         * 参数5:     (in)码流类型
         * 返回值:    无
         **********************************************************************/
        int (*AVStreamData)(int iChannel,
                            unsigned char *pBuf,
                            int iBufLen,
                            T_NET_FRAME_HEADER *pFrameHead);
        
        /**********************************************************************
         * 函数功能： 对讲数据
         * 参数1:     (in)数据缓冲区指针
         * 参数2:     (in)数据长度
         * 返回值:    无
         **********************************************************************/
        int (*VoiceStreamData)(unsigned char *pBuf, int iBufLen);
        
        
        /**********************************************************************
         * 函数功能： 得到程序版本
         * 返回值:    得到版本信息，返回一个字符串，内存不需要释放
         **********************************************************************/
        int (*GetVersion)(char *ver, int size);
        
    }T_NET_CB_ENTRY;
    
    
    //=======================================================
    // IP设备提供的接口（你方提供给我调用的接口）
    //=======================================================
    typedef struct tagT_NET_FUNC_ENTRY
    {
        /**********************************************************************
         * 函数功能： 重启
         * 返回值:    无
         **********************************************************************/
        int (*UserLogin)(char *user, char *passwd);
        
        /**********************************************************************
         * 函数功能： 重启
         * 返回值:    无
         **********************************************************************/
        int (*Reboot)(void);
        
        /**********************************************************************
         * 函数功能： 得到设备属性
         * 参数1:     (OUT)设备属性指针
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/
        int (*GetDeviceAttr)(T_DEV_ATTR *ptDevAttr);
        
        /**********************************************************************
         * 函数功能： 发送云台命令
         * 参数1:     (in)通道编号，从0开始
         * 参数2:     (in)命令类型:PTZ_TURN_UP...PTZ_STOP_LINE_SCAN
         * 参数3:     (in)命令类型:在云台指令时,为TRUE或是FALSE,即开启或是停止;
         *							在球机指令时,为第一个预置点值;
         * 参数4:     (in)命令类型:在云台指令时,为云台速度
         * 参数5:     (in)命令类型:保留值
         * 返回值:    无
         **********************************************************************/
        int (*SendPTZCmd)(T_NET_PTZ_CONTROL *ptz_control);
        
        /**********************************************************************
         * 函数功能： 调整系统时间
         * 参数1:     (in)时间(时间为CST时间)
         * 返回值:    无
         **********************************************************************/
        int (*AdjustTime)(T_NET_DATE_TIME *ptTime);
        
        /**********************************************************************
         * 函数功能： 设备报警输出
         * 参数1:     (in)第几路，从0开始
         * 参数2:     (in)TRUE为打开，FALSE为关闭
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/
        int (*SetAlarmOut)(int iPort, int bValue);
        
        /**********************************************************************
         * 函数功能： 控制通道音视频数据
         * 参数1:     (in)通道编号，从0开始
         * 参数2:     (in)码流编号,
         * 参数3:     (in)TRUE为开启数据，FALSE为关闭数据
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/
        int (*ControlChannel)(int iChannel, int iStreamType, int bOpen);
        
        /**********************************************************************
         * 函数功能： 控制SD卡本地录像
         * 参数1:     (in)通道编号，从0开始
         * 参数2:     (in)码流编号,
         * 参数3:     (in)TRUE为开启数据，FALSE为关闭数据
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/	
        int (*ControlSdRec)(int iChannel, int iStreamType, int bOpen);
        
        /**********************************************************************
         * 函数功能： 强制产生I帧，打开通道以后有效
         * 参数1:     (in)通道编号，从0开始
         * 参数2:     (in)码流编号,
         * 返回值:    无
         **********************************************************************/
        int (*ForceIFrame)(int iChannel, int iStreamType);
        
        /**********************************************************************
         * 函数功能： 生成jpg快照
         * 参数1:     (in)通道编号，从0开始
         * 参数2:     (in)码流编号,
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/
        int (*SnapJpg)(int iChannel, int iStreamType);
        
        /**********************************************************************
         * 函数功能： 控制对讲数据
         * 参数1:     (in)TRUE为开启数据，设备自行打开音频输入输出，通过调用PlayVoiceData播放用户的声音数据
         *				 FALSE为关闭数据，设备自行关闭声音输入输出，关闭后，设备端不再调用VoiceStreamData
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/	
        int (*ControlVoice)(int bOpen);
        
        /**********************************************************************
         * 函数功能： 播放对讲
         * 参数1:     (in)压缩的数据缓冲区指针
         * 参数2:     (in)数据长度
         * 返回值:    无
         **********************************************************************/		
        int (*PlayVoiceData)(unsigned char *pBuf, int iBufLen);	
        
        /**********************************************************************
         * 函数功能： 设置参数与得到参数
         * 参数1:     (in)参数类型ID
         * 参数2:     (in)通道编号，不是通道相关的参数时，此值被忽略
         * 参数3:     (in)参数值结构指针
         * 返回值:    成功返回NET_SDK_OK，失败详见返回码
         **********************************************************************/
        int (*SetConfig)(E_NET_CONFIG_TYPE config_type, int res, void *value);
        int (*GetConfig)(E_NET_CONFIG_TYPE config_type, int res, void *value);
        
    }T_NET_FUNC_ENTRY;
    
    //=====================================================================
    // 外部接口
    //=====================================================================
    
    /**********************************************************************
     * 函数功能： 模块注册(非阻塞，立即返回)
     * 参数1:     (in)设备提供给NetSdk调用的api函数指针
     * 参数2:     (in)NetSdk提供给设备调用的api函数指针
     * 返回值:    无
     **********************************************************************/
    int Net_ModuleRegister(T_NET_FUNC_ENTRY *ptNetFunc, T_NET_CB_ENTRY *ptNetIpc);
    
    int Net_SendNoticeMsg(unsigned int sd_status);
    

#pragma pack(1)
    typedef struct
    {
        char name[8]; //"GPSOCKET"
        UInt16 nACK;  //0x0002 ACK   0003 NACK
        Byte nModeID;
        Byte nCmdID;
        UInt16 nLen;
    } T_GP_PACKET_HEADER;
#pragma pack()
    
    
    
#ifdef __cplusplus
}
#endif
#endif

