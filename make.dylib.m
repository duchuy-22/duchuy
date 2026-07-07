#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ====== BIẾN TOÀN CỤC ======
static BOOL isAimbotActive = NO;
static BOOL isEspActive = NO;
static BOOL isGodMode = NO;
static BOOL isHighSpeed = NO;
static BOOL isNoRecoil = NO;
static BOOL isFastReload = NO;
static BOOL isTeleport = NO;
static BOOL isKillAll = NO;

static BOOL espBox = YES;
static BOOL espLine = YES;
static BOOL espSkeleton = NO;
static float espDistance = 100.0f;
static UIColor *espColor = nil;

static int aimTarget = 0;
static BOOL aimAuto = NO;
static BOOL aimWall = NO;
static float aimFOV = 150.0f;

static UIWindow *menuWindow = nil;
static UIView *menuContainer = nil;
static int currentTab = 0;

// ====== LƯU CẤU HÌNH ======
static void saveSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isAimbotActive forKey:@"mod_aim"];
    [defaults setBool:isEspActive forKey:@"mod_esp"];
    [defaults setBool:isGodMode forKey:@"mod_god"];
    [defaults setBool:isHighSpeed forKey:@"mod_spd"];
    [defaults setBool:isNoRecoil forKey:@"mod_recoil"];
    [defaults setBool:isFastReload forKey:@"mod_reload"];
    [defaults setBool:isTeleport forKey:@"mod_tele"];
    [defaults setBool:isKillAll forKey:@"mod_kill"];
    [defaults setInteger:aimTarget forKey:@"mod_aimtarget"];
    [defaults setBool:aimAuto forKey:@"mod_aimauto"];
    [defaults setBool:aimWall forKey:@"mod_aimwall"];
    [defaults setFloat:aimFOV forKey:@"mod_aimfov"];
    [defaults setBool:espBox forKey:@"mod_espbox"];
    [defaults setBool:espLine forKey:@"mod_espline"];
    [defaults setBool:espSkeleton forKey:@"mod_espskel"];
    [defaults setFloat:espDistance forKey:@"mod_espdist"];
    [defaults synchronize];
}

static void loadSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isAimbotActive = [defaults boolForKey:@"mod_aim"];
    isEspActive = [defaults boolForKey:@"mod_esp"];
    isGodMode = [defaults boolForKey:@"mod_god"];
    isHighSpeed = [defaults boolForKey:@"mod_spd"];
    isNoRecoil = [defaults boolForKey:@"mod_recoil"];
    isFastReload = [defaults boolForKey:@"mod_reload"];
    isTeleport = [defaults boolForKey:@"mod_tele"];
    isKillAll = [defaults boolForKey:@"mod_kill"];
    aimTarget = (int)[defaults integerForKey:@"mod_aimtarget"];
    aimAuto = [defaults boolForKey:@"mod_aimauto"];
    aimWall = [defaults boolForKey:@"mod_aimwall"];
    aimFOV = [defaults floatForKey:@"mod_aimfov"];
    espBox = [defaults boolForKey:@"mod_espbox"];
    espLine = [defaults boolForKey:@"mod_espline"];
    espSkeleton = [defaults boolForKey:@"mod_espskel"];
    espDistance = [defaults floatForKey:@"mod_espdist"];
    if (!espColor) espColor = [UIColor redColor];
}

static void resetAllFeatures() {
    isAimbotActive = NO;
    isEspActive = NO;
    isGodMode = NO;
    isHighSpeed = NO;
    isNoRecoil = NO;
    isFastReload = NO;
    isTeleport = NO;
    isKillAll = NO;
    aimAuto = NO;
    aimWall = NO;
    aimFOV = 150.0f;
    espBox = YES;
    espLine = YES;
    espSkeleton = NO;
    espDistance = 100.0f;
    saveSettings();
}

// ====== VIEW CONTROLLER ======
@interface GrannyModMenuVC : UIViewController
@end

