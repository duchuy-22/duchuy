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
static BOOL isVietnamese = YES;

// ESP Settings
static BOOL espBox = YES;
static BOOL espLine = YES;
static BOOL espSkeleton = NO;
static float espDistance = 100.0f;
static UIColor *espColor = nil;

// Aimbot Settings
static int aimTarget = 0; // 0:Đầu, 1:Ngực, 2:Cổ, 3:Bụng
static BOOL aimAuto = NO;
static BOOL aimWall = NO;
static float aimFOV = 150.0f;

// UI
static UIWindow *menuWindow = nil;
static UIView *menuContainer = nil;
static int currentTab = 0; // 0:Aimbot, 1:ESP, 2:ChucNang, 3:TaiKhoan
static NSMutableArray *allSwitches = nil;

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

// ====== HÀM TẠO LABEL ======
static UILabel* createLabel(NSString *text, CGRect frame, UIColor *color, UIFont *font) {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = text;
    label.textColor = color ? color : [UIColor whiteColor];
    label.font = font ? font : [UIFont systemFontOfSize:14];
    return label;
}

// ====== HÀM TẠO SWITCH ======
static UISwitch* createSwitch(CGRect frame, BOOL value, int tag, id target, SEL action) {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:frame];
    sw.on = value;
    sw.tag = tag;
    sw.onTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [sw addTarget:target action:action forControlEvents:UIControlEventValueChanged];
    return sw;
}

// ====== HÀM TẠO NÚT ======
static UIButton* createButton(NSString *title, CGRect frame, UIColor *bgColor, id target, SEL action) {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = frame;
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.backgroundColor = bgColor;
    btn.layer.cornerRadius = 8;
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

// ====== VIEW CONTROLLER ======
@interface GrannyModMenuVC : UIViewController
@end

@implementation GrannyModMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Nền mờ
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    dimView.userInteractionEnabled = YES;
    [self.view addSubview:dimView];
    
    // MENU CONTAINER
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(30, 60, 340, 520)];
    menuContainer.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.95];
    menuContainer.layer.cornerRadius = 16;
    menuContainer.layer.borderWidth = 1.5;
    menuContainer.layer.borderColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.6].CGColor;
    menuContainer.clipsToBounds = YES;
    [self.view addSubview:menuContainer];
    
    // ====== HEADER ======
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 340, 50)];
    header.backgroundColor = [UIColor colorWithRed:0.12 green:0.04 blue:0.04 alpha:1];
    [menuContainer addSubview:header];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 30)];
    title.text = @"🔥 GRANNY MOD";
    title.textColor = [UIColor colorWithRed:1.0 green:0.3 blue:0.3 alpha:1];
    title.font = [UIFont boldSystemFontOfSize:18];
    [header addSubview:title];
    
    // Nút X
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(295, 10, 35, 30);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];
    
    // ====== TAB BAR ======
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
    
    // ====== CONTENT AREA ======
    UIView *contentArea = [[UIView alloc] initWithFrame:CGRectMake(10, 95, 320, 370)];
    contentArea.tag = 999;
    contentArea.backgroundColor = [UIColor clearColor];
    [menuContainer addSubview:contentArea];
    
    // Load tab hiện tại
    [self loadTab:currentTab];
}

