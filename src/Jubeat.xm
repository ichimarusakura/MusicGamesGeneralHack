#import <CommonCrypto/CommonCrypto.h>
#import <objc/runtime.h>
#import <substrate.h>

extern NSString *DocumentsDirectory();
extern NSString *LibraryDirectory();

@interface BFCodec : NSObject

- (void)dealloc;
- (BOOL)decipher:(id)arg1;
- (unsigned int)encipher:(id)arg1;
- (void)cipherInit:(id)arg1;
- (void)cipherInit:(const char *)arg1 keyLength:(int)arg2;
- (id)init;

@end

%group Jubeat

%hook PurchaseManager

- (BOOL)isPurchased:(id)arg1 {
    return YES;
}

%end

%hook ChallengeStatus

+ (id)sharedStatus {
    id ret = %orig;
    MSHookIvar<int>(ret, "_coinNum") = 1;
    MSHookIvar<int>(ret, "_jCubeNum") = 1;
    MSHookIvar<int>(ret, "_nailNum") = 1;
    return ret;
}

- (double)getMusicEnableTime:(int)arg1 {
    return 99999.9;
}

%end

%end

static void SaveMulist(NSString *OutFileName, NSString *InputFileName) {
    NSString *SavePath = [DocumentsDirectory() stringByAppendingString:OutFileName];
    NSString *musicListKey =
        [[[objc_getClass("JubeatAppDelegate") alloc] init] performSelector:@selector(musicListKey)];
    NSMutableData *data = [NSMutableData dataWithBytes:"\x41\x53\x48\x55" length:4];

    NSLog(@"mulist Key:%@", musicListKey);
    if (musicListKey == nil) {
        NSLog(@"musicListKey is NIL");
        return;
    }
    BFCodec *BFC = [[objc_getClass("BFCodec") alloc] init];

    InputFileName = [DocumentsDirectory() stringByAppendingString:InputFileName];
    NSLog(@"InputFileName:%@", InputFileName);
    if (![[NSFileManager defaultManager] fileExistsAtPath:InputFileName]) {
        NSLog(@"-----SaveMulist-----\nFile  Doesn't Exist");
        return;
    }
    NSData *YoSwag = [NSData dataWithContentsOfFile:InputFileName];
    [data appendData:YoSwag];
    NSLog(@"Prefixed Data Size:%lu", (unsigned long)data.length);
    [YoSwag release];
    const char *MK = [musicListKey UTF8String];
    int r5 = strlen(MK);
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5, MK, r5);
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSData *s = [NSData dataWithBytes:digest length:0x10];
    NSLog(@"Actual BFCodec Key:%@", s);

    [BFC cipherInit:s];
    [BFC encipher:data];
    [data writeToFile:SavePath atomically:YES];

    [data release];
    [SavePath release];
    [s release];
    [BFC release];
}

static void DecryptMulist(NSString *InputFileName) {
    NSString *SavePath = [DocumentsDirectory() stringByAppendingString:InputFileName];
    NSString *musicListKey =
        [[[objc_getClass("JubeatAppDelegate") alloc] init] performSelector:@selector(musicListKey)];
    if (![[NSFileManager defaultManager] fileExistsAtPath:SavePath]) {
        NSLog(@"-----DecryptMulist-----\nFile  %@ Doesn't Exist", InputFileName);
        return;
    }
    NSLog(@"mulist Key:%@", musicListKey);
    if (musicListKey == nil) {
        NSLog(@"musicListKey is NIL");
        return;
    }
    NSMutableData *olddata = [NSMutableData dataWithContentsOfFile:SavePath];
    BFCodec *BFC = [[objc_getClass("BFCodec") alloc] init];
    const char *MK = [musicListKey UTF8String];
    int r5 = strlen(MK);
    CC_MD5_CTX md5;
    CC_MD5_Init(&md5);
    CC_MD5_Update(&md5, MK, r5);
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSData *s = [NSData dataWithBytes:digest length:0x10];

    [BFC cipherInit:s];
    [BFC decipher:olddata];
    NSMutableData *data = [NSMutableData dataWithData:[olddata subdataWithRange:NSMakeRange(4, olddata.length - 4)]];
    NSLog(@"Decrypted:\n%@", data);
    [data writeToFile:[SavePath stringByAppendingString:@".decrypted"] atomically:YES];

    [data release];
    [s release];
    [olddata release];
    [BFC release];
}

void init_Jubeat_hook() {
    NSLog(@"MUGKit--Jubeat");
    %init(Jubeat); // Or SaveMulist Would Be Using Wrong Key
    SaveMulist(@"mulist", @"Input.plist");
    // DecryptMulist(@"mulist");
}
