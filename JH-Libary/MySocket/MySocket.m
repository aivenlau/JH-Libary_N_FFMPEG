//
//  MySocket.m
//  JH_WifiCamera
//
//  Created by AivenLau on 2016/12/2.
//  Copyright © 2016年 joyhonest. All rights reserved.
//

#import "MySocket.h"
#import  "phone_rl_protocol.h"

@interface MySocket()


@property(assign,nonatomic)  BOOL bEnableReadThread;

@end

@implementation MySocket

-(id)init
{
    self = [super init];
    if(self)
    {
        self.socketfd = -1;
        self.bConnected = NO;
        
    }
    return self;
}


-(void)DisConnect
{
    if(self.socketfd>0)
    {
        self.bConnected = false;
        NSLog(@"Disconnected = %d",self.socketfd);
        shutdown(self.socketfd, 2);
        int re = close(self.socketfd);
        if(re!=0)
        {
            NSLog(@"Close socket error!!!!!!!! socket = %d",self.socketfd);
        }
        self.socketfd = -1;
        
    }

}


-(int)Connect:(NSString *)sHost  PORT:(int)port
{
    int re = [self ConnectA:sHost PORT:port];
    if(re !=0)
    {
        usleep(1000*50);
        return [self ConnectA:sHost PORT:port];
        //if(re !=0)
        //{
            //usleep(1000*200);
            //return  [self ConnectA:sHost PORT:port];
        //}
    }
    return 0;
}

