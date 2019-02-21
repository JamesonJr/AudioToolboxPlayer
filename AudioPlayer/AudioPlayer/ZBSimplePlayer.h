#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ZBSimplePlayer : NSObject <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>
+ (id) sharedPlayer;
- (double)framePerSecond;
- (void) stopPlaying;
- (void) startPlaying;
- (void) passNewURL: (NSURL *) newURL;
- (void) changeSong: (NSURL *) newSong;

@property (readonly, getter=isStopped) BOOL stopped;

@end
