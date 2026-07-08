#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

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
// BIẾN LƯU OFFSET TỰ ĐỘNG TÌM
// =====================================================================
static uintptr_t g_playerHealthOffset = 0;
static uintptr_t g_playerSpeedOffset = 0;
static uintptr_t g_cameraFovOffset = 0;
static uintptr_t g_grannyPositionOffset = 0;
static uintptr_t g_grannyIsDeadOffset = 0;
static uintptr_t g_keyCountOffset = 0;

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
// BỘ TỰ ĐỘNG TÌM OFFSET BẰNG MACH VIRTUAL MEMORY
// =====================================================================

// Hàm đọc bộ nhớ
static kern_return_t readMemory(uintptr_t address, void *buffer, size_t size) {
    mach_port_t task = mach_task_self();
    vm_size_t outSize;
    return vm_read_overwrite(task, (vm_address_t)address, size, (vm_address_t)buffer, &outSize);
}

// Hàm quét tìm giá trị float trong bộ nhớ
static uintptr_t scanForFloatValue(float targetValue, float tolerance, uintptr_t startAddr, uintptr_t endAddr) {
    uintptr_t current = startAddr;
    float buffer[1024];
    
    while (current < endAddr) {
        size_t bytesToRead = sizeof(buffer);
        if (current + bytesToRead > endAddr) {
            bytesToRead = endAddr - current;
        }
        
        kern_return_t kr = readMemory(current, buffer, bytesToRead);
        if (kr == KERN_SUCCESS) {
            size_t count = bytesToRead / sizeof(float);
            for (size_t i = 0; i < count; i++) {
                if (fabs(buffer[i] - targetValue) < tolerance) {
                    return current + (i * sizeof(float));
                }
            }
        }
        current += bytesToRead;
    }
    return 0;
}

// Hàm quét tìm giá trị int trong bộ nhớ
static uintptr_t scanForIntValue(int targetValue, uintptr_t startAddr, uintptr_t endAddr) {
    uintptr_t current = startAddr;
    int buffer[1024];
    
    while (current < endAddr) {
        size_t bytesToRead = sizeof(buffer);
        if (current + bytesToRead > endAddr) {
            bytesToRead = endAddr - current;
        }
        
        kern_return_t kr = readMemory(current, buffer, bytesToRead);
        if (kr == KERN_SUCCESS) {
            size_t count = bytesToRead / sizeof(int);
            for (size_t i = 0; i < count; i++) {
                if (buffer[i] == targetValue) {
                    return current + (i * sizeof(int));
                }
            }
        }
        current += bytesToRead;
    }
    return 0;
}

// Hàm tự động tìm offset bằng cách quét bộ nhớ
static void autoFindAllOffsets() {
    uintptr_t base = get_Framework_Base_Address();
    if (base == 0) {
        NSLog(@"❌ Không tìm thấy Framework base address!");
        return;
    }
    
    // Quét trong phạm vi 20MB từ base
    uintptr_t startAddr = base;
    uintptr_t endAddr = base + 0x1400000; // 20MB
    
    NSLog(@"🔍 Bắt đầu quét tìm offset trong khoảng 0x%lx - 0x%lx", startAddr, endAddr);
    
    // Tìm offset của máu (giá trị float 100.0)
    g_playerHealthOffset = scanForFloatValue(100.0f, 0.5f, startAddr, endAddr);
    if (g_playerHealthOffset != 0) {
        NSLog(@"✅ Tìm thấy offset máu: 0x%lx", g_playerHealthOffset);
    } else {
        // Thử tìm giá trị 100 dạng int
        g_playerHealthOffset = scanForIntValue(100, startAddr, endAddr);
        if (g_playerHealthOffset != 0) {
            NSLog(@"✅ Tìm thấy offset máu (int): 0x%lx", g_playerHealthOffset);
        }
    }
    
    // Tìm offset của speed (giá trị float 5.0 - speed mặc định)
    g_playerSpeedOffset = scanForFloatValue(5.0f, 0.5f, startAddr, endAddr);
    if (g_playerSpeedOffset != 0) {
        NSLog(@"✅ Tìm thấy offset speed: 0x%lx", g_playerSpeedOffset);
    }
    
    // Tìm offset của FOV (giá trị float 60.0)
    g_cameraFovOffset = scanForFloatValue(60.0f, 0.5f, startAddr, endAddr);
    if (g_cameraFovOffset != 0) {
        NSLog(@"✅ Tìm thấy offset FOV: 0x%lx", g_cameraFovOffset);
    }
    
    // Tìm offset của key (giá trị int 0 hoặc 1)
    g_keyCountOffset = scanForIntValue(0, startAddr, endAddr);
    if (g_keyCountOffset != 0) {
        NSLog(@"✅ Tìm thấy offset key: 0x%lx", g_keyCountOffset);
    }
    
    NSLog(@"🔍 Hoàn tất quét offset!");
}

