//
//  MyDownLoad_GK.m
//  Wifi_Camera
//
//  Created by AivenLau on 16/5/23.
//  Copyright © 2016年 KLStudio. All rights reserved.
//

#import "MyDownLoad_GK.h"



@interface MyDownLoad_GK()


@property(copy,nonatomic) Progress Progress;
@property(copy,nonatomic) Sucess  Sucess;
@property(copy,nonatomic) Fail  Fail;


@property (nonatomic, strong) NSURLSession *session;
// 下载任务
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
// 续传的二进制数据
@property (nonatomic, strong) NSData *resumeData;

@property (nonatomic, assign) BOOL   bIsRunning;
@property (nonatomic, assign) NSInteger   nIndex;

@end

@implementation MyDownLoad_GK
#pragma mark  下载文件。。。。
- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        config.timeoutIntervalForRequest = 5000.0f;
        config.timeoutIntervalForResource = 5000.0f;
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    
    return _session;
}

-(void)dealloc
{
    [self Cancel];
}

-(void)Cancel
{
    
    [self.downloadTask cancel];
    self.downloadTask = nil;
}

// 暂停下载任务
- (IBAction)pause
{
    // 如果下载任务不存在，直接返回
    if (!self.downloadTask)
        return;
    // 暂停任务(块代码中的resumeData就是当前正在下载的二进制数据)
    // 停止下载任务时，需要保存数据
    [self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
        //self.resumeData = resumeData;
        _bIsRunning = NO;
        // 清空并且释放当前的下载任务
        self.downloadTask = nil;
    }];
}

- (IBAction)resume
{
    // 要续传的数据是否存在？
    if (!self.downloadTask)
        return;
    
    // 建立续传的下载任务
    self.downloadTask = [self.session downloadTaskWithResumeData:self.resumeData];
    [self.downloadTask resume];
    _bIsRunning = YES;
    // 将此前记录的续传数据清空
    self.resumeData = nil;
}

// 如果在开发中使用到缓存目录，一定要提供一个功能，“清除缓存”！
/** 下载文件 */
/*
- (void)downloadFile:(NSString *)urlStr ByIndex:(NSInteger)inx
{
    urlStr = [urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:urlStr];
    // (1) 代理 & 直接启动任
    // 2. 启动下载任务
    self.downloadTask = [self.session downloadTaskWithURL:url];
    [self.downloadTask resume];
    _bIsRunning = YES;
    _nIndex = inx;
}
*/

-(void)F_DownLoad:(NSString *)sPath   Sucess:(Sucess)sucess_  Progress:(Progress)Progress_  Fail:(Fail)Fail_
{
    self.Sucess = sucess_;
    self.Progress=Progress_;
    self.Fail=Fail_;
    
    sPath = [sPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:sPath];
    // (1) 代理 & 直接启动任
    // 2. 启动下载任务
    self.downloadTask = [self.session downloadTaskWithURL:url];
    [self.downloadTask resume];
    
}

#pragma mark - 下载代理方法

// 任务完成调用
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
        if(!error)
            return;
        else
        {
                if ([error code] == NSURLErrorCancelled)
                {
                    ;
                }
                else
                {
                    self.Fail();
                }
        }
}


- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSLog(@"完成 %@ %@", location, [NSThread currentThread]);
    NSFileManager *manager=[NSFileManager defaultManager];
    NSString *sTemp =[location absoluteString];
    sTemp = [sTemp substringFromIndex:7];
    NSString *filename = [sTemp lastPathComponent];
    NSArray *pathcaches=NSSearchPathForDirectoriesInDomains(NSCachesDirectory
                                                            , NSUserDomainMask
                                                            , YES);
    NSString* cacheDirectory  = [pathcaches objectAtIndex:0];
    NSString* cacheFile = [NSString stringWithFormat:@"%@/%@",cacheDirectory,filename];
    //NSURL *url = [NSURL URLWithString:cacheFile];
    if([manager fileExistsAtPath:cacheFile])
    {
        [manager removeItemAtPath:cacheFile error:nil];
    }
    NSError *error;
    if([manager moveItemAtPath:sTemp toPath:cacheFile error:&error])
    {
        self.Sucess(cacheFile);
    }
}

/**
 bytesWritten               : 本次下载的字节数
 totalBytesWritten          : 已经下载的字节数
 totalBytesExpectedToWrite  : 下载总大小
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
    int  nPorgress = (int)(progress*100);
    self.Progress(nPorgress);
}

/** 续传的代理方法 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"offset : %lld", fileOffset);
}

@end
