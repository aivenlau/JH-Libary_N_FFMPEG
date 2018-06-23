

#import "MyDownLoad_a.h"
#import "phone_rl_protocol.h"
//@interface MyDownLoad_a()<GCDAsyncSocketDelegate>
@interface MyDownLoad_a() //<GCDAsyncSocketDelegate>
{
    
}

@property(strong,nonatomic)NSString  *sPath;
//@property(strong,nonatomic)GCDAsyncSocket  *Socket;
@property(strong,nonatomic)MySocket  *Socket;
@property(copy,nonatomic) Progress Progress;
@property(copy,nonatomic) Sucess  Sucess;
@property(copy,nonatomic) Fail  Fail;
@property(assign,nonatomic) int nType;
@property(assign,nonatomic) uint64_t nStarttime;
@property(strong,nonatomic) NSString *tempfileA;
@property(strong,nonatomic) NSOutputStream *outStream;

@property(assign,nonatomic) BOOL bDowning;
@property(assign,nonatomic) UInt16  nDowning;

@property(assign,nonatomic) int   nTp;


@property(assign,nonatomic) BOOL   bCancel;



@end

@implementation MyDownLoad_a

#define   PackLenA   (1024*256)

-(id)init
{
    self = [super init];
    if(self)
    {
        _bCancel = NO;
        //dispatch_queue_t myQueue = dispatch_queue_create("JOYHONEST-WIFI-Download", DISPATCH_QUEUE_PRIORITY_DEFAULT);
        //_Socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:myQueue socketQueue:nil];
        _Socket =[[MySocket alloc] init];
        _session_id = -1;
        
    }
    return self;
}

-(void)F_CheckDownloading
{
    
    __weak  MyDownLoad_a  *weakself = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
         weakself.nTp=0;
        while(weakself.bDowning)
        {
            if(weakself.nTp>=10)   //250ms
            {
                if(weakself.nDowning!=0xFFFF)
                    weakself.nDowning++;
                if(weakself.nDowning>15)
                {
                    [weakself disconnect];
                    if(weakself.outStream)
                        [weakself.outStream close];
                    if(weakself.Fail)
                    {
                        self.Fail();
                    }
                }
                weakself.nTp = 0;
            }
            usleep(1000*25);
            weakself.nTp++;
        }
    });
}



