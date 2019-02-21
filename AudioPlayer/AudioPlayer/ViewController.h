//
//  ViewController.h
//  AudioPlayer
//
//  Created by Eugenie Tyan on 11/14/18.
//  Copyright © 2018 Eugenie Tyan. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "ZBSimplePlayer.h"


#pragma mark - Need for AudioQueue
#include <stdlib.h>
#include <math.h>

#include <AudioToolbox/AudioQueue.h>
#include <CoreAudio/CoreAudioTypes.h>
#include <CoreFoundation/CFRunLoop.h>

#define NUM_CHANNELS 2
#define NUM_BUFFERS 3
#define BUFFER_SIZE 4096
#define MAX_NUMBER 32767
#define SAMPLE_RATE 44100



@interface ViewController : NSViewController

@property (strong, nonatomic) AVAudioPlayer *player;

@end

