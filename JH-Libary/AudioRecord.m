//
//  AudioRecord.m
//  JH_Libary
//
//  Created by AivenLau on 2018/6/6.
//  Copyright © 2018年 AivenLau. All rights reserved.
//

#import "AudioRecord.h"

@implementation AudioRecord

+(AudioRecord *)shareAudioRecord{
    static AudioRecord *sharedAccountManagerInstance = nil;
    
    static dispatch_once_t predicate; dispatch_once(&predicate, ^{
        sharedAccountManagerInstance = [[self alloc] init];
    });
    return sharedAccountManagerInstance;
}
/**
 *  设置录制的音频文件的位置
 *
 *  @return return value description
 */
- (NSString *)audioRecordingPath{
    
    NSString *result = nil;
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsFolde = [folders objectAtIndex:0];
    result = [documentsFolde stringByAppendingPathComponent:@"Recording.aac"];
    return (result);
    
}

/**
 *  在初始化AVAudioRecord实例之前，需要进行基本的录音设置
 *
 *  @return return value description
 */
- (NSDictionary *)audioRecordingSettings{
    
    NSDictionary *settings = [[NSDictionary alloc] initWithObjectsAndKeys:
                              
                              [NSNumber numberWithFloat:44100.0],AVSampleRateKey ,    //采样率 8000/44100/96000
                              
                              [NSNumber numberWithInt:kAudioFormatMPEG4AAC],AVFormatIDKey,  //录音格式
                              
                              [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,   //线性采样位数  8、16、24、32
                              
                              [NSNumber numberWithInt:1],AVNumberOfChannelsKey,      //声道 1，2
                              
                              [NSNumber numberWithInt:AVAudioQualityLow],AVEncoderAudioQualityKey, //录音质量
                              
                              nil];
    return (settings);
}

/**
 *  停止音频的录制
 *
 *  @param recorder recorder description
 */
- (void)stopRecordingOnAudioRecorder:(AVAudioRecorder *)recorder{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];  //此处需要恢复设置回放标志，否则会导致其它播放声音也会变小
    [session setActive:YES error:nil];
    [recorder stop];
}

/**
 *  @param recorder recorder description
 *  @param flag     flag description
 */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    
    
    if (flag == YES) {
        NSLog(@"录音完成！");
        NSError *playbackError = nil;
        NSError *readingError = nil;
        NSData *fileData = [NSData dataWithContentsOfFile:[self audioRecordingPath] options:NSDataReadingMapped error:&readingError];
        
        AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithData:fileData
                                                                 error:&playbackError];
        
        self.audioPlayer = newPlayer;
        
        if (self.audioPlayer != nil) {
            self.audioPlayer.delegate = self;
            if ([self.audioPlayer prepareToPlay] == YES &&
                [self.audioPlayer play] == YES) {
                NSLog(@"开始播放音频！");
            } else {
                NSLog(@"不能播放音频！");
            }
        }else {
            NSLog(@"播放失败！");
        }
        
    } else {
        NSLog(@"录音过程意外终止！");
    }
    self.audioRecorder = nil;
}


/**
 *  初始化音频检查
 */
-(void)initRecordSession
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [session setActive:YES error:nil];
    
}

/**
 *  开始录音
 */
- (void)onStatrRecord
{
    
    
    if (![self canRecord])
    {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:[NSString stringWithFormat:@"The application needs to access microphone. Please turn on the microphone"]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    [self initRecordSession];
    
    NSError *error = nil;
    NSString *pathOfRecordingFile = [self audioRecordingPath];
    NSURL *audioRecordingUrl = [NSURL fileURLWithPath:pathOfRecordingFile];
    AVAudioRecorder *newRecorder = [[AVAudioRecorder alloc]
                                    initWithURL:audioRecordingUrl
                                    settings:[self audioRecordingSettings]
                                    error:&error];
    self.audioRecorder = newRecorder;
    if (self.audioRecorder != nil) {
        self.audioRecorder.delegate = self;
        if([self.audioRecorder prepareToRecord] == NO){
            return;
        }
        
        if ([self.audioRecorder record] == YES) {
            
            NSLog(@"录音开始！");
            [self performSelector:@selector(stopRecordingOnAudioRecorder:)
                       withObject:self.audioRecorder
                       afterDelay:10.0f];
            
        } else {
            NSLog(@"录音失败！");
            self.audioRecorder =nil;
        }
    } else {
        NSLog(@"auioRecorder实例录音器失败！");
    }
}

/**
 *  停止录音
 */
- (void)stopRecord{
    
    if (self.audioRecorder != nil) {
        if ([self.audioRecorder isRecording] == YES) {
            [self.audioRecorder stop];
        }
        self.audioRecorder = nil;
    }
    
    if (self.audioPlayer != nil) {
        if ([self.audioPlayer isPlaying] == YES) {
            [self.audioPlayer stop];
        }
        self.audioPlayer = nil;
    }
}


/**
 *  将要录音
 *
 *  @return return value description
 */
- (BOOL)canRecord
{
    __block BOOL bCanRecord = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending)
    {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        
        
        
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted)
                {
                    bCanRecord = YES;
                    NSError *error;
                    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
                    
                } else {
                    
                    bCanRecord = NO;
                    
                }
                
            }];
            
        }
    }
    return bCanRecord;
}

@end