-(void)F_DownLoad:(NSString *)sPath   Sucess:(Sucess)sucess_  Progress:(Progress)Progress_  Fail:(Fail)Fail_
{
    
    NSFileManager *FileManager = [NSFileManager defaultManager];
   // NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString  *sDoc;// = [paths objectAtIndex:0];
    
    self.bDowning = YES;
    //0xFFFFFFFF
    NSString  *ext = [sPath pathExtension];
    ext = [ext lowercaseString];
    if([ext isEqualToString:@"avi"]  && [ext isEqualToString:@"mov"])
    {
        sDoc = self.VideosFloder;
    }
    else
    {
        sDoc = self.PhotosFloder;
    }


    NSString  *sName = [sPath lastPathComponent];
    NSString *sSaveName1 = [sDoc stringByAppendingPathComponent:sName];
  //  unsigned long red = 0;
    
    if([FileManager fileExistsAtPath:sSaveName1]) //文件已经下载
    {
      //  NSDictionary * attributes = [FileManager attributesOfItemAtPath:sSaveName1 error:nil];
       // NSNumber *theFileSize;
       // theFileSize = [attributes objectForKey:NSFileSize];
        //red =  (uint32_t)[theFileSize unsignedLongLongValue];
      //  attributes = nil;
    }
    FileManager= nil;
  //  paths = nil;
    sDoc = nil;
    sSaveName1 = nil;
    
    
    
    
    
    NSString *temp = NSTemporaryDirectory();
    NSUUID *downloadID = [NSUUID UUID];
    NSString *tempfilea = [downloadID UUIDString];
    ext=[sPath pathExtension];
    ext =  [ext lowercaseString];
    
    if([ext isEqualToString:@"avi"]  && [ext isEqualToString:@"mov"])
    {
        self.nType = DL_REC_FILE;
    }
    else
    {
        self.nType = DL_SNAP_FILE;
    }
    
    
    self.tempfileA = [NSString stringWithFormat:@"%@%@.%@",temp,tempfilea,ext];
    
    self.outStream =[NSOutputStream outputStreamToFileAtPath:self.tempfileA append:NO];
    [self.outStream open];
    
    
    self.Sucess = sucess_;
    self.Progress = Progress_;
    self.Fail = Fail_;
    
    if(self.outStream==nil)
    {
        self.bDowning = NO;
        [self.outStream close];
        [self disconnect];
        self.Fail();
        return;
    }
    if(self.session_id <0)
    {
        self.bDowning = NO;
        [self.outStream close];
        [self disconnect];
        self.Fail();
        return;
    }
    self.sPath = sPath;
    //NSError *error;
    self.bDowning = YES;
    self.nDowning = 0;
    
    if([_Socket Connect:GK_ServerIP PORT:GK_Port]<0)
    {
        self.bDowning = NO;
        [self.outStream close];
        self.Fail();
    }
    
    
    const char *sPathA = [self.sPath UTF8String];
    T_REQ_MSG msg;
    T_NET_CMD_MSG Cmd;
    T_NET_DOWNLOAD_CONTROL downCtrol;
    Cmd.session_id = self.session_id;
    Cmd.type = CMD_DOWNLOAD_SOCK;
    downCtrol.dl_type =  self.nType;
    downCtrol.one_packet_size = PackLenA;
    memset(downCtrol.name,0,256);
    memcpy(downCtrol.name,(const void *)sPathA,strlen(sPathA));
    NSMutableData  *sendData = [NSMutableData dataWithBytes:&Cmd length:sizeof(T_NET_CMD_MSG)];
    NSData *data =  [NSData dataWithBytes:&downCtrol length:sizeof(T_NET_DOWNLOAD_CONTROL)];
    [sendData appendData:data];
    [_Socket Write:sendData];
    //[self F_CheckDownloading];
    data = [_Socket Read:sizeof(T_REQ_MSG) timeout:5000];
    if(!data)
    {
        self.bDowning = NO;
        [self.outStream close];
        [_Socket DisConnect];
        self.Fail();
        return;
    }
    if(_bCancel)
    {
        self.bDowning = NO;
        [self.outStream close];
        [_Socket DisConnect];
        return;
    }
    memcpy(&msg, [data bytes], sizeof(T_REQ_MSG));
    if(msg.ret != 0)
    {
        self.bDowning = NO;
        [self.outStream close];
        [_Socket DisConnect];
        self.Fail();
        return;
    }
    
    //[sock readDataToLength:sizeof(T_NET_DL_PACKET_HEADER) withTimeout:-1 tag:Tag_DownLoadHead];
    
    self.file_all_size=-1;
    while(!_bCancel)
    {
        data = [_Socket Read:sizeof(T_NET_DL_PACKET_HEADER) timeout:2500];
        if(data && data.length == sizeof(T_NET_DL_PACKET_HEADER))
        {
            if(_bCancel)
            {
                self.bDowning = NO;
                [self.outStream close];
                [self.Socket DisConnect];
                self.outStream = nil;
                return;
            }
            
            T_NET_DL_PACKET_HEADER  header;
            [data getBytes:&header length:sizeof(T_NET_DL_PACKET_HEADER)];
            if(self.file_all_size<0)
            {
                self.file_all_size = header.file_all_size;
                /*
                if(self.file_all_size ==red)
                {
                    self.bDowning = NO;
                    [self.outStream close];
                    [_Socket DisConnect];
                    self.Sucess(@"FileExists");
                    return;
                }
                 */
            }
            data = [_Socket Read:header.size timeout:10000];
            if(data && data.length == header.size)
            {
                if(_bCancel)
                {
                    self.bDowning = NO;
                    [self.outStream close];
                    [self.Socket DisConnect];
                    self.outStream = nil;
                    return;
                }
                
                
                self.nSize+=(UInt64)data.length;
                NSLog(@"total read size %llu FileSize=%lld",self.nSize,self.file_all_size);
                
                NSUInteger dataLength = [data length];
                const uint8_t * dataBytes  = [data bytes];
                NSInteger       bytesWritten;
                NSInteger       bytesWrittenSoFar;
                
                bytesWrittenSoFar = 0;
                
                do {
                    bytesWritten = [self.outStream write:&(dataBytes[bytesWrittenSoFar]) maxLength:dataLength - bytesWrittenSoFar];
                    if(bytesWritten == -1) {
                        self.bDowning = NO;
                        [self.outStream close];
                        [_Socket DisConnect];
                        self.Fail();
                        return;
                    }
                    else
                    {
                        bytesWrittenSoFar += bytesWritten;
                    }
                } while (bytesWrittenSoFar != dataLength);
                
                
                if(data.length<PackLenA || self.nSize>=self.file_all_size)
                {
                    self.bDowning = NO;
                    [self.outStream close];
                    [_Socket DisConnect];
                    self.outStream = nil;
                    if(_bCancel)
                    {
                        return;
                    }
                    self.Sucess(self.tempfileA);
                    self.Progress(100);
                    return;
                }
                
                if(self.file_all_size !=0)
                {
                    NSInteger pre =(NSInteger)((self.nSize*100.0f)/self.file_all_size);
                    if(pre >100)
                    {
                        //pre = 100;
                        self.bDowning = NO;
                        [self.outStream close];
                        [self.Socket DisConnect];
                        self.outStream = nil;
                        if(_bCancel)
                        {
                            return;
                        }
                        self.Sucess(self.tempfileA);
                        self.Progress(100);
                        return;
                    }
                    
                    if(_bCancel)
                    {
                        self.bDowning = NO;
                        [self.outStream close];
                        [self.Socket DisConnect];
                        self.outStream = nil;
                        return;
                    }
                    self.Progress(pre);
                }
            }
        }
        else
        {
            self.bDowning = NO;
            [self.outStream close];
            [self.Socket DisConnect];
            self.outStream = nil;
            if(!_bCancel)
            {
                self.Fail();
            }
            return;
        }
    }
   

}
-(void)CancelDown
{
}

-(void)disconnect
{
    _bCancel = YES;
    [self.Socket DisConnect];
}

-(void)dealloc
{
    [self disconnect];
}


@end
