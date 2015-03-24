//
//  ViewController.m
//  OldMovie
//
//  Created by TCH on 15/3/21.
//  Copyright (c) 2015年 com.rcplatform. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "IS_ShareVideoViewController.h"
#import "EditViewController.h"

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate,SCRecorderDelegate>
{
    UIImagePickerController *videoPicker;
    
    SCRecorder *_recorder;
    SCRecordSession *_recordSession;
}
@property (weak, nonatomic) IBOutlet UITextField *text1;
@property (weak, nonatomic) IBOutlet UITextField *text2;
@property (weak, nonatomic) IBOutlet UITextField *text3;
@property (weak, nonatomic) IBOutlet UITextField *text4;
@property (weak, nonatomic) IBOutlet UITextField *text5;
@property (weak, nonatomic) IBOutlet UITextField *text6;
@property (weak, nonatomic) IBOutlet UITextField *text7;
@property (weak, nonatomic) IBOutlet UITextField *text8;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    videoPicker = [[UIImagePickerController alloc] init];
    videoPicker.delegate = self;
    videoPicker.allowsEditing = YES;
    videoPicker.videoMaximumDuration = 15.0f;
    videoPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    videoPicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeMovie, nil];
    videoPicker.videoQuality = UIImagePickerControllerQualityTypeHigh;
    
    _recorder = [SCRecorder recorder];
    _recorder.sessionPreset = [SCRecorderTools bestSessionPresetCompatibleWithAllDevices];
    _recorder.maxRecordDuration = CMTimeMake(60, 1);
    
    _recorder.delegate = self;
    _recorder.autoSetVideoOrientation = YES;

}