// =====================================================================
// HÀM LẤY BASE ADDRESS
// =====================================================================
static uintptr_t get_Framework_Base_Address() {
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
// HÀM PATCH MEMORY
// =====================================================================
static void patchMemory(uintptr_t address, const void *bytes, size_t size) {
    if (address == 0 || address < 0x100000) return;
    
    mach_port_t task = mach_task_self();
    kern_return_t err;
    
    err = vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (err == KERN_SUCCESS) {
        memcpy((void *)address, bytes, size);
        vm_protect(task, (vm_address_t)address, size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// =====================================================================
// HOOK FUNCTIONS DÙNG OFFSET TỰ TÌM
// =====================================================================
static void updateGameSpeedHack() {
    uintptr_t base = get_Framework_Base_Address();
    if (base == 0 || g_playerSpeedOffset == 0) return;
    
    uintptr_t speedAddress = base + g_playerSpeedOffset;
    if (isHighSpeed && isKeyValidated) {
        uint32_t patchBytes[] = {0x528003c0, 0xD65F03C0};
        patchMemory(speedAddress, patchBytes, sizeof(patchBytes));
    } else {
        uint32_t originalBytes[] = {0xaa0003e0, 0xd65f03c0};
        patchMemory(speedAddress, originalBytes, sizeof(originalBytes));
    }
}

static void updateGodModeHack() {
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
static UIWindowScene* getActiveWindowScene() {
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
static void loadSavedModSettings() {
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
    } else {
        isAimbotActive = NO;
        isEspActive = NO;
        isGodMode = NO;
        isHighSpeed = NO;
    }
}

static void saveAllModSettingsToDevice() {
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
    
    [self updateThemeColors];
    
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
    if (accentColorIndex == 0) {
        menuAccentColor = [UIColor colorWithRed:1.0 green:0.32 blue:0.18 alpha:1.0];
    } else if (accentColorIndex == 1) {
        menuAccentColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.3 alpha:1.0];
    } else {
        menuAccentColor = [UIColor colorWithRed:0.0 green:0.47 blue:1.0 alpha:1.0];
    }
    
    if (espColorIndex == 0) {
        espColor = [UIColor redColor];
    } else if (espColorIndex == 1) {
        espColor = [UIColor greenColor];
    } else {
        espColor = [UIColor yellowColor];
    }
}

- (void)updateMenuContainerStyle {
    if (menuStyleCorner == 1) {
        menuContainer.layer.cornerRadius = 16.0f;
        self.sidebar.layer.cornerRadius = 16.0f;
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.sidebar.bounds
                                                       byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerBottomLeft)
                                                             cornerRadii:CGSizeMake(16, 16)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.sidebar.bounds;
        maskLayer.path = maskPath.CGPath;
        self.sidebar.layer.mask = maskLayer;
    } else {
        menuContainer.layer.cornerRadius = 0.0f;
        self.sidebar.layer.cornerRadius = 0.0f;
        self.sidebar.layer.mask = nil;
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
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    toast.textColor = [UIColor whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
    toast.text = msg;
    toast.layer.cornerRadius = 10;
    toast.layer.masksToBounds = YES;
    toast.layer.borderWidth = 1;
    toast.layer.borderColor = menuAccentColor.CGColor;
    [self.view addSubview:toast];
    
    [UIView animateWithDuration:0.3 delay:1.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        toast.alpha = 0.0;
    } completion:^(BOOL finished) {
        [toast removeFromSuperview];
    }];
}

- (void)renderActiveTabScreen:(NSInteger)idx {
    for (UIView *sub in self.scrollView.subviews) {
        [sub removeFromSuperview];
    }
    
    CGFloat y = 10;
    
    if (idx == 0) {
        // TAB 0: AIMBOT
        UILabel *secHeader = [self buildSectionHeader:isVietnamese ? @"MỤC TIÊU & AIMBOT" : @"AIMBOT LOCATIONS"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *aimSw = [self buildSwitchRow:isVietnamese ? @"Bật khóa mục tiêu" : @"Enable Aimbot Lock" state:isAimbotActive action:^(BOOL isOn) {
            isAimbotActive = isOn;
        }];
        aimSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:aimSw];
        y += 55;
        
        UILabel *aimPosLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 140, 30)];
        aimPosLbl.text = isVietnamese ? @"Tọa độ khóa tâm:" : @"Aim Focus Area:";
        aimPosLbl.textColor = [UIColor whiteColor];
        aimPosLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:aimPosLbl];
        
        UISegmentedControl *posSeg = [[UISegmentedControl alloc] initWithItems:@[@"Đầu", @"Cổ", @"Ngực", @"Bụng"]];
        posSeg.frame = CGRectMake(160, y, 230, 30);
        posSeg.selectedSegmentIndex = [aimTargetPosition isEqualToString:@"Đầu"] ? 0 : ([aimTargetPosition isEqualToString:@"Cổ"] ? 1 : ([aimTargetPosition isEqualToString:@"Ngực"] ? 2 : 3));
        if (@available(iOS 13.0, *)) {
            posSeg.selectedSegmentTintColor = menuAccentColor;
        }
        [posSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [posSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [posSeg addTarget:self action:@selector(posSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:posSeg];
        y += 45;
        
        UILabel *modeLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 140, 30)];
        modeLbl.text = isVietnamese ? @"Cơ chế hoạt động:" : @"Aim Trigger Style:";
        modeLbl.textColor = [UIColor whiteColor];
        modeLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:modeLbl];
        
        UISegmentedControl *modeSeg = [[UISegmentedControl alloc] initWithItems:@[isVietnamese ? @"Bắn mới ghim" : @"On Fire", isVietnamese ? @"Luôn ghim" : @"Always Locked"]];
        modeSeg.frame = CGRectMake(160, y, 230, 30);
        modeSeg.selectedSegmentIndex = isAimbotAlways ? 1 : 0;
        if (@available(iOS 13.0, *)) {
            modeSeg.selectedSegmentTintColor = menuAccentColor;
        }
        [modeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [modeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [modeSeg addTarget:self action:@selector(modeSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:modeSeg];
        y += 45;
        
        UIView *wallCheckSw = [self buildSwitchRow:isVietnamese ? @"Ghim xuyên qua tường" : @"Aim Through Obstacles" state:isAimThroughWall action:^(BOOL isOn) {
            isAimThroughWall = isOn;
        }];
        wallCheckSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:wallCheckSw];
        y += 55;
        
        UIView *fovSw = [self buildSwitchRow:isVietnamese ? @"Hiển thị vòng tròn tâm ngắm FOV" : @"Draw Visual FOV Circle" state:showFovCircle action:^(BOOL isOn) {
            showFovCircle = isOn;
            [HuyMenuController drawFovCircleOnScreen];
        }];
        fovSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:fovSw];
        y += 55;
        
        UIView *fovSlider = [self buildSliderRow:isVietnamese ? @"Bán kính vòng ngắm" : @"Adjust FOV Radius" val:aimbotFovRadius min:30 max:300 unit:@"px" action:^(float newVal) {
            aimbotFovRadius = newVal;
            [HuyMenuController drawFovCircleOnScreen];
        }];
        fovSlider.frame = CGRectMake(0, y, 410, 65);
        [self.scrollView addSubview:fovSlider];
        y += 75;
        
    } else if (idx == 1) {
        // TAB 1: ESP
        UILabel *secHeader = [self buildSectionHeader:isVietnamese ? @"XUYÊN TƯỜNG ĐỊNH VỊ (ESP)" : @"WALL ESP CONFIGURATION"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *espSw = [self buildSwitchRow:isVietnamese ? @"Bật tia quét ESP" : @"Enable Wall ESP" state:isEspActive action:^(BOOL isOn) {
            isEspActive = isOn;
        }];
        espSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espSw];
        y += 55;
        
        UIView *espLin = [self buildSwitchRow:isVietnamese ? @"Định hướng đường kẻ (Lines)" : @"Draw Direct Lines" state:isEspLines action:^(BOOL isOn) {
            isEspLines = isOn;
        }];
        espLin.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espLin];
        y += 55;
        
        UIView *espBox = [self buildSwitchRow:isVietnamese ? @"Vẽ Hộp 3D (Boxes)" : @"ESP Boxes" state:isEspBoxes action:^(BOOL isOn) {
            isEspBoxes = isOn;
        }];
        espBox.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espBox];
        y += 55;
        
        UIView *espSke = [self buildSwitchRow:isVietnamese ? @"Vẽ khung xương (Skeleton)" : @"ESP Skeleton" state:isEspSkeleton action:^(BOOL isOn) {
            isEspSkeleton = isOn;
        }];
        espSke.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espSke];
        y += 55;
        
        UILabel *colorLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 150, 30)];
        colorLbl.text = isVietnamese ? @"Màu sắc vẽ ESP:" : @"ESP Color Theme:";
        colorLbl.textColor = [UIColor whiteColor];
        colorLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:colorLbl];
        
        UISegmentedControl *colorSeg = [[UISegmentedControl alloc] initWithItems:@[@"Đỏ", @"Xanh lá", @"Vàng"]];
        colorSeg.frame = CGRectMake(160, y, 230, 30);
        colorSeg.selectedSegmentIndex = espColorIndex;
        if (@available(iOS 13.0, *)) {
            colorSeg.selectedSegmentTintColor = menuAccentColor;
        }
        [colorSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [colorSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [colorSeg addTarget:self action:@selector(espColorChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:colorSeg];
        y += 45;
        
        UIView *distSlider = [self buildSliderRow:isVietnamese ? @"Giới hạn khoảng cách hiển thị" : @"Max Render Distance" val:espMaxDistance min:50 max:1000 unit:@"m" action:^(float newVal) {
            espMaxDistance = newVal;
        }];
        distSlider.frame = CGRectMake(0, y, 410, 65);
        [self.scrollView addSubview:distSlider];
        y += 75;
        
    } else if (idx == 2) {
        // TAB 2: CHỨC NĂNG
        UILabel *secHeader = [self buildSectionHeader:isVietnamese ? @"TINH CHỈNH NHÂN VẬT & GAME" : @"CHARACTER & GAMEPLAY MOD"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *godSw = [self buildSwitchRow:isVietnamese ? @"Bất tử (God Mode)" : @"God Mode (Infinite Health)" state:isGodMode action:^(BOOL isOn) {
            isGodMode = isOn;
            updateGodModeHack();
        }];
        godSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:godSw];
        y += 55;
        
        UIView *spdSw = [self buildSwitchRow:isVietnamese ? @"Chạy siêu nhanh" : @"Super Sprint Speed" state:isHighSpeed action:^(BOOL isOn) {
            isHighSpeed = isOn;
            updateGameSpeedHack();
        }];
        spdSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:spdSw];
        y += 55;
        
        UIView *fovCam = [self buildSliderRow:isVietnamese ? @"Góc nhìn rộng phía sau (FOV)" : @"Expand Camera FOV" val:cameraFov min:60 max:130 unit:@"°" action:^(float newVal) {
            cameraFov = newVal;
        }];
        fovCam.frame = CGRectMake(0, y, 410, 65);
        [self.scrollView addSubview:fovCam];
        y += 75;
        
        UILabel *killHeader = [self buildSectionHeader:isVietnamese ? @"TÁC VỤ DIỆT BÀ NGOẠI & GỌI ĐỒ" : @"AI KILL & ITEM SPAWNER"];
        [self.scrollView addSubview:killHeader];
        y += 35;
        
        UIButton *killBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        killBtn.frame = CGRectMake(10, y, 380, 45);
        killBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
        killBtn.layer.cornerRadius = 8;
        [killBtn setTitle:isVietnamese ? @"💀 TIÊU DIỆT HOÀN TOÀN BÀ NGOẠI" : @"💀 ELIMINATE GRANNY AI" forState:UIControlStateNormal];
        [killBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        killBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [killBtn addTarget:self action:@selector(killGrannyCommand) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:killBtn];
        y += 55;
        
        UILabel *spawnLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 140, 30)];
        spawnLabel.text = isVietnamese ? @"Chọn đồ vật rơi:" : @"Select Drop Item:";
        spawnLabel.textColor = [UIColor whiteColor];
        spawnLabel.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:spawnLabel];
        
        UIButton *selectItemBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        selectItemBtn.frame = CGRectMake(160, y, 230, 30);
        selectItemBtn.backgroundColor = [UIColor colorWithRed:0.12 green:0.15 blue:0.22 alpha:1.0];
        selectItemBtn.layer.cornerRadius = 6;
        selectItemBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
        selectItemBtn.layer.borderWidth = 1;
        [selectItemBtn setTitle:[NSString stringWithFormat:@"📦 %@", selectedItemToSpawn] forState:UIControlStateNormal];
        [selectItemBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.55 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
        [selectItemBtn addTarget:self action:@selector(showItemSelectionMenu:) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:selectItemBtn];
        y += 40;
        
        UIButton *spawnActionBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        spawnActionBtn.frame = CGRectMake(10, y, 380, 40);
        spawnActionBtn.backgroundColor = menuAccentColor;
        spawnActionBtn.layer.cornerRadius = 8;
        [spawnActionBtn setTitle:isVietnamese ? @"💥 TRIỆU HỒI VẬT PHẨM TRƯỚC MẮT" : @"💥 SPAWN SELECTED ITEM" forState:UIControlStateNormal];
        [spawnActionBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        spawnActionBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        [spawnActionBtn addTarget:self action:@selector(executeSpawnAction) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:spawnActionBtn];
        y += 55;
        
        UILabel *uiHeader = [self buildSectionHeader:isVietnamese ? @"CẤU HÌNH PHONG CÁCH GIAO DIỆN" : @"UI INTERFACE THEME"];
        [self.scrollView addSubview:uiHeader];
        y += 35;
        
        UILabel *langLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 140, 30)];
        langLbl.text = isVietnamese ? @"Lựa chọn ngôn ngữ:" : @"Select Language:";
        langLbl.textColor = [UIColor whiteColor];
        langLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:langLbl];
        
        UISegmentedControl *langSeg = [[UISegmentedControl alloc] initWithItems:@[@"Tiếng Việt", @"English"]];
        langSeg.frame = CGRectMake(160, y, 230, 30);
        langSeg.selectedSegmentIndex = isVietnamese ? 0 : 1;
        if (@available(iOS 13.0, *)) {
            langSeg.selectedSegmentTintColor = menuAccentColor;
        }
        [langSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [langSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [langSeg addTarget:self action:@selector(langSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:langSeg];
        y += 45;
        
        UILabel *themeColorLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 140, 30)];
        themeColorLbl.text = isVietnamese ? @"Màu chính phát sáng:" : @"Menu Main Accent:";
        themeColorLbl.textColor = [UIColor whiteColor];
        themeColorLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:themeColorLbl];
        
        UISegmentedControl *themeSeg = [[UISegmentedControl alloc] initWithItems:@[@"Cam", @"Xanh lá", @"Xanh dương"]];
        themeSeg.frame = CGRectMake(160, y, 230, 30);
        themeSeg.selectedSegmentIndex = accentColorIndex;
        if (@available(iOS 13.0, *)) {
            themeSeg.selectedSegmentTintColor = menuAccentColor;
        }
        [themeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [themeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [themeSeg addTarget:self action:@selector(themeSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:themeSeg];
        y += 45;
        
        UILabel *styleLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 140, 30)];
        styleLbl.text = isVietnamese ? @"Kiểu góc của Menu:" : @"Menu Edge Corner:";
        styleLbl.textColor = [UIColor whiteColor];
        styleLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:styleLbl];
        
        UISegmentedControl *styleSeg = [[UISegmentedControl alloc] initWithItems:@[isVietnamese ? @"Góc vuông" : @"Flat Square", isVietnamese ? @"Góc tròn" : @"Rounded Corner"]];
        styleSeg.frame = CGRectMake(160, y, 230, 30);
        styleSeg.selectedSegmentIndex = menuStyleCorner;
        if (@available(iOS 13.0, *)) {
            styleSeg.selectedSegmentTintColor = menuAccentColor;
        }
        [styleSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [styleSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [styleSeg addTarget:self action:@selector(styleSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:styleSeg];
        y += 50;
        
    } else if (idx == 3) {
        // TAB 3: TÀI KHOẢN
        UILabel *secHeader = [self buildSectionHeader:isVietnamese ? @"QUẢN LÝ BẢN QUYỀN KEY" : @"ACTIVE VIP CONTRACT"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(10, y, 380, 180)];
        card.backgroundColor = [UIColor colorWithRed:0.1 green:0.12 blue:0.18 alpha:0.4];
        card.layer.borderColor = menuAccentColor.CGColor;
        card.layer.borderWidth = 1.0;
        card.layer.cornerRadius = 10;
        
        userLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 350, 20)];
        userLabel.text = [NSString stringWithFormat:@"%@: %@", isVietnamese ? @"Người sở hữu" : @"Owner", usernameInfo];
        userLabel.textColor = [UIColor whiteColor];
        userLabel.font = [UIFont boldSystemFontOfSize:14];
        [card addSubview:userLabel];
        
        keyDisplayLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 45, 350, 20)];
        keyDisplayLabel.text = [NSString stringWithFormat:@"License Key: %@", currentActiveKey];
        keyDisplayLabel.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
        keyDisplayLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
        [card addSubview:keyDisplayLabel];
        
        NSDate *expDate = [NSDate dateWithTimeIntervalSince1970:keyExpirationTimestamp];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        UILabel *exactExpLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 75, 350, 20)];
        exactExpLabel.text = [NSString stringWithFormat:@"%@: %@", isVietnamese ? @"Hết hạn lúc" : @"Expired date", [formatter stringFromDate:expDate]];
        exactExpLabel.textColor = [UIColor lightGrayColor];
        exactExpLabel.font = [UIFont systemFontOfSize:11];
        [card addSubview:exactExpLabel];
        
        countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 110, 350, 25)];
        countdownLabel.textColor = [UIColor greenColor];
        countdownLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
        [card addSubview:countdownLabel];
        
        [self.scrollView addSubview:card];
        y += 195;
        
        [self updateCountdownRealtime];
        
        UIButton *saveSettingsBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        saveSettingsBtn.frame = CGRectMake(10, y, 380, 45);
        saveSettingsBtn.backgroundColor = menuAccentColor;
        saveSettingsBtn.layer.cornerRadius = 8;
        [saveSettingsBtn setTitle:isVietnamese ? @"💾 LƯU CẤU HÌNH MOD HIỆN TẠI" : @"💾 SAVE CURRENT SETTINGS" forState:UIControlStateNormal];
        [saveSettingsBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        saveSettingsBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [saveSettingsBtn addTarget:self action:@selector(saveSettingsAction) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:saveSettingsBtn];
        y += 55;
        
        UIButton *unlinkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        unlinkBtn.frame = CGRectMake(10, y, 380, 45);
        unlinkBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.1 blue:0.1 alpha:0.15];
        unlinkBtn.layer.borderColor = [UIColor redColor].CGColor;
        unlinkBtn.layer.borderWidth = 1;
        unlinkBtn.layer.cornerRadius = 8;
        [unlinkBtn setTitle:isVietnamese ? @"🔴 ĐĂNG XUẤT / GỠ KEY KHỎI MÁY" : @"🔴 REMOVE LICENCE KEY" forState:UIControlStateNormal];
        [unlinkBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        unlinkBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [unlinkBtn addTarget:self action:@selector(unlinkKeyAction) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:unlinkBtn];
        y += 55;
    }
    
    self.scrollView.contentSize = CGSizeMake(410, y + 20);
}