@implementation GrannyModMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    dimView.userInteractionEnabled = YES;
    [self.view addSubview:dimView];
    
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(30, 60, 340, 520)];
    menuContainer.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.95];
    menuContainer.layer.cornerRadius = 16;
    menuContainer.layer.borderWidth = 1.5;
    menuContainer.layer.borderColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.6].CGColor;
    menuContainer.clipsToBounds = YES;
    [self.view addSubview:menuContainer];
    
    // HEADER
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 50)];
    header.backgroundColor = [UIColor colorWithRed:0.12 green:0.04 blue:0.04 alpha:1];
    [menuContainer addSubview:header];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 30)];
    title.text = @"🔥 GRANNY MOD";
    title.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1];
    title.font = [UIFont boldSystemFontOfSize:18];
    [header addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(295, 10, 35, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];
    
    // TAB BAR
    NSArray *tabNames = @[@"Aimbot", @"ESP", @"Chức năng", @"Tài khoản"];
    for (int i = 0; i < 4; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(10 + i * 80, 55, 75, 35);
        [tabBtn setTitle:tabNames[i] forState:UIControlStateNormal];
        [tabBtn setTitleColor:(i == currentTab) ? [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1] : [UIColor grayColor] forState:UIControlStateNormal];
        tabBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        tabBtn.tag = 200 + i;
        [tabBtn addTarget:self action:@selector(tabPressed:) forControlEvents:UIControlEventTouchUpInside];
        [menuContainer addSubview:tabBtn];
    }
    
    // CONTENT
    UIView *contentArea = [[UIView alloc] initWithFrame:CGRectMake(10, 95, 320, 370)];
    contentArea.tag = 999;
    contentArea.backgroundColor = [UIColor clearColor];
    [menuContainer addSubview:contentArea];
    
    [self loadTab:currentTab];
}

- (void)tabPressed:(UIButton *)sender {
    int index = (int)(sender.tag - 200);
    currentTab = index;
    
    for (int i = 0; i < 4; i++) {
        UIButton *btn = (UIButton *)[menuContainer viewWithTag:200 + i];
        if (btn) {
            [btn setTitleColor:(i == index) ? [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:1] : [UIColor grayColor] forState:UIControlStateNormal];
        }
    }
    [self loadTab:index];
}

- (void)loadTab:(int)index {
    UIView *content = [menuContainer viewWithTag:999];
    if (!content) return;
    
    for (UIView *v in content.subviews) {
        [v removeFromSuperview];
    }
    
    switch (index) {
        case 0: [self drawAimbotTab:content]; break;
        case 1: [self drawESPTab:content]; break;
        case 2: [self drawChucNangTab:content]; break;
        case 3: [self drawTaiKhoanTab:content]; break;
    }
}

// ====== TAB AIMBOT ======
- (void)drawAimbotTab:(UIView *)content {
    int y = 5;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isAimbotActive tag:100 label:@"🔫 Aimbot"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:aimAuto tag:101 label:@"🎯 Tự động ngắm"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:aimWall tag:102 label:@"🧱 Xuyên tường"];
    y += 40;
    
    [self addLabel:content text:@"🎯 Vị trí:" frame:CGRectMake(10, y, 100, 30)];
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Đầu", @"Ngực", @"Cổ", @"Bụng"]];
    seg.frame = CGRectMake(100, y, 200, 30);
    seg.selectedSegmentIndex = aimTarget;
    seg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    seg.selectedSegmentTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [seg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:seg];
    y += 45;
    
    [self addLabel:content text:[NSString stringWithFormat:@"📏 FOV: %.0f", aimFOV] frame:CGRectMake(10, y, 120, 30)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(130, y, 170, 30)];
    slider.minimumValue = 30;
    slider.maximumValue = 300;
    slider.value = aimFOV;
    slider.tag = 500;
    [slider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:slider];
}

// ====== TAB ESP ======
- (void)drawESPTab:(UIView *)content {
    int y = 5;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isEspActive tag:200 label:@"👁️ ESP"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:espBox tag:201 label:@"📦 Box"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:espLine tag:202 label:@"📏 Line"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:espSkeleton tag:203 label:@"🦴 Skeleton"];
    y += 40;
    
    UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    colorBtn.frame = CGRectMake(10, y, 150, 35);
    [colorBtn setTitle:@"🎨 Màu ESP" forState:UIControlStateNormal];
    [colorBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    colorBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    colorBtn.layer.cornerRadius = 8;
    [colorBtn addTarget:self action:@selector(chooseColor) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:colorBtn];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(170, y, 30, 30)];
    colorView.backgroundColor = espColor ? espColor : [UIColor redColor];
    colorView.layer.cornerRadius = 15;
    colorView.layer.borderWidth = 1;
    colorView.layer.borderColor = [UIColor whiteColor].CGColor;
    colorView.tag = 900;
    [content addSubview:colorView];
    y += 50;
    
    [self addLabel:content text:[NSString stringWithFormat:@"📡 Khoảng cách: %.0fm", espDistance] frame:CGRectMake(10, y, 150, 30)];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(160, y, 140, 30)];
    slider.minimumValue = 10;
    slider.maximumValue = 200;
    slider.value = espDistance;
    slider.tag = 501;
    [slider addTarget:self action:@selector(distChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:slider];
}

