//
//  PlayerController.h
//  AudioPlayer
//
//  Created by Eugenie Tyan on 12/21/18.
//  Copyright © 2018 Eugenie Tyan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "ZBSimplePlayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface PlayerController : NSObject

@property (strong, nonatomic) AVAudioPlayer *player;


- (void) playMusicWithURL: (NSURL *) url;
- (void) stop;
@end

NS_ASSUME_NONNULL_END
