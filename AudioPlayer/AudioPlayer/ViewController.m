//
//  ViewController.m
//  AudioPlayer
//
//  Created by Eugenie Tyan on 11/14/18.
//  Copyright © 2018 Eugenie Tyan. All rights reserved.
//

#import "ViewController.h"
#import "PlayerController.h"

@implementation ViewController {
    NSURL *YTURL;
    NSURL *secondURL;
    NSMutableArray *songs;
    PlayerController *playerController;
}

@synthesize player;


- (void)viewDidLoad {
    [super viewDidLoad];
    songs = [[NSMutableArray alloc] init];
    playerController = [[PlayerController alloc] init];
    
    NSString *videoIdentifier = @"g3vTDeMULTI"; // A 11 characters YouTube video identifier
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier: videoIdentifier completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
            NSString *XCDYouTubeVideoQualityAudioString = [NSString stringWithFormat: @"%@", video.streamURLs[@18]];
            
//            NSURL *soundFileURL = [NSURL fileURLWithPath: XCDYouTubeVideoQualityAudioString];
            NSURL *soundFileURL = [NSURL URLWithString: XCDYouTubeVideoQualityAudioString];
            self->YTURL = soundFileURL;
            NSLog (@"%@", self->YTURL);
        }
        else
        {
            // Handle error
            NSLog(@"error getting video from youtube");
        }
    }];
    
    NSString *second = @"d33n5lJpP_I"; // A 11 characters YouTube video identifier
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier: second completionHandler:^(XCDYouTubeVideo *video, NSError *error) {
        if (video)
        {
            NSString *XCDYouTubeVideoQualityAudioString = [NSString stringWithFormat: @"%@", video.streamURLs[@18]];
            
            //            NSURL *soundFileURL = [NSURL fileURLWithPath: XCDYouTubeVideoQualityAudioString];
            NSURL *soundFileURL = [NSURL URLWithString: XCDYouTubeVideoQualityAudioString];
            self->secondURL = soundFileURL;
            NSLog (@"%@", self->secondURL);
        }
        else
        {
            // Handle error
            NSLog(@"error getting video from youtube");
        }
    }];
    


    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (IBAction)buttonPlayPressed:(id)sender {
//    ZBSimplePlayer *player1 = [[ZBSimplePlayer alloc] init];
//    if ([songs count] > 0) {
//        for (int i = 0; i < [songs count]; i++) {
//            [songs[i] stopPlaying];
//        }
//        [songs removeAllObjects];
//    }
//
//    if ([songs count] == 0) {
//        [songs addObject: player1];
//        [songs[0] passNewURL: YTURL];
//    }
    NSString *path = @"/Users/eugenietyan/Desktop/123.mp3";
    NSURL *url = [NSURL fileURLWithPath: path];
    [playerController playMusicWithURL: YTURL];
//    [playerController playMusicWithURL: [NSURL URLWithString: path]];
}


- (IBAction)buttonPausePressed:(id)sender {
//    if ([songs count] > 0) {
//        for (int i = 0; i < [songs count]; i++) {
//            [songs[i] stopPlaying];
//        }
//        [songs removeAllObjects];
//    }
    [playerController stop];
//    [player stop];
}

- (IBAction)secondSong:(id)sender {
//    ZBSimplePlayer *player1 = [[ZBSimplePlayer alloc] init];
//    if ([songs count] > 0) {
//        for (int i = 0; i < [songs count]; i++) {
//            [songs[i] stopPlaying];
//        }
//        [songs removeAllObjects];
//    }
//    if ([songs count] == 0) {
//        [songs addObject: player1];
//        [songs[0] passNewURL: secondURL];
//    }
    [playerController playMusicWithURL: secondURL];
}

@end