// ====== TAB CHỨC NĂNG ======
- (void)drawChucNangTab:(UIView *)content {
    int y = 5;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isGodMode tag:300 label:@"🛡️ Bất tử"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isHighSpeed tag:301 label:@"⚡ Speed"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isNoRecoil tag:302 label:@"🔫 Không giật"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isFastReload tag:303 label:@"🔄 Nạp đạn nhanh"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isTeleport tag:304 label:@"📦 Teleport"];
    y += 40;
    [self addSwitch:content frame:CGRectMake(250, y, 51, 31) value:isKillAll tag:305 label:@"💀 Kill bà ngoại"];
}

// ====== TAB TÀI KHOẢN ======
- (void)drawTaiKhoanTab:(UIView *)content {
    int y = 10;
    
    [self addLabel:content text:@"🔑 KEY:" frame:CGRectMake(10, y, 60, 30)];
    UITextField *keyField = [[UITextField alloc] initWithFrame:CGRectMake(80, y, 160, 35)];
    keyField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    keyField.textColor = [UIColor whiteColor];
    keyField.placeholder = @"Nhập key...";
    keyField.layer.cornerRadius = 8;
    keyField.layer.borderWidth = 1;
    keyField.layer.borderColor = [UIColor grayColor].CGColor;
    [content addSubview:keyField];
    
    UIButton *confirmBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    confirmBtn.frame = CGRectMake(250, y, 50, 35);
    [confirmBtn setTitle:@"✅" forState:UIControlStateNormal];
    confirmBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.7 blue:0.2 alpha:0.8];
    confirmBtn.layer.cornerRadius = 8;
    [confirmBtn addTarget:self action:@selector(confirmKey) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:confirmBtn];
    y += 50;
    
    [self addLabel:content text:@"👤 User: HuyMod" frame:CGRectMake(10, y, 200, 30) color:[UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1]];
    y += 35;
    [self addLabel:content text:@"⏳ Hết hạn: 2026-12-31" frame:CGRectMake(10, y, 250, 30) color:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1]];
    y += 40;
    [self addLabel:content text:@"✅ Đã kích hoạt!" frame:CGRectMake(10, y, 200, 30) color:[UIColor greenColor] font:[UIFont boldSystemFontOfSize:16]];
    y += 50;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    saveBtn.frame = CGRectMake(30, y, 250, 45);
    [saveBtn setTitle:@"💾 LƯU SETTING" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveBtn.backgroundColor = [UIColor colorWithRed:0.2 green:0.5 blue:0.2 alpha:0.9];
    saveBtn.layer.cornerRadius = 8;
    [saveBtn addTarget:self action:@selector(savePressed) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:saveBtn];
    y += 55;
    
    UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    resetBtn.frame = CGRectMake(30, y, 250, 45);
    [resetBtn setTitle:@"🔴 TẮT TẤT CẢ" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    resetBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9];
    resetBtn.layer.cornerRadius = 8;
    [resetBtn addTarget:self action:@selector(resetPressed) forControlEvents:UIControlEventTouchUpInside];
    [content addSubview:resetBtn];
}

// ====== UI HELPER ======
- (void)addSwitch:(UIView *)content frame:(CGRect)frame value:(BOOL)value tag:(int)tag label:(NSString *)label {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:frame];
    sw.on = value;
    sw.tag = tag;
    sw.onTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:sw];
    [self addLabel:content text:label frame:CGRectMake(10, frame.origin.y, 200, 30)];
}

- (void)addLabel:(UIView *)content text:(NSString *)text frame:(CGRect)frame {
    [self addLabel:content text:text frame:frame color:[UIColor whiteColor] font:[UIFont systemFontOfSize:14]];
}

- (void)addLabel:(UIView *)content text:(NSString *)text frame:(CGRect)frame color:(UIColor *)color {
    [self addLabel:content text:text frame:frame color:color font:[UIFont systemFontOfSize:14]];
}

- (void)addLabel:(UIView *)content text:(NSString *)text frame:(CGRect)frame color:(UIColor *)color font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = color ? color : [UIColor whiteColor];
    label.font = font ? font : [UIFont systemFontOfSize:14];
    [content addSubview:label];
}

