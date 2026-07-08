#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach/vm_map.h>
#import <mach/mach_init.h>
#import <mach/mach_types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// =====================================================================
// ĐỊNH NGHĨA CỨNG CÁC ĐỊNH DANH ĐỂ TRÁNH LỖI PHÂN GIẢI TRÊN MÁY ẢO GITHUB
// =====================================================================
#ifndef UIControlStateNormal
#define UIControlStateNormal 0
#endif
#ifndef UIControlStateSelected
#define UIControlStateSelected 4
#endif
#ifndef UIControlEventTouchUpInside
#define UIControlEventTouchUpInside (1 << 6)
#endif
#ifndef UIControlEventValueChanged
#define UIControlEventValueChanged (1 << 12)
#endif

// =====================================================================
// BIẾN LƯU OFFSET
// =====================================================================
static uintptr_t g_playerHealthOffset = 0;
static uintptr_t g_playerSpeedOffset = 0;
static uintptr_t g_cameraFovOffset = 0;

// =====================================================================
// CẤU HÌNH FIREBASE
// =====================================================================
static NSString *const FIREBASE_DB_URL = @"https://duchuy-75d5d-default-rtdb.firebaseio.com";
static NSString *const APP_ID = @"granny_v1_vip";

// =====================================================================
// BIẾN TRẠNG THÁI TOÀN CỤC
// =====================================================================
static BOOL isKeyValidated = NO;
static NSString *currentActiveKey = @"";
static NSString *usernameInfo = @"Chưa đăng ký";
static NSTimeInterval keyExpirationTimestamp = 0;
static NSTimer *countdownTimer = nil;

static BOOL isVietnamese = YES;
static NSInteger menuStyleCorner = 1;
static UIColor *menuAccentColor = nil;
static NSInteger accentColorIndex = 0;

static BOOL isAimbotActive = NO;
static NSString *aimTargetPosition = @"Đầu";
static BOOL isAimbotAlways = NO;
static BOOL isAimThroughWall = NO;
static float aimbotFovRadius = 120.0f;
static BOOL showFovCircle = YES;

static BOOL isEspActive = NO;
static BOOL isEspLines = YES;
static BOOL isEspBoxes = YES;
static BOOL isEspSkeleton = YES;
static float espMaxDistance = 250.0f;
static UIColor *espColor = nil;
static NSInteger espColorIndex = 0;

static BOOL isGodMode = NO;
static BOOL isHighSpeed = NO;
static float cameraFov = 60.0f;
static NSString *selectedItemToSpawn = @"Shotgun";

static UIWindow *floatingButtonWindow = nil;
static UIWindow *overlayMenuWindow = nil;
static UIView *menuContainer = nil;
static UIView *authPanel = nil;
static UIView *mainModPanel = nil;
static UITextField *keyInputField = nil;
static UILabel *countdownLabel = nil;
static UILabel *userLabel = nil;
static UILabel *keyDisplayLabel = nil;
static CAShapeLayer *fovCircleLayer = nil;
static UIButton *floatingLogoBtn = nil;

// =====================================================================
// FORWARD DECLARATION
// =====================================================================
@interface HuyMenuController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *contentArea;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *activeTabButton;
+ (void)drawFovCircleOnScreen;
+ (void)openMenuWithAnimation;
+ (void)toggleMenuGlobal;
@end

// =====================================================================
// HÀM LẤY BASE ADDRESS
// =====================================================================
static uintptr_t get_Framework_Base_Address(void) {
    uint32_t imageCount = _dyld_image_count();
    for (uint32_t i = 0; i < imageCount; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "UnityFramework") != NULL) {
            return (uintptr_t)_dyld_get_image_vmaddr_slide(i);
        }
    }
    return (uintptr_t)_dyld_get_image_vmaddr_slide(0);
}

// =====================================================================
// HÀM ĐỌC BỘ NHỚ
// =====================================================================
static kern_return_t readMemory(uintptr_t address, void *buffer, size_t size) {
    mach_port_t task = mach_task_self();
    vm_size_t outSize;
    return vm_read_overwrite(task, (vm_address_t)address, size, (vm_address_t)buffer, &outSize);
}