-(int)ConnectA:(NSString *)sHost  PORT:(int)port
{
    NSLog(@"Connect start");
    struct sockaddr_in dest_addr; //destnation ip info
    if(self.socketfd>0)
    {
        return 0;
    }
    self.socketfd = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
    if(self.socketfd == -1) {
        self.bConnected = false;
        return -1;
    }
    int ret=0;
    unsigned long ul = 1;
    struct timeval timeout;
    fd_set  writeset;
    int error = -1, len = sizeof(int);
    
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(port);
    dest_addr.sin_addr.s_addr = inet_addr([sHost UTF8String]);
    
    
    int send_len = 50 * 1024;
    if( setsockopt(self.socketfd, SOL_SOCKET, SO_RCVBUF, (void*)&send_len, sizeof(int) ) < 0 ){
        self.bConnected = false;
    }
    
    ioctl(self.socketfd, FIONBIO, &ul);
    self.bConnected = false;
    if(-1 == connect(self.socketfd,(struct sockaddr*)&dest_addr,sizeof(struct sockaddr)))
    {
        timeout.tv_sec = 0;       //2Secs
        timeout.tv_usec = 1000*400;  //1.2
        FD_ZERO(&writeset);
        FD_SET(self.socketfd, &writeset);
        
        ret = select(self.socketfd + 1, NULL, &writeset, NULL, &timeout);
        if (ret == 0)              //返回0，代表在描述词状态改变已超过timeout时间
        {
            getsockopt(self.socketfd, SOL_SOCKET, SO_ERROR, &error, (socklen_t *) &len);
            if (error == 0)          // 超时，可以做更进一步的处理，如重试等
            {
              //  bTimeoutFlag = 1;
                NSLog(@"Not Connect timeout");
            }
            else {
                NSLog(@"Not Connect host error");
            }
        }
        else if (ret == -1)      // 返回-1， 有错误发生，错误原因存在于errno
        {
            NSLog(@"Not Connect host error1");
            
        }
        else {
            self.bConnected = true;
        }
    }
    else
    {
        self.bConnected = true;
    }
    
    
    ul = 0;
    ioctl(self.socketfd, FIONBIO, &ul); //重新将socket设置成阻塞模式
    
    int set = 1;
    setsockopt(self.socketfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
    
    // set nodelay
    int on = 1;
    setsockopt(self.socketfd, IPPROTO_TCP, TCP_NODELAY, (void *)&on, sizeof(on));
    
    
    if(self.bConnected) {
        NSLog(@"Connect host OK! fd = %d",self.socketfd);
        return 0;
    }
    else {
        NSLog(@"not connect!!!!! socket = %d",_socketfd);
        close(self.socketfd);
        self.socketfd = -1;
        self.bConnected = false;
        return -1;
    }
  
}


-(int)Write:(NSData *)data
{
    if(data.length==0)
        return -1;
    struct timeval timeoutA = {0,1000*10};     //10ms
    if(!self.bConnected)
        return -2;
    setsockopt(self.socketfd,SOL_SOCKET,SO_SNDTIMEO,(char *)&timeoutA,sizeof(struct timeval));
    ssize_t ret = send(self.socketfd,[data bytes],(size_t)data.length,0);
    if(ret!=data.length)
        return -3;
    return 0;
}




-(int)Read_B:(int )nLen  timeout:(int)timeout
{
    if(nLen<=0)
        return 0;
    if(_pBuffer==NULL)
        return 0;
    ssize_t nRet;
    //NSData *dat;
    uint  nStep = timeout;
    
    uint8_t *buffer =  _pBuffer;
    uint8_t *bufferA=buffer;
    uint64_t  nStart=(uint64_t) ([[NSDate  date] timeIntervalSince1970]*1000);
    int nCount = 0;
    
    //fd_set   set;
    
    while(nLen>0 && self.bConnected)
    {
        struct timeval timeoutA = {0,1000*10};     //10ms
        setsockopt(self.socketfd,SOL_SOCKET,SO_RCVTIMEO,(char *)&timeoutA,sizeof(struct timeval));
        nRet = recv(self.socketfd,bufferA,nLen,0);
        if(nRet>0)
        {
            nLen-=nRet;
            bufferA+=nRet;
            nCount+=nRet;
        }
        else
        {
            int errs = errno;
            if (errs == EWOULDBLOCK)
            {
                ;
            }
            usleep(2000);
        }
        if(timeout>0)
        {
            uint64_t  nEnd=(uint64_t) ([[NSDate  date] timeIntervalSince1970]*1000);
            if(nEnd-nStart>nStep)
            {
                break;
            }
        }
    }
    return nCount;
    
    /*
    if(nCount>0)
        dat = [NSData dataWithBytes:buffer length:nCount];
    else
        dat = nil;
    if(buffer!=NULL)
        free(buffer);
    return dat;
     */

}



-(NSData *)Read:(int )nLen  timeout:(int)timeout
{
    if(nLen<=0)
        return nil;
    ssize_t nRet;
    NSData *dat;
    uint  nStep = timeout;
    
    uint8_t *buffer =  malloc(nLen);
    uint8_t *bufferA=buffer;
    uint64_t  nStart=(uint64_t) ([[NSDate  date] timeIntervalSince1970]*1000);
    int nCount = 0;
    while(nLen>0 && self.bConnected)
    {
        struct timeval timeoutA = {0,1000*10};     //10ms
        setsockopt(self.socketfd,SOL_SOCKET,SO_RCVTIMEO,(char *)&timeoutA,sizeof(struct timeval));
        nRet = recv(self.socketfd,bufferA,nLen,0);
        if(nRet>0)
        {
            nLen-=nRet;
            bufferA+=nRet;
            nCount+=nRet;
        }
        else
        {
            int errs = errno;
            if (errs == EWOULDBLOCK)
            {
                ;
            }
            usleep(500);
        }
        if(timeout>0)
        {
            uint64_t  nEnd=(uint64_t) ([[NSDate  date] timeIntervalSince1970]*1000);
            if(nEnd-nStart>nStep)
            {
                break;
            }
        }
    }
    
    if(nCount>0)
        dat = [NSData dataWithBytes:buffer length:nCount];
    else
        dat = nil;
    if(buffer!=NULL)
        free(buffer);
    return dat;
   
}

-(NSData *)ReadA:(int )nLen
{
    return [self Read:nLen timeout:200];
}






-(NSData *)Read:(int )nLen
{
    return [self Read:nLen timeout:50];
}

#define Bufferlen 128

-(void)ReadData
{
    int nRet;
    uint8_t  buffer[Bufferlen];
    SEL sel = @selector (SocketRecv: socket:);
    int nError;
    //int send_len = 64 * 1024;
    //setsockopt(self.socketfd, SOL_SOCKET, SO_RCVBUF, (void*)&send_len, sizeof(int) );
    while(self.bConnected)
    {
        struct timeval timeoutA = {0,1000*20};     //20ms
        setsockopt(self.socketfd,SOL_SOCKET,SO_RCVTIMEO,(char *)&timeoutA,sizeof(struct timeval));
        nRet = (int)recv(self.socketfd,buffer,Bufferlen,0);
        if(nRet<0)
        {
            nError = errno;
            if(nError == EWOULDBLOCK || nError== EAGAIN )
            {
                
            }
        }
        else if(nRet>0)
        {
            NSData *dat  = [NSData dataWithBytes:buffer length:nRet];
            if(self.delegate)
            {
                if([self.delegate respondsToSelector:sel])
                {
                    [self.delegate SocketRecv:dat socket:self];
                }
            }
            dat = nil;
        }
        else
        {
            break;
        }
    }
}


-(void)ReadData_GP
{
    SEL sel = @selector (SocketRecv: socket:);
    bool  bHeader=true;
    NSData *dat_Header;
    NSData *dat = nil;
    T_GP_PACKET_HEADER header;
    while(self.bConnected && self.bEnableReadThread)
    {
        if(bHeader)
        {
            dat_Header = [self Read:sizeof(T_GP_PACKET_HEADER) timeout:500];
            [dat_Header getBytes:&header length:sizeof(T_GP_PACKET_HEADER)];
        }
        else
        {
            if(header.nLen>0)
                dat = [self Read:header.nLen timeout:500];
        }
        bHeader =!bHeader;
        if(bHeader)
        {
            NSMutableData  *revDat = [NSMutableData dataWithData:dat_Header];
            if(dat)
                [revDat appendData:dat];
            if(self.delegate)
            {
                if([self.delegate respondsToSelector:sel])
                {
                    [self.delegate SocketRecv:revDat socket:self];
                }
            }
        }
    }
}



-(void)ReadData:(int)pack_len
{
    //uint8_t  buffer[Bufferlen];
    uint8_t *buffer = malloc(pack_len);
    SEL sel = @selector (SocketRecv: socket:);
    bool  bHeader=true;
    NSData *dat_Header;
    NSData *dat;
    T_NET_DL_PACKET_HEADER header;
    
    while(self.bConnected)
    {
        if(bHeader)
        {
            dat_Header = [self Read:sizeof(T_NET_DL_PACKET_HEADER) timeout:1500];
            [dat_Header getBytes:&header length:sizeof(T_NET_DL_PACKET_HEADER)];
        }
        else
            dat = [self Read:header.size timeout:1500];
        bHeader =!bHeader;
        if(bHeader)
        {
            NSMutableData  *revDat = [NSMutableData dataWithData:dat_Header];
            [revDat appendData:dat];
            if(self.delegate)
            {
                    if([self.delegate respondsToSelector:sel])
                    {
                        [self.delegate SocketRecv:revDat socket:self];
                    }
            }
        }
    }
    free(buffer);
    
}


-(void)ReadData_A:(int)pack_len
{
    //uint8_t  buffer[Bufferlen];
    uint8_t *buffer = malloc(pack_len);
    SEL sel = @selector (SocketRecv: socket:);
    
    
    while(self.bConnected)
    {
        NSData *dat = [self Read:pack_len timeout:200];
        if(dat)
        {
    
            if(self.delegate)
            {
                if([self.delegate respondsToSelector:sel])
                {
                    [self.delegate SocketRecv:dat socket:self];
                }
            }
        }
    }
    free(buffer);
    
}

-(void)StopReadThread_GP
{
    self.bEnableReadThread = NO;
    usleep(1000*550);
}

-(void)StartReadThread_GP
{
    __weak MySocket *weakself =self;
    self.bEnableReadThread = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [weakself ReadData];
    });
}




