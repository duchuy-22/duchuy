// make.dylib.m
// FPS Overlay tweak — hiển thị FPS thời gian thực trên màn hình
// và cho phép bật/tắt từ xa qua một HTTP server cục bộ (điều khiển từ web UI).
//
// Build bằng Theos (xem Makefile đi kèm).

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <pthread.h>

// ====== Cấu hình ======
static const int kServerPort = 8123; // đổi nếu bị trùng cổng

// ====== Trạng thái toàn cục ======
static UILabel *gFPSLabel = nil;
static BOOL gOverlayEnabled = NO;
static double gCurrentFPS = 0;

#pragma mark - Bộ đo FPS

@interface FPSMonitor : NSObject
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic, assign) NSTimeInterval lastTimestamp;
- (void)start;
- (void)stop;
@end

@implementation FPSMonitor

- (void)start {
    if (self.displayLink) return;
    self.frameCount = 0;
    self.lastTimestamp = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stop {
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        return;
    }
    self.frameCount++;
    NSTimeInterval delta = link.timestamp - self.lastTimestamp;
    if (delta >= 1.0) {
        double fps = self.frameCount / delta;
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
        gCurrentFPS = fps;
        dispatch_async(dispatch_get_main_queue(), ^{
            gFPSLabel.text = [NSString stringWithFormat:@"%.0f FPS", fps];
        });
    }
}

@end

static FPSMonitor *gMonitor = nil;

#pragma mark - Overlay UI

static void ensureOverlayCreated(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) return;

        if (!gFPSLabel) {
            gFPSLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 44, 96, 26)];
            gFPSLabel.textColor = [UIColor greenColor];
            gFPSLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
            gFPSLabel.font = [UIFont boldSystemFontOfSize:14];
            gFPSLabel.textAlignment = NSTextAlignmentCenter;
            gFPSLabel.layer.cornerRadius = 6;
            gFPSLabel.layer.zPosition = CGFLOAT_MAX;
            gFPSLabel.clipsToBounds = YES;
            gFPSLabel.text = @"-- FPS";
            gFPSLabel.hidden = YES;
            gFPSLabel.windowLevel = UIWindowLevelStatusBar + 1;
        }
        [window addSubview:gFPSLabel];
        [window bringSubviewToFront:gFPSLabel];
    });
}

static void setOverlayEnabled(BOOL enabled) {
    gOverlayEnabled = enabled;
    ensureOverlayCreated();
    dispatch_async(dispatch_get_main_queue(), ^{
        gFPSLabel.hidden = !enabled;
    });
    if (enabled) {
        if (!gMonitor) gMonitor = [FPSMonitor new];
        [gMonitor start];
    } else {
        [gMonitor stop];
    }
}

#pragma mark - HTTP control server (localhost)
// Web UI gọi:
//   GET /fps          -> {"fps": 60, "enabled": true}
//   GET /toggle?on=1  -> bật overlay
//   GET /toggle?on=0  -> tắt overlay

static NSString *jsonStatus(void) {
    return [NSString stringWithFormat:@"{\"fps\":%.1f,\"enabled\":%@}",
            gCurrentFPS, gOverlayEnabled ? @"true" : @"false"];
}

static void handleClient(int clientSocket) {
    char buffer[1024] = {0};
    ssize_t n = recv(clientSocket, buffer, sizeof(buffer) - 1, 0);
    if (n <= 0) { close(clientSocket); return; }

    NSString *request = [NSString stringWithUTF8String:buffer];
    NSString *body = nil;

    if ([request containsString:@"GET /fps"]) {
        body = jsonStatus();
    } else if ([request containsString:@"GET /toggle"]) {
        BOOL on = [request containsString:@"on=1"];
        setOverlayEnabled(on);
        body = jsonStatus();
    } else {
        body = @"{\"error\":\"not_found\"}";
    }

    NSString *response = [NSString stringWithFormat:
        @"HTTP/1.1 200 OK\r\n"
        "Content-Type: application/json\r\n"
        "Access-Control-Allow-Origin: *\r\n"
        "Content-Length: %lu\r\n"
        "Connection: close\r\n\r\n%@",
        (unsigned long)[body lengthOfBytesUsingEncoding:NSUTF8StringEncoding], body];

    const char *utf8 = [response UTF8String];
    send(clientSocket, utf8, strlen(utf8), 0);
    close(clientSocket);
}

static void *serverLoop(void *arg) {
    int serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSocket < 0) return NULL;

    int opt = 1;
    setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_port = htons(kServerPort);

    if (bind(serverSocket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(serverSocket);
        return NULL;
    }
    if (listen(serverSocket, 8) < 0) {
        close(serverSocket);
        return NULL;
    }

    while (1) {
        struct sockaddr_in clientAddr;
        socklen_t clientLen = sizeof(clientAddr);
        int clientSocket = accept(serverSocket, (struct sockaddr *)&clientAddr, &clientLen);
        if (clientSocket >= 0) {
            handleClient(clientSocket);
        }
    }
    return NULL;
}

static void startHTTPServer(void) {
    pthread_t thread;
    pthread_create(&thread, NULL, serverLoop, NULL);
    pthread_detach(thread);
}

#pragma mark - Entry point

__attribute__((constructor))
static void tweakInit(void) {
    ensureOverlayCreated();
    startHTTPServer();
}