// =====================================================================
// HÀM TỰ ĐỘNG TÌM OFFSET
// =====================================================================
static uintptr_t scanForFloatValue(float targetValue, float tolerance, uintptr_t startAddr, uintptr_t endAddr) {
    uintptr_t current = startAddr;
    float buffer[1024];
    size_t bytesToRead = sizeof(buffer);
    
    while (current < endAddr) {
        if (current + bytesToRead > endAddr) {
            bytesToRead = endAddr - current;
        }
        
        kern_return_t kr = readMemory(current, buffer, bytesToRead);
        if (kr == KERN_SUCCESS) {
            size_t count = bytesToRead / sizeof(float);
            for (size_t i = 0; i < count; i++) {
                if (fabsf(buffer[i] - targetValue) < tolerance) {
                    return current + (i * sizeof(float));
                }
            }
        }
        current += bytesToRead;
    }
    return 0;
}

static void autoFindAllOffsets(void) {
    uintptr_t base = get_Framework_Base_Address();
    if (base == 0) {
        NSLog(@"❌ Không tìm thấy Framework base address!");
        return;
    }
    
    uintptr_t startAddr = base;
    uintptr_t endAddr = base + 0x1400000;
    
    NSLog(@"🔍 Bắt đầu quét tìm offset trong khoảng 0x%lx - 0x%lx", startAddr, endAddr);
    
    g_playerHealthOffset = scanForFloatValue(100.0f, 0.5f, startAddr, endAddr);
    if (g_playerHealthOffset != 0) {
        NSLog(@"✅ Tìm thấy offset máu: 0x%lx", g_playerHealthOffset);
    }
    
    g_playerSpeedOffset = scanForFloatValue(5.0f, 0.5f, startAddr, endAddr);
    if (g_playerSpeedOffset != 0) {
        NSLog(@"✅ Tìm thấy offset speed: 0x%lx", g_playerSpeedOffset);
    }
    
    g_cameraFovOffset = scanForFloatValue(60.0f, 0.5f, startAddr, endAddr);
    if (g_cameraFovOffset != 0) {
        NSLog(@"✅ Tìm thấy offset FOV: 0x%lx", g_cameraFovOffset);
    }
    
    NSLog(@"🔍 Hoàn tất quét offset!");
}

// =====================================================================
// HÀM PATCH MEMORY
// =====================================================================
static void patchMemory(uintptr_t address, const void *bytes, size_t size) {
    if (address == 0 || address < 0x100000) return;
    
    mach_port_t task = mach_task_self();
    kern_return_t kr;
    
    kr = mach_vm_protect(task, (mach_vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr == KERN_SUCCESS) {
        memcpy((void *)address, bytes, size);
        mach_vm_protect(task, (mach_vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

static void updateGameSpeedHack(void) {
    uintptr_t base = get_Framework_Base_Address();
    if (base == 0 || g_playerSpeedOffset == 0) return;
    
    uintptr_t speedAddress = base + g_playerSpeedOffset;
    if (isHighSpeed && isKeyValidated) {
        uint32_t patchBytes[] = {0x528003c0, 0xD65F03C0};
        patchMemory(speedAddress, patchBytes, sizeof(patchBytes));
    }
}

static void updateGodModeHack(void) {
    uintptr_t base = get_Framework_Base_Address();
    if (base == 0 || g_playerHealthOffset == 0) return;
    
    uintptr_t healthAddress = base + g_playerHealthOffset;
    if (isGodMode && isKeyValidated) {
        float health = 9999.0f;
        patchMemory(healthAddress, &health, sizeof(health));
    }
}

// =====================================================================
// HÀM LẤY ACTIVE WINDOW SCENE
// =====================================================================
static UIWindowScene* getActiveWindowScene(void) {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                return (UIWindowScene *)scene;
            }
        }
    }
    return nil;
}

// =====================================================================
// LƯU/LOAD SETTINGS
// =====================================================================
static void loadSavedModSettings(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"huy_settings_saved"] != nil) {
        isAimbotActive = [defaults boolForKey:@"huy_aimbot_active"];
        aimTargetPosition = [defaults stringForKey:@"huy_aim_target"] ?: @"Đầu";
        isAimbotAlways = [defaults boolForKey:@"huy_aim_always"];
        isAimThroughWall = [defaults boolForKey:@"huy_aim_wall"];
        aimbotFovRadius = [defaults floatForKey:@"huy_aim_fov_radius"] ?: 120.0f;
        showFovCircle = [defaults boolForKey:@"huy_show_fov_circle"];
        isEspActive = [defaults boolForKey:@"huy_esp_active"];
        isEspLines = [defaults boolForKey:@"huy_esp_lines"];
        isEspBoxes = [defaults boolForKey:@"huy_esp_boxes"];
        isEspSkeleton = [defaults boolForKey:@"huy_esp_skeleton"];
        espMaxDistance = [defaults floatForKey:@"huy_esp_max_distance"] ?: 250.0f;
        espColorIndex = [defaults integerForKey:@"huy_esp_color_idx"];
        isGodMode = [defaults boolForKey:@"huy_god_mode"];
        isHighSpeed = [defaults boolForKey:@"huy_high_speed"];
        cameraFov = [defaults floatForKey:@"huy_camera_fov"] ?: 60.0f;
        menuStyleCorner = [defaults integerForKey:@"huy_menu_corner"];
        accentColorIndex = [defaults integerForKey:@"huy_accent_color_idx"];
        isVietnamese = [defaults objectForKey:@"huy_lang_viet"] ? [defaults boolForKey:@"huy_lang_viet"] : YES;
    }
}