- (IBAction)startProject:(id)sender {
    [self presentViewController:videoPicker animated:YES completion:nil];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if (picker == videoPicker) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectory = [paths objectAtIndex:0];
        NSString *filePathTemp1 = [documentDirectory stringByAppendingPathComponent:@"/videoTemp2/"];
        if (![fileMgr fileExistsAtPath:filePathTemp1]) {
            
            [fileMgr createDirectoryAtPath:filePathTemp1 withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSMutableString *s = [NSMutableString stringWithFormat:@"%@/%@%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/videoTemp2/"],@"tempVideo",@".mp4"];
        if ([fileMgr fileExistsAtPath:s])
        {
            [fileMgr removeItemAtPath:s error:nil];
        }
        NSData  *myData = [[NSData  alloc] initWithContentsOfURL:info[UIImagePickerControllerMediaURL]];
        BOOL success = [myData writeToFile:s atomically:YES];
        
        if(success)
        {
            NSURL *sourceMovieURL = [NSURL fileURLWithPath:s];
            AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
            CGSize videoSize = [[[movieAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
            NSLog(@"%f,%f",videoSize.width,videoSize.height);
            AVAssetTrack *clipVideoTrack = [[movieAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
            CGAffineTransform videoTransform = clipVideoTrack.preferredTransform;
            BOOL isVideoAssetPortrait_ = NO;
            if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
                isVideoAssetPortrait_ = YES;
            }
            if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
                
                isVideoAssetPortrait_ = YES;
            }
            if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
                isVideoAssetPortrait_  = NO;
            }
            if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
                isVideoAssetPortrait_  = NO;
            }
            float height,width;
            if (isVideoAssetPortrait_)
            {
                height = videoSize.width;
                width = videoSize.height;
            }
            else
            {
                height = videoSize.height;
                width = videoSize.width;
            }
            
            float rate = width/height;
            [picker dismissViewControllerAnimated:YES completion:nil];
            [self changeVideo:sourceMovieURL toSize:CGSizeMake(640, 360)];
//            if (rate >= 1)//横屏
//            {
//                if(height>640)
//                {
//                    [picker dismissViewControllerAnimated:YES completion:nil];
//                    [self changeVideo:sourceMovieURL toSize:CGSizeMake(640*rate, 640)];
//                }
//                else
//                {
//                    __weak ViewController *weakSelf = self;
//                    if (success) {
//                        [picker dismissViewControllerAnimated:YES completion:^{
//                            [weakSelf performSelectorOnMainThread:@selector(presentEditView:) withObject:s waitUntilDone:NO];
//                        }];
//                    }
//                }
//            }
//            else//竖屏
//            {
//                if(width>640)
//                {
//                    [picker dismissViewControllerAnimated:YES completion:nil];
//                    [self changeVideo:sourceMovieURL toSize:CGSizeMake(640, 640.0/rate)];
//                }
//                else
//                {
//                    __weak ViewController *weakSelf = self;
//                    if (success) {
//                        [picker dismissViewControllerAnimated:YES completion:^{
//                            [weakSelf performSelectorOnMainThread:@selector(presentEditView:) withObject:s waitUntilDone:NO];
//                        }];
//                    }
//                }
//            }
        }
        else
        {
            [picker dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

-(void)changeVideo:(NSURL *)url toSize:(CGSize)size
{
    AVMutableComposition* composition = [AVMutableComposition composition];
    
    AVURLAsset* firstAsset = [[AVURLAsset alloc]initWithURL:url options:nil];
    float fps=0.00;
    AVAssetTrack * videoATrack = [[firstAsset tracksWithMediaType:AVMediaTypeVideo] lastObject];
    if(videoATrack)
    {
        fps = videoATrack.nominalFrameRate;
    }
    
    AVMutableCompositionTrack *firstTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    if ([[firstAsset tracksWithMediaType:AVMediaTypeAudio] count]>0) {
        AVMutableCompositionTrack *firstAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [firstAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
    }
    
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
    [transformer setTransform:videoATrack.preferredTransform atTime:kCMTimeZero];
    
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    if (fps>0) {
        videoComposition.frameDuration = CMTimeMake(1, fps);
    }
    else
    {
        videoComposition.frameDuration = CMTimeMake(1, 30);
    }
    NSLog(@"%lld,%d",firstAsset.duration.value,firstAsset.duration.timescale);
    videoComposition.renderSize = size;
    videoComposition.renderScale = 1.0;
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPreset640x480] ;
    //    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    
    NSMutableString *s = [NSMutableString stringWithFormat:@"%@/%@%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"],@"finishedVideoaaa",@".mp4"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:s])
        [[NSFileManager defaultManager] removeItemAtPath:s error:nil];
    exporter.outputURL=[NSURL fileURLWithPath:s];
    //    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    exporter.outputFileType=AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    //    exporter.fileLengthLimit = 10*1024*1024;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, [firstAsset duration]);
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        
        if (AVAssetExportSessionStatusCompleted == exporter.status) {
            [self performSelectorOnMainThread:@selector(success:) withObject:s waitUntilDone:NO];
        } else if (AVAssetExportSessionStatusFailed == exporter.status) {
            NSLog(@"%@",exporter.error);
        } else {
            NSLog(@"Export Session Status: %ld", (long)exporter.status);
        }
    }];
    NSLog(@"Retain count is %ld", CFGetRetainCount((__bridge CFTypeRef)self));
}

-(void)success:(NSString *)filePath
{
    NSMutableString *toPath = [NSMutableString stringWithFormat:@"%@/%@%@",[NSHomeDirectory() stringByAppendingPathComponent:@"Documents/"],@"tempVideo",@".mp4"];
    [self addFeature2WithMoviePath:filePath CompletionPath:toPath];
}

-(void)addFeature2WithMoviePath:(NSString *)filePath CompletionPath:(NSString *)toPath
{
    NSMutableArray *layerInstructionArray = [[NSMutableArray alloc]init];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:toPath])
    {
        [fileMgr removeItemAtPath:toPath error:nil];
    }
    
    if (filePath) {
        NSString* outputFilePath = toPath;
        NSURL*    outputFileUrl = [NSURL fileURLWithPath:outputFilePath];
        
        CMTime time = kCMTimeZero;
        AVMutableComposition* mixComposition = [AVMutableComposition composition];
        AVURLAsset *asset;
        CGSize naturalSize;
        
        
        NSURL *videoinputFileURL = [NSURL fileURLWithPath:filePath];
        asset = [[AVURLAsset alloc]initWithURL:videoinputFileURL options:nil];
        NSLog(@"%lld,%d",asset.duration.value,asset.duration.timescale);
        AVMutableCompositionTrack *track = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:time error:nil];
        naturalSize = track.naturalSize;
        if ([[asset tracksWithMediaType:AVMediaTypeAudio] count]>0) {
            AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:[[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:time error:nil];
        }
        
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:track];
        [layerInstructionArray addObject:layerInstruction];
        time = CMTimeAdd(time, asset.duration);
        
        
        AVMutableVideoCompositionInstruction *MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, time);
        MainInstruction.layerInstructions = layerInstructionArray;
        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
        mainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        mainCompositionInst.frameDuration = CMTimeMake(1, 30);
        mainCompositionInst.renderSize = CGSizeMake(640, 360);
        
        
        CALayer *backgroundLayer = [CALayer layer];
        //        [backgroundLayer setContents:(id)[[UIImage imageNamed:@"square-003.jpg"] CGImage]];
