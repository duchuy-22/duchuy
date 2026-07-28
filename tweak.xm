// ============================================
// MenuESP.xm - ESP + Bypass AntiCheat
// ============================================

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ========== OFFSET (CẦN THAY RVA THỰC) ==========
#define OFFSET_HEALTH        0x6D3CAF8
#define OFFSET_POSITION      0x2326A78
#define OFFSET_CAMERA        0x38
#define OFFSET_BINDPLAYER    0x20

// ========== BIẾN TOÀN CỤ ==========
static BOOL enableESP = YES;
static BOOL espShowBox = YES;
static BOOL espShowLine = YES;
static BOOL espShowName = YES;
static BOOL espShowHealth = YES;
static BOOL espShowDistance = YES;

// === BYPASS SWITCHES ===
static BOOL bypassReport = YES;
static BOOL bypassMemoryScan = YES;
static BOOL bypassDebug = YES;
static BOOL bypassJailbreak = YES;
static BOOL bypassDeviceID = YES;

// ============================================
// PHẦN 1: MENU CHÍNH
// ============================================

@interface MenuESPViewController : UIViewController
+ (void)showMenu;
+ (void)showSettings;
+ (void)showBypassMenu;
@end

@implementation MenuESPViewController

+ (void)showMenu {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"🎯 MENU ESP" 
        message:[NSString stringWithFormat:@"ESP %@", enableESP ? @"🟢 BẬT" : @"🔴 TẮT"]
        preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *toggleESP = [UIAlertAction 
        actionWithTitle:[NSString stringWithFormat:@"ESP %@", enableESP ? @"✅" : @"❌"]
        style:UIAlertActionStyleDefault 
        handler:^(UIAlertAction *a) {
            enableESP = !enableESP;
            [self showMenu];
        }];

    UIAlertAction *settings = [UIAlertAction 
        actionWithTitle:@"⚙️ Cài đặt ESP" 
        style:UIAlertActionStyleDefault 
        handler:^(UIAlertAction *a) {
            [self showSettings];
        }];

    UIAlertAction *bypass = [UIAlertAction 
        actionWithTitle:@"🛡️ Bypass" 
        style:UIAlertActionStyleDefault 
        handler:^(UIAlertAction *a) {
            [self showBypassMenu];
        }];

    UIAlertAction *close = [UIAlertAction 
        actionWithTitle:@"✖ Đóng" 
        style:UIAlertActionStyleCancel 
        handler:nil];

    [alert addAction:toggleESP];
    [alert addAction:settings];
    [alert addAction:bypass];
    [alert addAction:close];

    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    [root presentViewController:alert animated:YES completion:nil];
}

// ===== CÀI ĐẶT ESP =====
+ (void)showSettings {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"⚙️ CÀI ĐẶT ESP" 
        message:@"Chọn thành phần" 
        preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *names = @[@"Box", @"Line", @"Tên", @"Máu", @"Khoảng cách"];
    BOOL *states[] = {&espShowBox, &espShowLine, &espShowName, &espShowHealth, &espShowDistance};

    for (int i = 0; i < 5; i++) {
        NSString *title = [NSString stringWithFormat:@"%@ %@", names[i], *states[i] ? @"✅" : @"❌"];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            *states[i] = !(*states[i]);
            [self showSettings];
        }];
        [alert addAction:action];
    }

    UIAlertAction *back = [UIAlertAction actionWithTitle:@"◀ Quay lại" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
        [self showMenu];
    }];
    [alert addAction:back];

    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    [root presentViewController:alert animated:YES completion:nil];
}

// ===== MENU BYPASS =====
+ (void)showBypassMenu {
    UIAlertController *alert = [UIAlertController 
        alertControllerWithTitle:@"🛡️ BYPASS" 
        message:@"Bật/tắt từng lớp" 
        preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *names = @[@"Report/Log", @"Memory Scan", @"Anti-Debug", @"Jailbreak", @"Device ID"];
    BOOL *states[] = {&bypassReport, &bypassMemoryScan, &bypassDebug, &bypassJailbreak, &bypassDeviceID};

    for (int i = 0; i < 5; i++) {
        NSString *title = [NSString stringWithFormat:@"%@ %@", names[i], *states[i] ? @"✅" : @"❌"];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            *states[i] = !(*states[i]);
            [self showBypassMenu];
        }];
        [alert addAction:action];
    }

    UIAlertAction *back = [UIAlertAction actionWithTitle:@"◀ Quay lại" style:UIAlertActionStyleCancel handler:^(UIAlertAction *a) {
        [self showMenu];
    }];
    [alert addAction:back];

    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    [root presentViewController:alert animated:YES completion:nil];
}

@end

// ============================================
// PHẦN 2: HOOK KÍCH HOẠT MENU
// ============================================

%hook UIApplication
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    [MenuESPViewController showMenu];
}
%end

// ============================================
// PHẦN 3: BYPASS ANTI-CHEAT
// ============================================

// 3.1 Bypass Report / Log (chặn gửi báo cáo)
%hook ReportManager
- (void)SendReport:(id)report {
    if (bypassReport) return;
    %orig;
}
- (void)UploadLog:(id)log {
    if (bypassReport) return;
    %orig;
}
%end

// 3.2 Bypass Memory Scan (chặn quét bộ nhớ)
%hook MemoryScanner
- (void)ScanMemory {
    if (bypassMemoryScan) return;
    %orig;
}
- (BOOL)DetectMod {
    if (bypassMemoryScan) return NO;
    return %orig;
}
%end

// 3.3 Bypass Anti-Debug
%hook AntiDebug
- (BOOL)isDebugged {
    if (bypassDebug) return NO;
    return %orig;
}
%end

// 3.4 Bypass Jailbreak Detection
%hook JailbreakDetection
- (BOOL)isJailbroken {
    if (bypassJailbreak) return NO;
    return %orig;
}
%end

// 3.5 Bypass Device ID (fake ID)
%hook DeviceInfo
- (NSString *)get_DeviceId {
    if (bypassDeviceID) return @"FAKE_DEVICE_ESP_2026";
    return %orig;
}
- (NSString *)get_MacAddress {
    if (bypassDeviceID) return @"02:00:00:00:00:00";
    return %orig;
}
%end

// 3.6 Bypass chặn gửi data qua URL (không cần offset)
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (bypassReport) {
        NSArray *blocked = @[@"report", @"log", @"analytics", @"crashlytics", @"garena", @"firebase"];
        for (NSString *s in blocked) {
            if ([request.URL.absoluteString containsString:s]) {
                return nil;
            }
        }
    }
    return %orig;
}
%end

// ============================================
// PHẦN 4: HOOK ESP (LẤY DỮ LIỆU PLAYER)
// ============================================

// THAY TÊN CLASS BẰNG CLASS THỰC TẾ
%hook BHGGAEEHJCO

- (Vector3)get_Position {
    if (!enableESP) return %orig;
    return %orig;
}

- (int)get_Health {
    if (!enableESP) return %orig;
    return %orig;
}

%end

// ============================================
// PHẦN 5: CONSTRUCTOR
// ============================================

%ctor {
    NSLog(@"[MenuESP] Đã inject thành công!");
    // Bật bypass mặc định
    bypassReport = YES;
    bypassMemoryScan = YES;
    bypassDebug = YES;
    bypassJailbreak = YES;
    bypassDeviceID = YES;
    enableESP = YES;
}

%dtor {
    NSLog(@"[MenuESP] Đã gỡ bỏ.");
}