static void saveAllModSettingsToDevice(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"huy_settings_saved"];
    [defaults setBool:isAimbotActive forKey:@"huy_aimbot_active"];
    [defaults setObject:aimTargetPosition forKey:@"huy_aim_target"];
    [defaults setBool:isAimbotAlways forKey:@"huy_aim_always"];
    [defaults setBool:isAimThroughWall forKey:@"huy_aim_wall"];
    [defaults setFloat:aimbotFovRadius forKey:@"huy_aim_fov_radius"];
    [defaults setBool:showFovCircle forKey:@"huy_show_fov_circle"];
    [defaults setBool:isEspActive forKey:@"huy_esp_active"];
    [defaults setBool:isEspLines forKey:@"huy_esp_lines"];
    [defaults setBool:isEspBoxes forKey:@"huy_esp_boxes"];
    [defaults setBool:isEspSkeleton forKey:@"huy_esp_skeleton"];
    [defaults setFloat:espMaxDistance forKey:@"huy_esp_max_distance"];
    [defaults setInteger:espColorIndex forKey:@"huy_esp_color_idx"];
    [defaults setBool:isGodMode forKey:@"huy_god_mode"];
    [defaults setBool:isHighSpeed forKey:@"huy_high_speed"];
    [defaults setFloat:cameraFov forKey:@"huy_camera_fov"];
    [defaults setInteger:menuStyleCorner forKey:@"huy_menu_corner"];
    [defaults setInteger:accentColorIndex forKey:@"huy_accent_color_idx"];
    [defaults setBool:isVietnamese forKey:@"huy_lang_viet"];
    [defaults synchronize];
}

// =====================================================================
// LỚP CỬA SỔ TRONG SUỐT
// =====================================================================
@interface HuyPassthroughWindow : UIWindow
@end

@implementation HuyPassthroughWindow

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (menuContainer && !menuContainer.hidden && menuContainer.alpha > 0) {
        CGPoint pointInContainer = [menuContainer convertPoint:point fromView:self];
        if ([menuContainer pointInside:pointInContainer withEvent:event]) {
            return hitView;
        }
    }
    return nil;
}

@end

// =====================================================================
// HOOK UIWindow SEND EVENT
// =====================================================================
static void (*orig_UIWindow_sendEvent)(id, SEL, UIEvent *);

static void custom_UIWindow_sendEvent(UIWindow *self, SEL _cmd, UIEvent *event) {
    if (event.type == UIEventTypeTouches) {
        NSSet *touches = [event allTouches];
        if (touches.count == 3) {
            UITouch *touch = [touches anyObject];
            if (touch.phase == UITouchPhaseEnded && touch.tapCount == 2) {
                static NSTimeInterval lastTapTime = 0;
                NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
                if (now - lastTapTime > 0.5) {
                    lastTapTime = now;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [HuyMenuController toggleMenuGlobal];
                    });
                }
            }
        }
    }
    orig_UIWindow_sendEvent(self, _cmd, event);
}