- (void)saveSettingsAction {
    saveAllModSettingsToDevice();
    [self showToast:isVietnamese ? @"Đã lưu thiết lập thành công!" : @"All configurations successfully saved!"];
}

- (void)unlinkKeyAction {
    isKeyValidated = NO;
    currentActiveKey = @"";
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"huy_saved_activation_key"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (countdownTimer) {
        [countdownTimer invalidate];
    }
    
    mainModPanel.hidden = YES;
    authPanel.hidden = NO;
    menuContainer.hidden = NO;
    [self showToast:isVietnamese ? @"Đã hủy liên kết Key!" : @"Key removed!"];
}

- (void)killGrannyCommand {
    Class grannyClass = objc_getClass("GrannyAI");
    if (!grannyClass) grannyClass = objc_getClass("EnemyAI");
    if (!grannyClass) grannyClass = objc_getClass("AIController");
    
    if (grannyClass) {
        id unityEngine = NSClassFromString(@"UnityEngine");
        if (unityEngine) {
            SEL findSel = NSSelectorFromString(@"FindObjectsOfType:");
            if ([unityEngine respondsToSelector:findSel]) {
                NSArray *grannies = [unityEngine performSelector:findSel withObject:grannyClass];
                if (grannies && grannies.count > 0) {
                    for (id granny in grannies) {
                        if ([granny respondsToSelector:NSSelectorFromString(@"Die")]) {
                            [granny performSelector:NSSelectorFromString(@"Die")];
                        }
                        if ([granny respondsToSelector:NSSelectorFromString(@"setHealth:")]) {
                            [granny performSelector:NSSelectorFromString(@"setHealth:") withObject:@0];
                        }
                    }
                    [self showToast:isVietnamese ? @"💀 Đã tiêu diệt bà ngoại!" : @"💀 Granny eliminated!"];
                    return;
                }
            }
        }
        [self showToast:isVietnamese ? @"❌ Không tìm thấy bà ngoại!" : @"❌ Granny not found!"];
    } else {
        [self showToast:isVietnamese ? @"❌ Chưa tìm thấy class Granny!" : @"❌ Granny class not found!"];
    }
}

