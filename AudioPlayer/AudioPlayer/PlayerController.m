//
//  PlayerController.m
//  AudioPlayer
//
//  Created by Eugenie Tyan on 12/21/18.
//  Copyright © 2018 Eugenie Tyan. All rights reserved.
//

#import "PlayerController.h"


@implementation PlayerController {
    NSMutableArray *songs;
    BOOL isFile;
}

@synthesize player;

- (void) playMusicWithURL: (NSURL *) url {
    if (!songs) {
        songs = [[NSMutableArray alloc] init];
    }
    if ([url isFileURL]) {
        [self stop];
        player = [[AVAudioPlayer alloc] initWithContentsOfURL: url error: nil];
        player.numberOfLoops = -1;
        [player prepareToPlay];
        [player play];
        isFile = TRUE;
    } else {
        ZBSimplePlayer *player1 = [[ZBSimplePlayer alloc] init];
        [self stop];
        
        if ([songs count] == 0) {
            [songs addObject: player1];
            [songs[0] passNewURL: url];
        }
        isFile = FALSE;
    }
    
    
}

- (void) stop {
    
    if (isFile) {
        [player stop];
    } else {
        if ([songs count] > 0) {
            for (int i = 0; i < [songs count]; i++) {
                [songs[i] stopPlaying];
            }
            [songs removeAllObjects];
        }
    }
}

@end
