//
//  IS_ShareVideoViewController.m
//  InstaShot
//
//  Created by TCH on 14-8-7.
//  Copyright (c) 2014年 com.rcplatformhk. All rights reserved.
//

#import "IS_ShareVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "IS_ShareVideoViewController.h"

@interface IS_ShareVideoViewController ()
{
    int playState; //播放状态 0 暂停 1 播放
}
@property (nonatomic, strong) NSString *shareVideoPath;

@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic, strong) UIButton *playOrPauseBtn;

@end

@implementation IS_ShareVideoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithShareVideoPath:(NSString *)path
{
    self = [super init];
    if (self) {
        self.shareVideoPath = path;
    }
    return self;
}

- (void)pressBack
{
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    if(playState == 1)
    {
        [self.avPlayer pause];
        playState = 0;
        [_playOrPauseBtn setTitle:@"继续" forState:UIControlStateNormal];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor greenColor];
    
    UIButton *btnReturn = [[UIButton alloc]init];
    [btnReturn setTitle:@"返回" forState:UIControlStateNormal];
    [btnReturn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btnReturn addTarget:self action:@selector(pressBack) forControlEvents:UIControlEventTouchUpInside];
    [btnReturn setFrame:CGRectMake(0, 0, 50, 44)];
    [self.view addSubview:btnReturn];
    
    
    NSURL *sourceMovieURL = [NSURL fileURLWithPath:self.shareVideoPath];
    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
    self.avPlayer = player;
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    playerLayer.backgroundColor = [UIColor clearColor].CGColor;
    playerLayer.frame = CGRectMake(0, 90, 320, 320);
    playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:playerLayer];
    
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playOrPauseBtn setTitle:@"开始" forState:UIControlStateNormal];
    [_playOrPauseBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_playOrPauseBtn setFrame:CGRectMake(50, CGRectGetMaxY(playerLayer.frame), 50, 50)];
    [_playOrPauseBtn addTarget:self action:@selector(pressPlayOrPause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playOrPauseBtn];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playToEndTime) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
//    UIButton *btnSave = [[UIButton alloc]init];
//    [btnSave setTitle:@"保存" forState:UIControlStateNormal];
//    [btnSave setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
//    [btnSave addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
//    [btnSave setFrame:CGRectMake(-3, 0, 50, 44)];
//    UIBarButtonItem *itemSave = [[UIBarButtonItem alloc]initWithCustomView:btnSave];
//    self.navigationItem.leftBarButtonItem = itemSave;
    
}

-(void)playToEndTime
{
    playState = 2;
    [_playOrPauseBtn setTitle:@"开始" forState:UIControlStateNormal];
}

-(void)pressPlayOrPause
{
    if (playState == 0) {
        [self.avPlayer play];
        playState = 1;
        [_playOrPauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }
    else if(playState == 1)
    {
        [self.avPlayer pause];
        playState = 0;
        [_playOrPauseBtn setTitle:@"继续" forState:UIControlStateNormal];
    }
    else
    {
        [self.avPlayer seekToTime:kCMTimeZero];
        [self.avPlayer play];
        playState = 1;
        [_playOrPauseBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