- (void)showItemSelectionMenu:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:isVietnamese ? @"CHỌN VẬT PHẨM TRIỆU HỒI" : @"CHOOSE SPAWN OBJECT" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    NSArray *items = @[@"Shotgun", @"Búa gỗ", @"Chìa khóa Xe", @"Bình xăng", @"Tay quay nước", @"Dưa hấu"];
    
    for (NSString *item in items) {
        [alert addAction:[UIAlertAction actionWithTitle:item style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            selectedItemToSpawn = item;
            [sender setTitle:[NSString stringWithFormat:@"📦 %@", item] forState:UIControlStateNormal];
        }]];
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:isVietnamese ? @"Hủy bỏ" : @"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    alert.popoverPresentationController.sourceView = sender;
    alert.popoverPresentationController.sourceRect = sender.bounds;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)executeSpawnAction {
    Class itemClass = objc_getClass("Item");
    if (!itemClass) itemClass = objc_getClass("PickupItem");
    
    if (itemClass) {
        id unityEngine = NSClassFromString(@"UnityEngine");
        if (unityEngine) {
            SEL findSel = NSSelectorFromString(@"FindObjectsOfType:");
            if ([unityEngine respondsToSelector:findSel]) {
                NSArray *items = [unityEngine performSelector:findSel withObject:itemClass];
                for (id item in items) {
                    NSString *itemName = [item valueForKey:@"name"];
                    if ([itemName containsString:selectedItemToSpawn]) {
                        Class playerClass = objc_getClass("PlayerController");
                        if (!playerClass) playerClass = objc_getClass("Player");
                        if (playerClass) {
                            NSArray *players = [unityEngine performSelector:findSel withObject:playerClass];
                            if (players && players.count > 0) {
                                id player = players[0];
                                SEL transformSel = NSSelectorFromString(@"get_transform");
                                id playerTransform = [player performSelector:transformSel];
                                if (playerTransform) {
                                    SEL posSel = NSSelectorFromString(@"get_position");
                                    id playerPos = [playerTransform performSelector:posSel];
                                    if (playerPos) {
                                        id itemTransform = [item performSelector:transformSel];
                                        if (itemTransform) {
                                            SEL setPosSel = NSSelectorFromString(@"set_position:");
                                            if ([itemTransform respondsToSelector:setPosSel]) {
                                                [itemTransform performSelector:setPosSel withObject:playerPos];
                                                [self showToast:[NSString stringWithFormat:isVietnamese ? @"✅ Đã triệu hồi [%@]!" : @"✅ [%@] spawned!", selectedItemToSpawn]];
                                                return;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
            }
        }
        [self showToast:[NSString stringWithFormat:isVietnamese ? @"📦 Đã triệu hồi [%@]!" : @"📦 [%@] spawned!", selectedItemToSpawn]];
    } else {
        [self showToast:isVietnamese ? @"⚠️ Không tìm thấy class Item!" : @"⚠️ Item class not found!"];
    }
}

- (void)posSegChanged:(UISegmentedControl *)sender {
    NSArray *pos = @[@"Đầu", @"Cổ", @"Ngực", @"Bụng"];
    aimTargetPosition = pos[sender.selectedSegmentIndex];
}

- (void)modeSegChanged:(UISegmentedControl *)sender {
    isAimbotAlways = (sender.selectedSegmentIndex == 1);
}

- (void)espColorChanged:(UISegmentedControl *)sender {
    espColorIndex = sender.selectedSegmentIndex;
    [self updateThemeColors];
}

- (void)langSegChanged:(UISegmentedControl *)sender {
    isVietnamese = (sender.selectedSegmentIndex == 0);
    [self buildSidebarTabs];
    [self renderActiveTabScreen:2];
}

- (void)themeSegChanged:(UISegmentedControl *)sender {
    accentColorIndex = sender.selectedSegmentIndex;
    [self updateThemeColors];
    menuContainer.layer.borderColor = menuAccentColor.CGColor;
    [self buildSidebarTabs];
    [self renderActiveTabScreen:2];
}

- (void)styleSegChanged:(UISegmentedControl *)sender {
    menuStyleCorner = sender.selectedSegmentIndex;
    [self updateMenuContainerStyle];
}

- (UILabel *)buildSectionHeader:(NSString *)title {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 380, 25)];
    lbl.text = title;
    lbl.textColor = menuAccentColor;
    lbl.font = [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:14];
    return lbl;
}

- (UIView *)buildSwitchRow:(NSString *)title state:(BOOL)isOn action:(void (^)(BOOL))callback {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 410, 45)];
    view.backgroundColor = [UIColor colorWithRed:0.09 green:0.11 blue:0.16 alpha:0.5];
    view.layer.cornerRadius = 8;
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 7, 280, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [view addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(335, 7, 50, 30)];
    sw.onTintColor = menuAccentColor;
    sw.on = isOn;
    
    objc_setAssociatedObject(sw, "callback", callback, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [sw addTarget:self action:@selector(switchTriggered:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:sw];
    
    return view;
}

- (void)switchTriggered:(UISwitch *)sender {
    void (^callback)(BOOL) = objc_getAssociatedObject(sender, "callback");
    if (callback) {
        callback(sender.on);
    }
}

- (UIView *)buildSliderRow:(NSString *)title val:(float)val min:(float)min max:(float)max unit:(NSString *)unit action:(void (^)(float))callback {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 410, 65)];
    view.backgroundColor = [UIColor colorWithRed:0.09 green:0.11 blue:0.16 alpha:0.5];
    view.layer.cornerRadius = 8;
    
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 5, 200, 20)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:13];
    [view addSubview:lbl];
    
    UILabel *valLbl = [[UILabel alloc] initWithFrame:CGRectMake(280, 5, 100, 20)];
    valLbl.text = [NSString stringWithFormat:@"%.0f%@", val, unit];
    valLbl.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    valLbl.textAlignment = NSTextAlignmentRight;
    valLbl.font = [UIFont fontWithName:@"Courier-Bold" size:13];
    [view addSubview:valLbl];
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(15, 30, 370, 30)];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = val;
    slider.minimumTrackTintColor = menuAccentColor;
    slider.maximumTrackTintColor = [UIColor darkGrayColor];
    
    objc_setAssociatedObject(slider, "callback", callback, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(slider, "label", valLbl, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(slider, "unit", unit, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:slider];
    
    return view;
}

- (void)sliderMoved:(UISlider *)sender {
    void (^callback)(float) = objc_getAssociatedObject(sender, "callback");
    UILabel *lbl = objc_getAssociatedObject(sender, "label");
    NSString *unit = objc_getAssociatedObject(sender, "unit");
    if (callback) callback(sender.value);
    if (lbl) lbl.text = [NSString stringWithFormat:@"%.0f%@", sender.value, unit];
}

+ (void)drawFovCircleOnScreen {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (fovCircleLayer) {
            [fovCircleLayer removeFromSuperlayer];
            fovCircleLayer = nil;
        }
        
        if (!overlayMenuWindow || !showFovCircle) return;
        
        CGPoint center = overlayMenuWindow.center;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:aimbotFovRadius startAngle:0 endAngle:2 * M_PI clockwise:YES];
        
        fovCircleLayer = [CAShapeLayer layer];
        fovCircleLayer.path = path.CGPath;
        fovCircleLayer.fillColor = [UIColor clearColor].CGColor;
        fovCircleLayer.strokeColor = menuAccentColor.CGColor;
        fovCircleLayer.lineWidth = 1.0f;
        fovCircleLayer.opacity = 0.6f;
        
        [overlayMenuWindow.layer addSublayer:fovCircleLayer];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

// =====================================================================
// KHỞI CHẠY GIAO DIỆN & LOGO 🕵️‍♂️
// =====================================================================
@interface HuyMenuInitializer : NSObject
+ (void)tryInitializeUI;
@end

@implementation HuyMenuInitializer

+ (void)tryInitializeUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindowScene *scene = nil;
        
        if (@available(iOS 13.0, *)) {
            scene = getActiveWindowScene();
            if (!scene) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [HuyMenuInitializer tryInitializeUI];
                });
                return;
            }
        }
        
        // CỬA SỔ NỔI LOGO 🕵️‍♂️
        if (@available(iOS 13.0, *)) {
            floatingButtonWindow = [[UIWindow alloc] initWithWindowScene:scene];
        } else {
            floatingButtonWindow = [[UIWindow alloc] initWithFrame:CGRectMake(20, 180, 56, 56)];
        }
        floatingButtonWindow.frame = CGRectMake(20, 180, 56, 56);
        floatingButtonWindow.backgroundColor = [UIColor clearColor];
        floatingButtonWindow.windowLevel = UIWindowLevelAlert + 1001;
        
        UIViewController *btnRootVC = [[UIViewController alloc] init];
        btnRootVC.view.backgroundColor = [UIColor clearColor];
        floatingButtonWindow.rootViewController = btnRootVC;
        
        floatingLogoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        floatingLogoBtn.frame = btnRootVC.view.bounds;
        floatingLogoBtn.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        floatingLogoBtn.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.11 alpha:0.9];
        floatingLogoBtn.layer.cornerRadius = 28;
        floatingLogoBtn.layer.borderWidth = 1.5;
        floatingLogoBtn.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor;
        
        [floatingLogoBtn setTitle:@"🕵️‍♂️" forState:UIControlStateNormal];
        floatingLogoBtn.titleLabel.font = [UIFont systemFontOfSize:28];
        
        floatingLogoBtn.layer.shadowColor = [UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:1.0].CGColor;
        floatingLogoBtn.layer.shadowOffset = CGSizeZero;
        floatingLogoBtn.layer.shadowRadius = 8;
        floatingLogoBtn.layer.shadowOpacity = 0.9;
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleFloatingPan:)];
        [floatingLogoBtn addGestureRecognizer:pan];
        
        [floatingLogoBtn addTarget:self action:@selector(toggleHuyMenuViaLogo) forControlEvents:UIControlEventTouchUpInside];
        [btnRootVC.view addSubview:floatingLogoBtn];
        floatingButtonWindow.hidden = NO;

        // CỬA SỔ MENU TRONG SUỐT
        if (@available(iOS 13.0, *)) {
            overlayMenuWindow = [[HuyPassthroughWindow alloc] initWithWindowScene:scene];
        } else {
            overlayMenuWindow = [[HuyPassthroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }
        overlayMenuWindow.frame = [UIScreen mainScreen].bounds;
        overlayMenuWindow.backgroundColor = [UIColor clearColor];
        overlayMenuWindow.windowLevel = UIWindowLevelAlert + 1000;
        
        HuyMenuController *controller = [[HuyMenuController alloc] init];
        overlayMenuWindow.rootViewController = controller;
        overlayMenuWindow.hidden = NO;
    });
}