//        backgroundLayer.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"square-003.jpg"]].CGColor;
        backgroundLayer.backgroundColor = [UIColor blackColor].CGColor;
        backgroundLayer.frame = CGRectMake(0, 0, 640, 360);
        [backgroundLayer setMasksToBounds:YES];
        
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0.0f, 0.0f, 640.f, 360);
        videoLayer.frame = CGRectMake(0, 40, 640, 280);
        [parentLayer addSublayer:backgroundLayer];
        [parentLayer addSublayer:videoLayer];
        
        CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
        [subtitle1Text setFont:@"Helvetica-Bold"];
        [subtitle1Text setFontSize:15];
        [subtitle1Text setFrame:CGRectMake(0, 40, 640, 40)];
//        [subtitle1Text setBackgroundColor:[UIColor blueColor].CGColor];
        [subtitle1Text setString:[NSString stringWithFormat:@"%@\n%@",_text1.text,_text2.text ]];
        [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
        [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
        subtitle1Text.shadowColor=[UIColor redColor].CGColor;
        subtitle1Text.shadowOffset= CGSizeMake(1, 1);
        [parentLayer addSublayer:subtitle1Text];
        
        CATextLayer *subtitle2Text = [[CATextLayer alloc] init];
        [subtitle2Text setFont:@"Helvetica-Bold"];
        [subtitle2Text setFontSize:15];
        [subtitle2Text setFrame:CGRectMake(0, 40, 640, 40)];
        //        [subtitle1Text setBackgroundColor:[UIColor blueColor].CGColor];
        [subtitle2Text setString:[NSString stringWithFormat:@"%@\n%@",_text3.text,_text4.text ]];
        [subtitle2Text setAlignmentMode:kCAAlignmentCenter];
        [subtitle2Text setForegroundColor:[[UIColor whiteColor] CGColor]];
        [parentLayer addSublayer:subtitle2Text];
        
        CATextLayer *subtitle3Text = [[CATextLayer alloc] init];
        [subtitle3Text setFont:@"Helvetica-Bold"];
        [subtitle3Text setFontSize:15];
        [subtitle3Text setFrame:CGRectMake(0, 40, 640, 40)];
        //        [subtitle1Text setBackgroundColor:[UIColor blueColor].CGColor];
        [subtitle3Text setString:[NSString stringWithFormat:@"%@\n%@",_text5.text,_text6.text ]];
        [subtitle3Text setAlignmentMode:kCAAlignmentCenter];
        [subtitle3Text setForegroundColor:[[UIColor whiteColor] CGColor]];
        [parentLayer addSublayer:subtitle3Text];
        
        CATextLayer *subtitle4Text = [[CATextLayer alloc] init];
        [subtitle4Text setFont:@"Helvetica-Bold"];
        [subtitle4Text setFontSize:15];
        [subtitle4Text setFrame:CGRectMake(0, 40, 640, 40)];
        //        [subtitle1Text setBackgroundColor:[UIColor blueColor].CGColor];
        [subtitle4Text setString:[NSString stringWithFormat:@"%@\n%@",_text7.text,_text8.text ]];
        [subtitle4Text setAlignmentMode:kCAAlignmentCenter];
        [subtitle4Text setForegroundColor:[[UIColor whiteColor] CGColor]];
        [parentLayer addSublayer:subtitle4Text];
        
        CAAnimation *animation1 = [self createAnimationWithStartTime:AVCoreAnimationBeginTimeAtZero Duration:2];
        CAAnimation *animation2 = [self createAnimationWithStartTime:3 Duration:2];
        CAAnimation *animation3 = [self createAnimationWithStartTime:6 Duration:2];
        CAAnimation *animation4 = [self createAnimationWithStartTime:9 Duration:2];
        
        [subtitle1Text addAnimation:animation1 forKey:@"opacity"];
        [subtitle2Text addAnimation:animation2 forKey:@"opacity"];
        [subtitle3Text addAnimation:animation3 forKey:@"opacity"];
        [subtitle4Text addAnimation:animation4 forKey:@"opacity"];
        
        mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
        
        //合成后的新视频
        AVAssetExportSession *assetExportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
        assetExportSession.outputURL = outputFileUrl;
        assetExportSession.outputFileType = AVFileTypeQuickTimeMovie;
        assetExportSession.videoComposition = mainCompositionInst;
        assetExportSession.shouldOptimizeForNetworkUse = YES;
        
        [assetExportSession exportAsynchronouslyWithCompletionHandler:
         ^(void ) {
             if (AVAssetExportSessionStatusCompleted == assetExportSession.status) {
                 NSLog(@"AVAssetExportSessionStatusCompleted");
                 [self performSelectorOnMainThread:@selector(presentEditView:) withObject:toPath waitUntilDone:NO];
             } else if (AVAssetExportSessionStatusFailed == assetExportSession.status) {
                 NSLog(@"AVAssetExportSessionStatusFailed %@",assetExportSession.error);
             } else {
                 NSLog(@"Export Session Status: %d", (int)assetExportSession.status);
             }
             //             if (isFinal) {
             //                 [self performSelectorOnMainThread:@selector(updateView) withObject:nil waitUntilDone:NO];
             //             }
         }];
    }
    else
    {
        //        if (isFinal) {
        //            [self performSelectorOnMainThread:@selector(updateView) withObject:nil waitUntilDone:NO];
        //        }
    }
    
}