// =====================================================================
// LỚP ĐIỀU KHIỂN GIAO DIỆN
// =====================================================================
@implementation HuyMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Khởi tạo màu mặc định
    if (!menuAccentColor) {
        menuAccentColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1.0];
    }
    if (!espColor) {
        espColor = [UIColor redColor];
    }
    
    // Khung chứa Menu
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 580, 320)];
    menuContainer.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.11 alpha:0.96];
    menuContainer.layer.borderWidth = 1.5;
    menuContainer.layer.borderColor = menuAccentColor.CGColor;
    menuContainer.hidden = YES;
    [self updateMenuContainerStyle];
    [self.view addSubview:menuContainer];
    
    UIPanGestureRecognizer *panDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuDrag:)];
    [menuContainer addGestureRecognizer:panDrag];
    
    // ========== AUTH PANEL ==========
    authPanel = [[UIView alloc] initWithFrame:menuContainer.bounds];
    authPanel.backgroundColor = [UIColor clearColor];
    [menuContainer addSubview:authPanel];
    
    UILabel *authTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 35, 540, 30)];
    authTitle.text = isVietnamese ? @"HỆ THỐNG XÁC THỰC BẢO MẬT VIP" : @"SECURE VIP AUTHENTICATION";
    authTitle.textColor = menuAccentColor;
    authTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    authTitle.textAlignment = NSTextAlignmentCenter;
    [authPanel addSubview:authTitle];
    
    UILabel *authSub = [[UILabel alloc] initWithFrame:CGRectMake(20, 75, 540, 20)];
    authSub.text = isVietnamese ? @"Vui lòng nhập mã kích hoạt (Key) được cấp từ Admin Đức Huy" : @"Please enter your activation key from Admin";
    authSub.textColor = [UIColor lightGrayColor];
    authSub.font = [UIFont systemFontOfSize:11];
    authSub.textAlignment = NSTextAlignmentCenter;
    [authPanel addSubview:authSub];
    
    keyInputField = [[UITextField alloc] initWithFrame:CGRectMake(110, 115, 360, 45)];
    keyInputField.backgroundColor = [UIColor colorWithRed:0.04 green:0.05 blue:0.08 alpha:1.0];
    keyInputField.layer.borderColor = [UIColor darkGrayColor].CGColor;
    keyInputField.layer.borderWidth = 1;
    keyInputField.layer.cornerRadius = 8;
    keyInputField.textColor = [UIColor whiteColor];
    keyInputField.font = [UIFont fontWithName:@"Courier-Bold" size:15];
    keyInputField.textAlignment = NSTextAlignmentCenter;
    keyInputField.placeholder = @"HUY-XXXX-XXXX-XXXX";
    keyInputField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:keyInputField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor darkGrayColor]}];
    keyInputField.delegate = self;
    [authPanel addSubview:keyInputField];
    
    UIButton *submitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    submitBtn.frame = CGRectMake(110, 180, 360, 45);
    submitBtn.backgroundColor = menuAccentColor;
    submitBtn.layer.cornerRadius = 8;
    [submitBtn setTitle:isVietnamese ? @"KÍCH HOẠT THỜI GIAN THỰC" : @"ACTIVATE NOW" forState:UIControlStateNormal];
    [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    submitBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
    [submitBtn addTarget:self action:@selector(verifyLicenseKeyOnFirebase) forControlEvents:UIControlEventTouchUpInside];
    [authPanel addSubview:submitBtn];
    
    UILabel *contactAdmin = [[UILabel alloc] initWithFrame:CGRectMake(20, 245, 540, 20)];
    contactAdmin.text = isVietnamese ? @"Thiết kế độc quyền bởi sếp Đồng Đức Huy" : @"Exclusively programmed by Dong Duc Huy";
    contactAdmin.textColor = [UIColor grayColor];
    contactAdmin.font = [UIFont systemFontOfSize:10];
    contactAdmin.textAlignment = NSTextAlignmentCenter;
    [authPanel addSubview:contactAdmin];
    
    UIButton *closeAuthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeAuthBtn.frame = CGRectMake(545, 10, 25, 25);
    closeAuthBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.1 blue:0.1 alpha:0.2];
    closeAuthBtn.layer.cornerRadius = 12.5;
    [closeAuthBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeAuthBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeAuthBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [closeAuthBtn addTarget:self action:@selector(closeMenuWithAnimation) forControlEvents:UIControlEventTouchUpInside];
    [authPanel addSubview:closeAuthBtn];
    
    // ========== MAIN MOD PANEL ==========
    mainModPanel = [[UIView alloc] initWithFrame:menuContainer.bounds];
    mainModPanel.backgroundColor = [UIColor clearColor];
    mainModPanel.hidden = YES;
    [menuContainer addSubview:mainModPanel];
    
    self.sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 320)];
    self.sidebar.backgroundColor = [UIColor colorWithRed:0.04 green:0.05 blue:0.08 alpha:0.98];
    [mainModPanel addSubview:self.sidebar];
    
    UILabel *sidebarLogo = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 120, 25)];
    sidebarLogo.text = @"💀 HUY MENU VIP";
    sidebarLogo.textColor = menuAccentColor;
    sidebarLogo.font = [UIFont fontWithName:@"Helvetica-Bold" size:13];
    sidebarLogo.textAlignment = NSTextAlignmentCenter;
    [self.sidebar addSubview:sidebarLogo];
    
    UIButton *closeMainBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeMainBtn.frame = CGRectMake(545, 10, 25, 25);
    closeMainBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.1 blue:0.1 alpha:0.2];
    closeMainBtn.layer.cornerRadius = 12.5;
    [closeMainBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeMainBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeMainBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [closeMainBtn addTarget:self action:@selector(closeMenuWithAnimation) forControlEvents:UIControlEventTouchUpInside];
    [mainModPanel addSubview:closeMainBtn];
    
    self.contentArea = [[UIView alloc] initWithFrame:CGRectMake(150, 40, 420, 270)];
    self.contentArea.backgroundColor = [UIColor clearColor];
    [mainModPanel addSubview:self.contentArea];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:self.contentArea.bounds];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.contentArea addSubview:self.scrollView];
    
    [self buildSidebarTabs];
    
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"huy_saved_activation_key"];
    if (savedKey && savedKey.length > 0) {
        keyInputField.text = savedKey;
        [self verifyLicenseKeyOnFirebase];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    menuContainer.center = CGPointMake(bounds.size.width / 2, bounds.size.height / 2);
}