+ (void)handleFloatingPan:(UIPanGestureRecognizer *)gesture {
    UIView *btn = gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        floatingButtonWindow.center = CGPointMake(floatingButtonWindow.center.x + translation.x, floatingButtonWindow.center.y + translation.y);
        [gesture setTranslation:CGPointZero inView:btn.superview];
    }
}

+ (void)toggleHuyMenuViaLogo {
    [HuyMenuController toggleMenuGlobal];
}

@end

// =====================================================================
// HÀM KHỞI CHẠY CHÍNH
// =====================================================================
__attribute__((constructor)) static void initialize() {
    loadSavedModSettings();
    
    // ====== TỰ ĐỘNG TÌM OFFSET ======
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        autoFindAllOffsets();
    });
    
    Method originalMethod = class_getInstanceMethod([UIWindow class], @selector(sendEvent:));
    if (originalMethod) {
        orig_UIWindow_sendEvent = (void *)method_getImplementation(originalMethod);
        method_setImplementation(originalMethod, (IMP)custom_UIWindow_sendEvent);
    }
    
    if ([UIApplication sharedApplication].keyWindow || [[UIApplication sharedApplication] windows].count > 0) {
        [HuyMenuInitializer tryInitializeUI];
    } else {
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [HuyMenuInitializer tryInitializeUI];
        }];
    }
}