-(CAAnimation *)createAnimationWithStartTime:(double)beginTime Duration:(float)duration
{
    CABasicAnimation *animationIn =
    [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationIn.duration=0.01;
    animationIn.repeatCount=1;
    animationIn.autoreverses=NO;
    animationIn.fromValue=[NSNumber numberWithFloat:0];
    animationIn.toValue=[NSNumber numberWithFloat:1];
    animationIn.beginTime = AVCoreAnimationBeginTimeAtZero;
    
    CABasicAnimation *animationOut =
    [CABasicAnimation animationWithKeyPath:@"opacity"];
    animationOut.duration=0.01;
    animationOut.repeatCount=1;
    animationOut.autoreverses=NO;
    animationOut.fromValue=[NSNumber numberWithFloat:1];
    animationOut.toValue=[NSNumber numberWithFloat:0];
    animationOut.beginTime = duration-0.01;
    
    
    CAAnimationGroup *animationGroup   = [CAAnimationGroup animation];
    animationGroup.beginTime = beginTime;
    animationGroup.duration = duration;
    animationGroup.repeatCount = 1;
    animationGroup.animations = [NSArray arrayWithObjects:animationIn,
                                 animationOut,nil];
    animationGroup.removedOnCompletion = NO;
    animationGroup.fillMode = kCAFillModeBoth;
    return animationGroup;
}

-(void)presentEditView:(NSString *)filePath
{
    NSURL *url = [NSURL fileURLWithPath:filePath];
    [_recorder.recordSession addSegment:url];
    _recordSession = [SCRecordSession recordSession];
    [_recordSession addSegment:url];

    EditViewController *editVideoViewController = [[EditViewController alloc]initWithEditFilePath:filePath];
    editVideoViewController.recordSession = _recordSession;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:editVideoViewController];
    [self presentViewController:nav animated:YES completion:nil];
//    IS_ShareVideoViewController *editVideoViewController = [[IS_ShareVideoViewController alloc]initWithShareVideoPath:filePath];
//    [self presentViewController:editVideoViewController animated:YES completion:nil];
}

- (void)recorder:(SCRecorder *)recorder didSkipVideoSampleBuffer:(SCRecordSession *)recordSession {
    //    NSLog(@"Skipped video buffer");
}

- (void)recorder:(SCRecorder *)recorder didReconfigureAudioInput:(NSError *)audioInputError {
    NSLog(@"Reconfigured audio input: %@", audioInputError);
}

- (void)recorder:(SCRecorder *)recorder didReconfigureVideoInput:(NSError *)videoInputError {
    NSLog(@"Reconfigured video input: %@", videoInputError);
}

//-(void)presentEditView:(NSString *)filePath
//{
//    IS_ShareVideoViewController *editVideoViewController = [[IS_ShareVideoViewController alloc]initWithShareVideoPath:filePath];
//    [self presentViewController:editVideoViewController animated:YES completion:nil];
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