- (void)handleMenuDrag:(UIPanGestureRecognizer *)gesture {
    CGPoint trans = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        menuContainer.center = CGPointMake(menuContainer.center.x + trans.x, menuContainer.center.y + trans.y);
        [gesture setTranslation:CGPointZero inView:self.view];
    }
}

- (void)closeMenuWithAnimation {
    [UIView animateWithDuration:0.2 animations:^{
        menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
        menuContainer.alpha = 0.0;
    } completion:^(BOOL finished) {
        menuContainer.hidden = YES;
    }];
}

+ (void)openMenuWithAnimation {
    menuContainer.hidden = NO;
    menuContainer.transform = CGAffineTransformMakeScale(0.6, 0.6);
    menuContainer.alpha = 0.0;
    [UIView animateWithDuration:0.25 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        menuContainer.transform = CGAffineTransformIdentity;
        menuContainer.alpha = 1.0;
    } completion:nil];
}

+ (void)toggleMenuGlobal {
    if (menuContainer.hidden) {
        [HuyMenuController openMenuWithAnimation];
        [HuyMenuController drawFovCircleOnScreen];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
            menuContainer.alpha = 0.0;
        } completion:^(BOOL finished) {
            menuContainer.hidden = YES;
        }];
    }
}

- (void)updateThemeColors {
    // Hàm này được gọi từ các segment
}

- (void)updateMenuContainerStyle {
    if (menuStyleCorner == 1) {
        menuContainer.layer.cornerRadius = 16.0f;
        self.sidebar.layer.cornerRadius = 16.0f;
    } else {
        menuContainer.layer.cornerRadius = 0.0f;
        self.sidebar.layer.cornerRadius = 0.0f;
    }
    menuContainer.clipsToBounds = YES;
}

- (void)buildSidebarTabs {
    for (UIView *subview in self.sidebar.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            [subview removeFromSuperview];
        }
    }
    
    NSArray *tabNames = isVietnamese ? @[@"Aimbot", @"ESP Vẽ", @"Tính năng", @"Tài khoản"] : @[@"Aimbot", @"ESP View", @"Features", @"License"];
    NSArray *tabIcons = @[@"🎯", @"👁️", @"📦", @"👤"];
    
    for (int i = 0; i < tabNames.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 60 + (i * 48), 140, 44);
        btn.tag = 300 + i;
        [btn setTitle:[NSString stringWithFormat:@"  %@  %@", tabIcons[i], tabNames[i]] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor colorWithWhite:0.7 alpha:1.0] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:12];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        [btn addTarget:self action:@selector(tabClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
        
        if (i == 0) {
            [self selectTabBtn:btn];
        }
    }
}

- (void)tabClicked:(UIButton *)sender {
    [self selectTabBtn:sender];
    [self renderActiveTabScreen:(sender.tag - 300)];
}