-(void)StartReadThread
{
    __weak MySocket *weakself =self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [weakself ReadData];
    });
}

-(void)StartReadThread:(int)pack_len
{
    __weak MySocket *weakself =self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [weakself ReadData:pack_len];
    });
}

-(void)StartReadThread_A:(int)pack_len
{
    __weak MySocket *weakself =self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [weakself ReadData_A:pack_len];
    });
}



-(BOOL)SocketIsConnected
{
    if(_socketfd<0)
        return NO;
    
    unsigned long ul = 1;
    ioctl(self.socketfd, FIONBIO, &ul);
    
    int res,recvlen;
    char buf[20] = {'\0'};
    struct timeval timeout={0,1000*50};
    fd_set rdfs;
    FD_ZERO(&rdfs);
    FD_SET(_socketfd,&rdfs);
    
    res = select(_socketfd+1,&rdfs,NULL,NULL,&timeout);
    BOOL  re=NO;
    
    if(res > 0){
        
        recvlen =(int) recv(_socketfd,buf,sizeof(buf),0);
        if(recvlen > 0){
            printf("socket connected\n");
            re =  YES;
        } else if (recvlen < 0 ){
            if(errno == EINTR){
                printf("socket connected\n");
                re =  YES;
            }else {
                printf("socket disconnected! connect again!\n");
                re =  NO;
            }
        } else if (recvlen == 0){
            printf("socket disconnected!connect again\n");
            re =  NO;
        }
    } else if(res == 0 ){
        //time out
        printf("socket connected\n");
        re = YES;
    } else if(res < 0){
        if (errno == EINTR){
            printf("socket connected\n");
            re = YES;
        }else{
            printf("socket disconnected ! connect again!\n");
            re =  NO;
        }
    }
    ul=0;
    ioctl(self.socketfd, FIONBIO, &ul);
    return re;
}
@end

















