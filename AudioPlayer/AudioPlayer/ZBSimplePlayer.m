#import "ZBSimplePlayer.h"

static void ZBAudioFileStreamPropertyListener(void * inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 * ioFlags);
static void ZBAudioFileStreamPacketsCallback(void * inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription *inPacketDescriptions);
static void ZBAudioQueueOutputCallback(void * inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inBuffer);
static void ZBAudioQueueRunningListener(void * inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID);

typedef struct {
	size_t length;
	void *data;
} ZBPacketData;

@implementation ZBSimplePlayer
{
    NSURLSessionDataTask *dataTask;
	struct {
		BOOL stopped;
		BOOL loaded;
	} playerStatus ;

	AudioFileStreamID audioFileStreamID;
	AudioQueueRef outputQueue;

	AudioStreamBasicDescription streamDescription;
	ZBPacketData *packetData;
	size_t packetCount;
	size_t maxPacketCount;
	size_t readHead;
}

- (void)dealloc
{
	AudioQueueReset(outputQueue);
	AudioQueueDispose(outputQueue, true);
	AudioFileStreamClose(audioFileStreamID);

	for (size_t index = 0 ; index < packetCount ; index++) {
		void *data = packetData[index].data;
		if (data) {
			free(data);
			packetData[index].data = nil;
			packetData[index].length = 0;
		}
	}
    
	free(packetData);
}

+ (id) sharedPlayer {
    static ZBSimplePlayer* sharedPlayer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPlayer = [[self alloc] init];
    });
    return sharedPlayer;
}

- (id)init {
    if (self = [super init]) {
        playerStatus.stopped = NO;
        packetCount = 0;
        maxPacketCount = 20480;
        packetData = (ZBPacketData *)calloc(maxPacketCount, sizeof(ZBPacketData));
    }
    return self;
}

- (double)framePerSecond
{
	if (streamDescription.mFramesPerPacket) {
		return streamDescription.mSampleRate / streamDescription.mFramesPerPacket;
	}

	return 44100.0/1152.0;
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    if (data) {
        OSStatus *result = AudioFileStreamParseBytes(audioFileStreamID, (UInt32)[data length], [data bytes], 0);
    }
    
}



- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"didCompleteWithError");
    if (error) {
        playerStatus.stopped = YES;
    } else {
        playerStatus.loaded = YES;
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    if ([response isKindOfClass: [NSHTTPURLResponse class]]) {
        if ([(NSHTTPURLResponse *) response statusCode] != 200) {
            NSLog(@"HTTP code:%ld", [(NSHTTPURLResponse *)response statusCode]);
        }
    }
    completionHandler(NSURLSessionResponseAllow);
}

#pragma mark - Audio Parser and Audio Queue callbacks

- (void)_enqueueDataWithPacketsCount:(size_t)inPacketCount
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
	if (!outputQueue) {
		return;
	}

	if (readHead == packetCount) {
		if (playerStatus.loaded) {
			AudioQueueStop(outputQueue, false);
			playerStatus.stopped = YES;
			return;
		}
	}

	if (readHead + inPacketCount >= packetCount) {
		inPacketCount = packetCount - readHead;
	}

	UInt32 totalSize = 0;
	UInt32 index;

	for (index = 0 ; index < inPacketCount ; index++) {
		totalSize += packetData[index + (UInt32)readHead].length;
	}

	OSStatus status = 0;
	AudioQueueBufferRef buffer;
	status = AudioQueueAllocateBuffer(outputQueue, totalSize, &buffer);
	assert(status == noErr);
	buffer->mAudioDataByteSize = totalSize;
    buffer->mUserData = (__bridge void * _Nullable)(self);

	AudioStreamPacketDescription *packetDescs = calloc(inPacketCount, sizeof(AudioStreamPacketDescription));

	totalSize = 0;
	for (index = 0 ; index < inPacketCount ; index++) {
		size_t readIndex = index + readHead;
		memcpy(buffer->mAudioData + totalSize, packetData[readIndex].data, packetData[readIndex].length);
		AudioStreamPacketDescription description;
		description.mStartOffset = totalSize;
		description.mDataByteSize = (UInt32)packetData[readIndex].length;
		description.mVariableFramesInPacket = 0;
		totalSize += packetData[readIndex].length;
		memcpy(&(packetDescs[index]), &description, sizeof(AudioStreamPacketDescription));
	}
	status = AudioQueueEnqueueBuffer(outputQueue, buffer, (UInt32)inPacketCount, packetDescs);
	free(packetDescs);
	readHead += inPacketCount;
}

- (void)_createAudioQueueWithAudioStreamDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription
{
	memcpy(&streamDescription, audioStreamBasicDescription, sizeof(AudioStreamBasicDescription));
    OSStatus status = AudioQueueNewOutput(audioStreamBasicDescription, ZBAudioQueueOutputCallback, (__bridge void * _Nullable)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &outputQueue);
	assert(status == noErr);

	UInt32 trueValue = 1;
	AudioQueueSetProperty(outputQueue, kAudioQueueProperty_EnableTimePitch, &trueValue, sizeof(trueValue));
	UInt32 timePitchAlgorithm = kAudioQueueTimePitchAlgorithm_Spectral;
	AudioQueueSetProperty(outputQueue, kAudioQueueProperty_TimePitchAlgorithm, &timePitchAlgorithm, sizeof(timePitchAlgorithm));
	status = AudioQueueSetParameter(outputQueue, kAudioQueueParam_Pitch, 0.0);

    status = AudioQueueAddPropertyListener(outputQueue, kAudioQueueProperty_IsRunning, ZBAudioQueueRunningListener, (__bridge void * _Nullable)(self));
	AudioQueuePrime(outputQueue, 0, NULL);
	AudioQueueStart(outputQueue, NULL);
}

- (void)_storePacketsWithNumberOfBytes: (UInt32)inNumberBytes numberOfPackets:(UInt32)inNumberPackets inputData:(const void *)inInputData packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions
{
	for (int i = 0; i < inNumberPackets; ++i) {
		SInt64 packetStart = inPacketDescriptions[i].mStartOffset;
		UInt32 packetSize = inPacketDescriptions[i].mDataByteSize;
        assert(packetSize > 0);
		packetData[packetCount].length = (size_t)packetSize;
		packetData[packetCount].data = malloc(packetSize);
		memcpy(packetData[packetCount].data, inInputData + packetStart, packetSize);
		packetCount++;
	}

	if (readHead == 0 & packetCount > (int)([self framePerSecond] * 3)) {
		AudioQueueStart(outputQueue, NULL);
		[self _enqueueDataWithPacketsCount: (int)([self framePerSecond] * 2)];
        
	}
}

- (void)_audioQueueDidStart
{
	NSLog(@"Audio Queue did start");
}

- (void)_audioQueueDidStop
{
	NSLog(@"Audio Queue did stop");
	playerStatus.stopped = YES;
}

#pragma mark - Properties

- (BOOL)isStopped
{
	return playerStatus.stopped;
}

- (void) stopPlaying {
    AudioQueueStop(outputQueue, YES);
    AudioQueueReset(outputQueue);
    AudioQueueDispose(outputQueue, true);
    AudioFileStreamClose(audioFileStreamID);
    for (size_t index = 0 ; index < packetCount ; index++) {
        void *data = packetData[index].data;
        if (data) {
            free(data);
            packetData[index].data = nil;
            packetData[index].length = 0;
        }
    }
    
    free(packetData);
}

- (void) startPlaying {
//    AudioQueueStart(outputQueue, 0);
}