- (void)selectTabBtn:(UIButton *)sender {
    if (self.activeTabButton) {
        self.activeTabButton.backgroundColor = [UIColor clearColor];
        [self.activeTabButton setTitleColor:[UIColor colorWithWhite:0.7 alpha:1.0] forState:UIControlStateNormal];
    }
    self.activeTabButton = sender;
    sender.backgroundColor = [menuAccentColor colorWithAlphaComponent:0.15];
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)verifyLicenseKeyOnFirebase {
    NSString *inputKey = [keyInputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (inputKey.length == 0) {
        [self showToast:isVietnamese ? @"Vui lòng nhập Key!" : @"Key cannot be empty!"];
        return;
    }
    
    [self showToast:isVietnamese ? @"Đang đối chiếu dữ liệu..." : @"Matching system key..."];
    
    NSString *endpoint = [NSString stringWithFormat:@"%@/artifacts/%@/public/data/keys/%@.json", FIREBASE_DB_URL, APP_ID, inputKey];
    NSURL *url = [NSURL URLWithString:endpoint];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self showToast:isVietnamese ? @"Lỗi liên kết Firebase!" : @"Firebase connect error!"];
                return;
            }
            
            if (!data) {
                [self showToast:isVietnamese ? @"Mã kích hoạt bị trống!" : @"Key responds empty!"];
                return;
            }
            
            NSError *jsonErr = nil;
            NSDictionary *keyData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
            
            if (jsonErr || !keyData || [keyData isKindOfClass:[NSNull class]]) {
                [self showToast:isVietnamese ? @"Key không tồn tại!" : @"Key does not exist!"];
                return;
            }
            
            NSString *username = keyData[@"username"] ? keyData[@"username"] : @"Khách hàng VIP";
            NSTimeInterval expiration = [keyData[@"expiration"] doubleValue];
            NSTimeInterval currentEpoch = [[NSDate date] timeIntervalSince1970];
            
            if (expiration < currentEpoch) {
                [self showToast:isVietnamese ? @"Key của sếp đã hết hạn!" : @"Your key has expired!"];
                return;
            }
            
            isKeyValidated = YES;
            currentActiveKey = inputKey;
            usernameInfo = username;
            keyExpirationTimestamp = expiration;
            
            [[NSUserDefaults standardUserDefaults] setObject:inputKey forKey:@"huy_saved_activation_key"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            authPanel.hidden = YES;
            mainModPanel.hidden = NO;
            menuContainer.hidden = NO;
            [self renderActiveTabScreen:0];
            
            [self startExpirationTimer];
            [self showToast:isVietnamese ? @"Đã mở khóa toàn bộ Menu VIP!" : @"VIP Menu unlocked!"];
        });
    }];
    [task resume];
}

- (void)startExpirationTimer {
    if (countdownTimer) {
        [countdownTimer invalidate];
    }
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateCountdownRealtime) userInfo:nil repeats:YES];
}

- (void)updateCountdownRealtime {
    NSTimeInterval currentEpoch = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval remaining = keyExpirationTimestamp - currentEpoch;
    
    if (remaining <= 0) {
        [countdownTimer invalidate];
        isKeyValidated = NO;
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"huy_saved_activation_key"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        mainModPanel.hidden = YES;
        authPanel.hidden = NO;
        menuContainer.hidden = NO;
        [self showToast:isVietnamese ? @"Hạn dùng Key đã kết thúc!" : @"License expired!"];
        return;
    }
    
    NSInteger days = (NSInteger)(remaining / (3600 * 24));
    NSInteger hours = (NSInteger)(((NSInteger)remaining % (3600 * 24)) / 3600);
    NSInteger minutes = (NSInteger)(((NSInteger)remaining % 3600) / 60);
    NSInteger seconds = (NSInteger)((NSInteger)remaining % 60);
    
    if (isVietnamese) {
        countdownLabel.text = [NSString stringWithFormat:@"Hạn dùng: %ld ngày %02ld:%02ld:%02ld", (long)days, (long)hours, (long)minutes, (long)seconds];
    } else {
        countdownLabel.text = [NSString stringWithFormat:@"Time Left: %ld days %02ld:%02ld:%02ld", (long)days, (long)hours, (long)minutes, (long)seconds];
    }
}

- (void)showToast:(NSString *)msg {
    UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    toast.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 40);
    toast.backgroundColor = [[UIColor blackColor] colorWithAlpha