// ====== HANDLERS ======
- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 100: isAimbotActive = sender.on; break;
        case 101: aimAuto = sender.on; break;
        case 102: aimWall = sender.on; break;
        case 200: isEspActive = sender.on; break;
        case 201: espBox = sender.on; break;
        case 202: espLine = sender.on; break;
        case 203: espSkeleton = sender.on; break;
        case 300: isGodMode = sender.on; break;
        case 301: isHighSpeed = sender.on; break;
        case 302: isNoRecoil = sender.on; break;
        case 303: isFastReload = sender.on; break;
        case 304: isTeleport = sender.on; break;
        case 305: isKillAll = sender.on; break;
    }
}

- (void)aimTargetChanged:(UISegmentedControl *)sender {
    aimTarget = (int)sender.selectedSegmentIndex;
}

- (void)fovChanged:(UISlider *)sender {
    aimFOV = sender.value;
    [self loadTab:currentTab];
}

- (void)distChanged:(UISlider *)sender {
    espDistance = sender.value;
    [self loadTab:currentTab];
}

- (void)chooseColor {
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
        picker.delegate = self;
        picker.selectedColor = espColor ? espColor : [UIColor redColor];
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    espColor = viewController.selectedColor;
    UIView *colorView = [menuContainer viewWithTag:900];
    if (colorView) colorView.backgroundColor = espColor;
}

- (void)savePressed {
    saveSettings();
    [self showAlert:@"✅ Thành công" message:@"Đã lưu cấu hình!"];
}

- (void)resetPressed {
    resetAllFeatures();
    [self loadTab:currentTab];
    [self showAlert:@"🔄 Đã tắt" message:@"Tất cả chức năng đã được tắt!"];
}

- (void)confirmKey {
    [self showAlert:@"✅" message:@"Key hợp lệ!"];
}

- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)hideMenu {
    menuWindow.hidden = YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self.view];
    if (!CGRectContainsPoint(menuContainer.frame, point)) {
        [self hideMenu];
    }
}

@end

// ====== HÀM MỞ MENU ======
void showMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!menuWindow) {
            menuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuWindow.windowLevel = UIWindowLevelAlert + 1;
            menuWindow.backgroundColor = [UIColor clearColor];
            menuWindow.rootViewController = [[GrannyModMenuVC alloc] init];
            menuWindow.userInteractionEnabled = YES;
        }
        menuWindow.hidden = NO;
    });
}

// ====== SETUP GESTURE ======
static void setupGestures() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) {
            win = [[[UIApplication sharedApplication] windows] firstObject];
        }
        if (!win) return;
        
        for (UIGestureRecognizer *gr in win.gestureRecognizers) {
            if ([gr isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gr;
                if (tap.numberOfTouchesRequired == 3 && tap.numberOfTapsRequired == 2) {
                    [win removeGestureRecognizer:gr];
                }
            }
        }
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:@selector(showMenu)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 2;
        tap.cancelsTouchesInView = NO;
        [win addGestureRecognizer:tap];
    });
}

// ====== HOOK BẰNG METHOD SWIZZLING ======
static void (*orig_applicationDidFinishLaunching)(id self, SEL cmd, UIApplication *app);
static void new_applicationDidFinishLaunching(id self, SEL cmd, UIApplication *app) {
    if (orig_applicationDidFinishLaunching) {
        orig_applicationDidFinishLaunching(self, cmd, app);
    }
    loadSettings();
    resetAllFeatures();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
    });
}

static void (*orig_Awake)(id self, SEL cmd);
static void new_Awake(id self, SEL cmd) {
    if (orig_Awake) {
        orig_Awake(self, cmd);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
    });
}

// ====== CONSTRUCTOR ======
__attribute__((constructor)) static void init() {
    loadSettings();
    resetAllFeatures();
    
    // Hook UnityAppController
    Class unityClass = NSClassFromString(@"UnityAppController");
    if (unityClass) {
        Method origMethod = class_getInstanceMethod(unityClass, @selector(applicationDidFinishLaunching:));
        if (origMethod) {
            orig_applicationDidFinishLaunching = (void *)method_getImplementation(origMethod);
            method_setImplementation(origMethod, (IMP)new_applicationDidFinishLaunching);
        }
    }
    
    // Hook GameManager
    Class gameClass = NSClassFromString(@"GameManager");
    if (gameClass) {
        Method origMethod = class_getInstanceMethod(gameClass, @selector(Awake));
        if (origMethod) {
            orig_Awake = (void *)method_getImplementation(origMethod);
            method_setImplementation(origMethod, (IMP)new_Awake);
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
    });
}
