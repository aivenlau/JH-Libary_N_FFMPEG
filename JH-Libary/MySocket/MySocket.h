//
//  MySocket.h
//  JH_WifiCamera
//
//  Created by AivenLau on 2016/12/2.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <TargetConditionals.h>
#import <arpa/inet.h>
#import <fcntl.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <netinet/in.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>
#import <sys/ioctl.h>
#import <sys/poll.h>
#import <sys/uio.h>
#import <sys/un.h>
#import <netinet/tcp.h>
#import <unistd.h>



@class MySocket;





@protocol MySocket_Delegate<NSObject>
@optional
-(void)SocketRecv:(NSData *)data socket:(MySocket *)socket;
@end


@interface MySocket : NSObject
{
    
    
}
@property(assign,nonatomic)  int socketfd;
@property(assign,nonatomic)  Byte *pBuffer;
@property(weak,nonatomic)  id<MySocket_Delegate> delegate;
@property(assign,nonatomic)  BOOL bConnected;
@property(assign,nonatomic)  int nID;

-(int)Connect:(NSString *)sHost  PORT:(int)port;
-(void)DisConnect;
-(int)Write:(NSData *)data;
-(NSData *)Read:(int )nLen;
-(NSData *)ReadA:(int )nLen;
-(NSData *)Read:(int )nLen  timeout:(int)timeout;
-(int)Read_B:(int )nLen  timeout:(int)timeout;
-(void)StartReadThread_GP;
-(void)StopReadThread_GP;
-(void)StartReadThread;
-(void)StartReadThread:(int)pack_len;
-(void)StartReadThread_A:(int)pack_len;



@end
