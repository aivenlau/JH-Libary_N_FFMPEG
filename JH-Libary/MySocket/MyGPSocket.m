//
//  MyGPSocket.m
//  JH_Libary
//
//  Created by AivenLau on 2017/5/6.
//  Copyright © 2017年 AivenLau. All rights reserved.
//

#import "MyGPSocket.h"

@interface MyGPSocket() //<GCDAsyncSocketDelegate>
{
    
}


@property(strong,nonatomic) NSData   *startcodeData;

//@property(strong,nonatomic) GCDAsyncSocket   *gp_cmdSocket;
@property(assign,nonatomic) BOOL              bConnected;

@end

#define   TAG_READ_DATA     0x100


@implementation MyGPSocket

-(id)init
{
    self = [super init];
    if(self)
    {
       // dispatch_queue_t myQueue = dispatch_queue_create("JOYHONEST-WIFI_GP", DISPATCH_QUEUE_PRIORITY_DEFAULT);
       // self.gp_cmdSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:myQueue socketQueue:nil];
        unsigned char startcode[] = {'G','P','S','O','C','K','E','T'};
        self.startcodeData = [NSData dataWithBytes:startcode length:8];
    }
    return self;
}

#if 0
//建连成功
- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host  port:(UInt16)port
{
    NSLog(@"Connected!");
    self.bConnected = YES;
    //[self.gp_cmdSocket readDataToData:self.startcodeData withTimeout:-1 tag:TAG_READ_DATA];
  //  [self.gp_cmdSocket readDataWithTimeout:2000 tag:TAG_READ_DATA];
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
    cmd[12] = (Byte)0;
    NSData *data = [[NSData alloc] initWithBytes:cmd length:13];
    [self.gp_cmdSocket writeData:data withTimeout:100 tag:TAG_READ_DATA];
    
    
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
    
    data = [[NSData alloc] initWithBytes:cmd length:12];
    [self.gp_cmdSocket writeData:data withTimeout:100 tag:TAG_READ_DATA];
    
    
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
    cmd[12] = (Byte)0;
    data = [[NSData alloc] initWithBytes:cmd length:13];
    [self.gp_cmdSocket writeData:data withTimeout:100 tag:TAG_READ_DATA+1];
    
    
}
//断开建连
- (void)socketDidDisconnect:(GCDAsyncSocket*)sock withError:(NSError*)err
{
    self.bConnected = NO;
}

//读到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    if(tag == TAG_READ_DATA)
    {
        //Byte *dat = (Byte *)[data bytes];
        [self.gp_cmdSocket readDataToData:self.startcodeData withTimeout:-1 tag:TAG_READ_DATA];
    }
    if(tag == TAG_READ_DATA+1)
    {
        //Byte *dat = (Byte *)[data bytes];
        [self.gp_cmdSocket readDataToData:self.startcodeData withTimeout:-1 tag:TAG_READ_DATA+1];
    }
}


//发送OK
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tagg
{
    
}


-(int)F_GP_Connect
{
    NSError *error;
    if([self.gp_cmdSocket connectToHost:@"192.168.25.1" onPort:8081 error:&error])
    {
        return 0;
    }
    else
    {
        return -1;
    }
}

-(void)F_StartRead
{
    [self.gp_cmdSocket readDataToData:self.startcodeData withTimeout:-1 tag:TAG_READ_DATA];
}
#endif

-(int)F_GP_Connect
{
    return -1;
}

@end
