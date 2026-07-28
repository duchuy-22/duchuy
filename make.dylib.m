// ============================================
// make.dylib.m - ESP + Bypass AntiCheat
// Copy toàn bộ file này vào GitHub
// ============================================

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ========== OFFSET (CẦN THAY RVA THỰC) ==========
#define OFFSET_HEALTH        0x6D3CAF8
#define OFFSET_POSITION      0x2326A78

// ========== BIẾN TOÀN CỤ ==========
static BOOL enableESP = YES;
static BOOL bypassReport = YES;
static BOOL bypassDebug = YES;

// ============================================
// MENU ESP
// ============================================

@interface MenuESPViewController : UIViewController
+ (void)showMenu;
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

    UIAlertAction *close = [UIAlertAction 
        actionWithTitle:@"✖ Đóng" 
        style:UIAlertActionStyleCancel 
        handler:nil];

    [alert addAction:toggleESP];
    [alert addAction:close];

    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    [root presentViewController:alert animated:YES completion:nil];
}

@end

// ============================================
// HOOK KÍCH HOẠT MENU
// ============================================

%hook UIApplication
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    [MenuESPViewController showMenu];
}
%end

// ============================================
// BYPASS REPORT + DEBUG
// ============================================

%hook ReportManager
- (void)SendReport:(id)report {
    if (bypassReport) return;
    %orig;
}
%end

%hook AntiDebug
- (BOOL)isDebugged {
    if (bypassDebug) return NO;
    return %orig;
}
%end

// ============================================
// HOOK ESP
// ============================================

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
// CONSTRUCTOR
// ============================================

%ctor {
    NSLog(@"[MenuESP] Da inject thanh cong!");
    enableESP = YES;
    bypassReport = YES;
    bypassDebug = YES;
}

%dtor {
    NSLog(@"[MenuESP] Da go bo.");
}