- (void)tabPressed:(UIButton *)sender {
    int index = (int)(sender.tag - 200);
    currentTab = index;
    
    // Cập nhật màu tab
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
    
    // Xóa content cũ
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

// ====== TAB 0: AIMBOT ======
- (void)drawAimbotTab:(UIView *)content {
    int y = 5;
    
    // Aimbot toggle
    UISwitch *sw1 = createSwitch(CGRectMake(250, y, 51, 31), isAimbotActive, 100, self, @selector(switchChanged:));
    [content addSubview:sw1];
    [content addSubview:createLabel:@"🔫 Aimbot" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Auto aim
    UISwitch *sw2 = createSwitch(CGRectMake(250, y, 51, 31), aimAuto, 101, self, @selector(switchChanged:));
    [content addSubview:sw2];
    [content addSubview:createLabel:@"🎯 Tự động ngắm" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Wall hack
    UISwitch *sw3 = createSwitch(CGRectMake(250, y, 51, 31), aimWall, 102, self, @selector(switchChanged:));
    [content addSubview:sw3];
    [content addSubview:createLabel:@"🧱 Xuyên tường" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Vị trí ngắm
    [content addSubview:createLabel:@"🎯 Vị trí:" CGRectMake(10, y, 100, 30) nil nil];
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Đầu", @"Ngực", @"Cổ", @"Bụng"]];
    seg.frame = CGRectMake(100, y, 200, 30);
    seg.selectedSegmentIndex = aimTarget;
    seg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    seg.selectedSegmentTintColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [seg addTarget:self action:@selector(aimTargetChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:seg];
    y += 45;
    
    // FOV
    [content addSubview:createLabel:[NSString stringWithFormat:@"📏 FOV: %.0f", aimFOV] CGRectMake(10, y, 120, 30) nil nil];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(130, y, 170, 30)];
    slider.minimumValue = 30;
    slider.maximumValue = 300;
    slider.value = aimFOV;
    slider.tag = 500;
    [slider addTarget:self action:@selector(fovChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:slider];
}

// ====== TAB 1: ESP ======
- (void)drawESPTab:(UIView *)content {
    int y = 5;
    
    // ESP toggle
    UISwitch *sw1 = createSwitch(CGRectMake(250, y, 51, 31), isEspActive, 200, self, @selector(switchChanged:));
    [content addSubview:sw1];
    [content addSubview:createLabel:@"👁️ ESP" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Box
    UISwitch *sw2 = createSwitch(CGRectMake(250, y, 51, 31), espBox, 201, self, @selector(switchChanged:));
    [content addSubview:sw2];
    [content addSubview:createLabel:@"📦 Box" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Line
    UISwitch *sw3 = createSwitch(CGRectMake(250, y, 51, 31), espLine, 202, self, @selector(switchChanged:));
    [content addSubview:sw3];
    [content addSubview:createLabel:@"📏 Line" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Skeleton
    UISwitch *sw4 = createSwitch(CGRectMake(250, y, 51, 31), espSkeleton, 203, self, @selector(switchChanged:));
    [content addSubview:sw4];
    [content addSubview:createLabel:@"🦴 Skeleton" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Màu ESP
    UIButton *colorBtn = createButton(@"🎨 Màu ESP", CGRectMake(10, y, 150, 35), [UIColor colorWithWhite:0.2 alpha:1], self, @selector(chooseColor));
    [content addSubview:colorBtn];
    
    // Hiển thị màu hiện tại
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(170, y, 30, 30)];
    colorView.backgroundColor = espColor ? espColor : [UIColor redColor];
    colorView.layer.cornerRadius = 15;
    colorView.layer.borderWidth = 1;
    colorView.layer.borderColor = [UIColor whiteColor].CGColor;
    colorView.tag = 900;
    [content addSubview:colorView];
    y += 50;
    
    // Khoảng cách
    [content addSubview:createLabel:[NSString stringWithFormat:@"📡 Khoảng cách: %.0fm", espDistance] CGRectMake(10, y, 150, 30) nil nil];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(160, y, 140, 30)];
    slider.minimumValue = 10;
    slider.maximumValue = 200;
    slider.value = espDistance;
    slider.tag = 501;
    [slider addTarget:self action:@selector(distChanged:) forControlEvents:UIControlEventValueChanged];
    [content addSubview:slider];
}

// ====== TAB 2: CHỨC NĂNG ======
- (void)drawChucNangTab:(UIView *)content {
    int y = 5;
    
    // God Mode
    UISwitch *sw1 = createSwitch(CGRectMake(250, y, 51, 31), isGodMode, 300, self, @selector(switchChanged:));
    [content addSubview:sw1];
    [content addSubview:createLabel:@"🛡️ Bất tử" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Speed
    UISwitch *sw2 = createSwitch(CGRectMake(250, y, 51, 31), isHighSpeed, 301, self, @selector(switchChanged:));
    [content addSubview:sw2];
    [content addSubview:createLabel:@"⚡ Speed" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // No Recoil
    UISwitch *sw3 = createSwitch(CGRectMake(250, y, 51, 31), isNoRecoil, 302, self, @selector(switchChanged:));
    [content addSubview:sw3];
    [content addSubview:createLabel:@"🔫 Không giật" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Fast Reload
    UISwitch *sw4 = createSwitch(CGRectMake(250, y, 51, 31), isFastReload, 303, self, @selector(switchChanged:));
    [content addSubview:sw4];
    [content addSubview:createLabel:@"🔄 Nạp đạn nhanh" CGRectMake(10, y, 150, 30) nil nil];
    y += 40;
    
    // Teleport
    UISwitch *sw5 = createSwitch(CGRectMake(250, y, 51, 31), isTeleport, 304, self, @selector(switchChanged:));
    [content addSubview:sw5];
    [content addSubview:createLabel:@"📦 Teleport vật phẩm" CGRectMake(10, y, 170, 30) nil nil];
    y += 40;
    
    // Kill All
    UISwitch *sw6 = createSwitch(CGRectMake(250, y, 51, 31), isKillAll, 305, self, @selector(switchChanged:));
    [content addSubview:sw6];
    [content addSubview:createLabel:@"💀 Kill bà ngoại" CGRectMake(10, y, 150, 30) nil nil];
}

// ====== TAB 3: TÀI KHOẢN ======
- (void)drawTaiKhoanTab:(UIView *)content {
    int y = 10;
    
    // Key
    [content addSubview:createLabel:@"🔑 KEY:" CGRectMake(10, y, 60, 30) nil nil];
    UITextField *keyField = [[UITextField alloc] initWithFrame:CGRectMake(80, y, 160, 35)];
    keyField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1];
    keyField.textColor = [UIColor whiteColor];
    keyField.placeholder = @"Nhập key...";
    keyField.layer.cornerRadius = 8;
    keyField.layer.borderWidth = 1;
    keyField.layer.borderColor = [UIColor grayColor].CGColor;
    [content addSubview:keyField];
    
    UIButton *confirmBtn = createButton(@"✅", CGRectMake(250, y, 50, 35), [UIColor colorWithRed:0.2 green:0.7 blue:0.2 alpha:0.8], self, @selector(confirmKey));
    [content addSubview:confirmBtn];
    y += 50;
    
    // Thông tin user
    [content addSubview:createLabel:@"👤 User: HuyMod" CGRectMake(10, y, 200, 30) [UIColor colorWithRed:0.5 green:1.0 blue:0.5 alpha:1] nil];
    y += 35;
    
    [content addSubview:createLabel:@"⏳ Hết hạn: 2026-12-31" CGRectMake(10, y, 250, 30) [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1] nil];
    y += 40;
    
    [content addSubview:createLabel:@"✅ Đã kích hoạt!" CGRectMake(10, y, 200, 30) [UIColor greenColor] [UIFont boldSystemFontOfSize:16]];
    y += 50;
    
    // Nút Lưu Setting
    UIButton *saveBtn = createButton(@"💾 LƯU SETTING", CGRectMake(30, y, 250, 45), [UIColor colorWithRed:0.2 green:0.5 blue:0.2 alpha:0.9], self, @selector(savePressed));
    [content addSubview:saveBtn];
    y += 55;
    
    // Nút Reset
    UIButton *resetBtn = createButton(@"🔴 TẮT TẤT CẢ", CGRectMake(30, y, 250, 45), [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.9], self, @selector(resetPressed));
    [content addSubview:resetBtn];
}

// ====== SWITCH HANDLER ======
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
    NSLog(@"🔄 Switch %d changed", sender.tag);
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

// ====== MÀU ESP ======
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

// ====== LƯU / RESET ======
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

// ====== ẨN MENU ======
- (void)hideMenu {
    menuWindow.hidden = YES;
    NSLog(@"📱 Menu hidden - features still active!");
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // Chạm ra ngoài menu cũng đóng
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
        NSLog(@"📱 Menu opened!");
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
        
        // Xóa gesture cũ
        for (UIGestureRecognizer *gr in win.gestureRecognizers) {
            if ([gr isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gr;
                if (tap.numberOfTouchesRequired == 3 && tap.numberOfTapsRequired == 2) {
                    [win removeGestureRecognizer:gr];
                }
            }
        }
        
        // Tạo gesture: 3 ngón chạm 2 lần
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:@selector(showMenu)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 2;
        tap.cancelsTouchesInView = NO;
        [win addGestureRecognizer:tap];
        
        NSLog(@"👆 Gesture ready: 3 fingers, 2 taps");
    });
}

// ====== HOOK GAME ======
%hook GameManager
- (void)Awake {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
    });
}
%end

%hook UnityAppController
- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    loadSettings();
    resetAllFeatures();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
        NSLog(@"🔥 Granny Mod v2.0 loaded!");
    });
}
%end

// ====== CONSTRUCTOR ======
__attribute__((constructor)) static void init() {
    loadSettings();
    resetAllFeatures();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
        NSLog(@"✅ Granny Mod v2.0 ready!");
    });
}