- (void) passNewURL: (NSURL *) newURL {
    AudioFileStreamOpen((__bridge void * _Nullable)(self), ZBAudioFileStreamPropertyListener, ZBAudioFileStreamPacketsCallback, kAudioFileM4AType, &audioFileStreamID);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: newURL
                                                  cachePolicy: NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval: 10.0];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration: sessionConfiguration
                                                          delegate: self
                                                     delegateQueue: [NSOperationQueue mainQueue]];
    dataTask = [session dataTaskWithRequest: request];
    [dataTask resume];
}

- (void) changeSong: (NSURL *) newSong {
    AudioQueueStop(outputQueue, YES);
    AudioQueueReset(outputQueue);
    AudioQueueDispose(outputQueue, true);
    outputQueue = nil;
    AudioFileStreamClose(audioFileStreamID);
    audioFileStreamID = nil;
//    for (size_t index = 0 ; index < packetCount ; index++) {
//        void *data = packetData[index].data;
//        if (data) {
//            free(data);
//            packetData[index].data = nil;
//            packetData[index].length = 0;
//        }
//    }
//
//    free(packetData);
//
//    playerStatus.stopped = NO;
//    packetCount = 0;
//    maxPacketCount = 20480;
//    packetData = (ZBPacketData *)calloc(maxPacketCount, sizeof(ZBPacketData));
    
    AudioFileStreamOpen((__bridge void * _Nullable)(self), ZBAudioFileStreamPropertyListener, ZBAudioFileStreamPacketsCallback, kAudioFileM4AType, &audioFileStreamID);
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL: newSong
                                                  cachePolicy: NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval: 10.0];
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration: sessionConfiguration
                                                          delegate: self
                                                     delegateQueue: [NSOperationQueue mainQueue]];
    dataTask = [session dataTaskWithRequest: request];
    [dataTask resume];
}

@end

void ZBAudioFileStreamPropertyListener(void * inClientData, AudioFileStreamID inAudioFileStream, AudioFileStreamPropertyID inPropertyID, UInt32 * ioFlags)
{
    ZBSimplePlayer *self = (__bridge ZBSimplePlayer *)inClientData;
	if (inPropertyID == kAudioFileStreamProperty_DataFormat) {
		UInt32 dataSize	 = 0;
		OSStatus status = 0;
		AudioStreamBasicDescription audioStreamDescription;
		Boolean writable = false;
		status = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &dataSize, &writable);
		status = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &dataSize, &audioStreamDescription);
        
		[self _createAudioQueueWithAudioStreamDescription:&audioStreamDescription];
	}
}

void ZBAudioFileStreamPacketsCallback(void * inClientData, UInt32 inNumberBytes, UInt32 inNumberPackets, const void * inInputData, AudioStreamPacketDescription *inPacketDescriptions)
{
    ZBSimplePlayer *self = (__bridge ZBSimplePlayer *)inClientData;
	[self _storePacketsWithNumberOfBytes:inNumberBytes numberOfPackets:inNumberPackets inputData:inInputData packetDescriptions:inPacketDescriptions];
}

static void ZBAudioQueueOutputCallback(void * inUserData, AudioQueueRef inAQ,AudioQueueBufferRef inBuffer)
{
	AudioQueueFreeBuffer(inAQ, inBuffer);
    ZBSimplePlayer *self = (__bridge ZBSimplePlayer *)inUserData;
	[self _enqueueDataWithPacketsCount:(int)([self framePerSecond] * 5)];
}

static void ZBAudioQueueRunningListener(void * inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
    ZBSimplePlayer *self = (__bridge ZBSimplePlayer *)inUserData;
	UInt32 dataSize;
	OSStatus status = 0;
	status = AudioQueueGetPropertySize(inAQ, inID, &dataSize);
	if (inID == kAudioQueueProperty_IsRunning) {
		UInt32 running;
		status = AudioQueueGetProperty(inAQ, inID, &running, &dataSize);
		running ? [self _audioQueueDidStart] : [self _audioQueueDidStop];
	}
}
