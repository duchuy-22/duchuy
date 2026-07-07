#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ============================================================
// ====== BIẾN TOÀN CỤC =======================================
// ============================================================
static UIWindow *menuWindow = nil;
static BOOL isMenuVisible = NO;
static int currentTab = 0;
static UIColor *themeColor = nil;
static BOOL isDarkMode = YES;
static float menuRadius = 20.0f;
static int remainingSeconds = 604800;

// Settings
static BOOL aimbotEnabled = NO;
static BOOL autoAimEnabled = NO;
static BOOL wallHackEnabled = NO;
static int aimPart = 0;
static float fovSize = 150.0f;

static BOOL espEnabled = NO;
static BOOL espBoxEnabled = YES;
static BOOL espLineEnabled = YES;
static BOOL espSkeletonEnabled = NO;
static float espDistance = 100.0f;
static UIColor *espColor = nil;

static BOOL godModeEnabled = NO;
static BOOL speedHackEnabled = NO;
static float speedValue = 2.0f;
static BOOL noRecoilEnabled = NO;
static BOOL fastReloadEnabled = NO;
static BOOL teleportEnabled = NO;
static BOOL killAllEnabled = NO;

// ============================================================
// ====== LƯU CẤU HÌNH ========================================
// ============================================================
static void saveSettings() {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:aimbotEnabled forKey:@"aim"];
    [d setBool:autoAimEnabled forKey:@"autoaim"];
    [d setBool:wallHackEnabled forKey:@"wall"];
    [d setInteger:aimPart forKey:@"aimpart"];
    [d setFloat:fovSize forKey:@"fov"];
    [d setBool:espEnabled forKey:@"esp"];
    [d setBool:espBoxEnabled forKey:@"espbox"];
    [d setBool:espLineEnabled forKey:@"espline"];
    [d setBool:espSkeletonEnabled forKey:@"espskel"];
    [d setFloat:espDistance forKey:@"espdist"];
    [d setBool:godModeEnabled forKey:@"god"];
    [d setBool:speedHackEnabled forKey:@"speed"];
    [d setFloat:speedValue forKey:@"speedval"];
    [d setBool:noRecoilEnabled forKey:@"recoil"];
    [d setBool:fastReloadEnabled forKey:@"reload"];
    [d setBool:teleportEnabled forKey:@"tele"];
    [d setBool:killAllEnabled forKey:@"kill"];
    [d synchronize];
}

static void loadSettings() {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    aimbotEnabled = [d boolForKey:@"aim"];
    autoAimEnabled = [d boolForKey:@"autoaim"];
    wallHackEnabled = [d boolForKey:@"wall"];
    aimPart = (int)[d integerForKey:@"aimpart"];
    fovSize = [d floatForKey:@"fov"];
    espEnabled = [d boolForKey:@"esp"];
    espBoxEnabled = [d boolForKey:@"espbox"];
    espLineEnabled = [d boolForKey:@"espline"];
    espSkeletonEnabled = [d boolForKey:@"espskel"];
    espDistance = [d floatForKey:@"espdist"];
    godModeEnabled = [d boolForKey:@"god"];
    speedHackEnabled = [d boolForKey:@"speed"];
    speedValue = [d floatForKey:@"speedval"];
    noRecoilEnabled = [d boolForKey:@"recoil"];
    fastReloadEnabled = [d boolForKey:@"reload"];
    teleportEnabled = [d boolForKey:@"tele"];
    killAllEnabled = [d boolForKey:@"kill"];
    if (!themeColor) themeColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1];
    if (!espColor) espColor = [UIColor redColor];
}

static void resetAllSettings() {
    aimbotEnabled = NO;
    autoAimEnabled = NO;
    wallHackEnabled = NO;
    aimPart = 0;
    fovSize = 150.0f;
    espEnabled = NO;
    espBoxEnabled = YES;
    espLineEnabled = YES;
    espSkeletonEnabled = NO;
    espDistance = 100.0f;
    godModeEnabled = NO;
    speedHackEnabled = NO;
    speedValue = 2.0f;
    noRecoilEnabled = NO;
    fastReloadEnabled = NO;
    teleportEnabled = NO;
    killAllEnabled = NO;
    saveSettings();
}

// ============================================================
// ====== VIEW CONTROLLER =====================================
// ============================================================
@interface GrannyFFMenuVC : UIViewController
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *tabBarView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSArray *tabNames;
@end

@implementation GrannyFFMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    loadSettings();
    [self buildMenu];
    [self startTimer];
}

- (void)buildMenu {
    // Nền đen mờ
    UIView *dim = [[UIView alloc] initWithFrame:self.view.bounds];
    dim.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
    [self.view addSubview:dim];
    
    // Menu chính
    _menuView = [[UIView alloc] initWithFrame:CGRectMake(15, 40, self.view.bounds.size.width - 30, self.view.bounds.size.height - 80)];
    _menuView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.08 alpha:0.98] : [UIColor colorWithWhite:0.95 alpha:0.98];
    _menuView.layer.cornerRadius = menuRadius;
    _menuView.layer.borderWidth = 2.5;
    _menuView.layer.borderColor = themeColor.CGColor;
    _menuView.clipsToBounds = YES;
    [self.view addSubview:_menuView];
    
    // Header
    [self buildHeader];
    
    // Tab Bar
    [self buildTabBar];
    
    // Content
    [self buildContent];
    
    // Footer
    [self buildFooter];
    
    // Load tab đầu tiên
    [self loadTab:0];
}

- (void)buildHeader {
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _menuView.bounds.size.width, 90)];
    _headerView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.15 alpha:1] : [UIColor colorWithWhite:0.9 alpha:1];
    [_menuView addSubview:_headerView];
    
    // Logo
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 200, 32)];
    logo.text = @"🔥 GRANNY MOD";
    logo.textColor = themeColor;
    logo.font = [UIFont boldSystemFontOfSize:22];
    [_headerView addSubview:logo];
    
    // Version
    UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(15, 44, 250, 18)];
    ver.text = @"Version 2.0.0 for game 1.123.X";
    ver.textColor = isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor];
    ver.font = [UIFont systemFontOfSize:11];
    [_headerView addSubview:ver];
    
    // Timer
    UILabel *timerLbl = [[UILabel alloc] initWithFrame:CGRectMake(15, 62, 280, 18)];
    timerLbl.text = [self getTimeString];
    timerLbl.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1];
    timerLbl.font = [UIFont boldSystemFontOfSize:12];
    timerLbl.tag = 999;
    [_headerView addSubview:timerLbl];
    
    // Close Button
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(_menuView.bounds.size.width - 50, 10, 40, 40);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setTitleColor:themeColor forState:UIControlStateNormal];
    close.titleLabel.font = [UIFont boldSystemFontOfSize:26];
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:close];
}

- (void)buildTabBar {
    _tabNames = @[@"Aimbot", @"Visuals", @"Settings", @"Account"];
    _tabBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 90, _menuView.bounds.size.width, 48)];
    _tabBarView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.05 alpha:1] : [UIColor colorWithWhite:0.85 alpha:1];
    [_menuView addSubview:_tabBarView];
    
    float tabWidth = _tabBarView.bounds.size.width / 4;
    for (int i = 0; i < _tabNames.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(i * tabWidth, 0, tabWidth, 48);
        [btn setTitle:_tabNames[i] forState:UIControlStateNormal];
        [btn setTitleColor:(i == currentTab) ? themeColor : (isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor]) forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        btn.tag = 100 + i;
        [btn addTarget:self action:@selector(tabPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_tabBarView addSubview:btn];
        
        if (i == currentTab) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(i * tabWidth + 30, 45, tabWidth - 60, 3)];
            line.backgroundColor = themeColor;
            line.tag = 200 + i;
            [_tabBarView addSubview:line];
        }
    }
}

- (void)buildContent {
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 138, _menuView.bounds.size.width, _menuView.bounds.size.height - 168)];
    _contentView.backgroundColor = [UIColor clearColor];
    [_menuView addSubview:_contentView];
}

- (void)buildFooter {
    _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, _menuView.bounds.size.height - 30, _menuView.bounds.size.width, 30)];
    _footerView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.05 alpha:1] : [UIColor colorWithWhite:0.85 alpha:1];
    [_menuView addSubview:_footerView];
    
    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, _footerView.bounds.size.width, 20)];
    footer.text = @"🔥 Granny Mod | Anonymous";
    footer.textColor = isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor];
    footer.font = [UIFont systemFontOfSize:10];
    footer.textAlignment = NSTextAlignmentCenter;
    [_footerView addSubview:footer];
}

- (void)tabPressed:(UIButton *)sender {
    int index = (int)(sender.tag - 100);
    currentTab = index;
    
    float tabWidth = _tabBarView.bounds.size.width / 4;
    for (int i = 0; i < _tabNames.count; i++) {
        UIButton *btn = (UIButton *)[_tabBarView viewWithTag:100 + i];
        [btn setTitleColor:(i == index) ? themeColor : (isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor]) forState:UIControlStateNormal];
        UIView *line = [_tabBarView viewWithTag:200 + i];
        [line removeFromSuperview];
    }
    
    UIView *newLine = [[UIView alloc] initWithFrame:CGRectMake(index * tabWidth + 30, 45, tabWidth - 60, 3)];
    newLine.backgroundColor = themeColor;
    newLine.tag = 200 + index;
    [_tabBarView addSubview:newLine];
    
    [self loadTab:index];
}

- (void)loadTab:(int)index {
    for (UIView *v in _contentView.subviews) [v removeFromSuperview];
    switch (index) {
        case 0: [self drawAimbotTab]; break;
        case 1: [self drawVisualsTab]; break;
        case 2: [self drawSettingsTab]; break;
        case 3: [self drawAccountTab]; break;
    }
}

// ============================================================
// ====== TAB 0: AIMBOT =======================================
// ============================================================
- (void)drawAimbotTab {
    int y = 10;
    int w = _contentView.bounds.size.width;
    
    [self addSwitchAt:w y:y label:@"🔫 Aimbot" value:aimbotEnabled tag:100];
    y += 50;
    [self addSwitchAt:w y:y label:@"🎯 Auto Aim" value:autoAimEnabled tag:101];
    y += 50;
    [self addSwitchAt:w y:y label:@"🧱 Wall Hack" value:wallHackEnabled tag:102];
    y += 50;
    
    [self addLabelAt:w y:y text:@"🎯 Aim Part:"];
    y += 28;
    
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Đầu", @"Ngực", @"Cổ", @"Bụng"]];
    seg.frame = CGRectMake(15, y, w - 30, 35);
    seg.selectedSegmentIndex = aimPart;
    seg.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.2 alpha:1] : [UIColor colorWithWhite:0.8 alpha:1];
    seg.selectedSegmentTintColor = themeColor;
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [seg addTarget:self action:@selector(aimPartChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:seg];
    y += 50;
    
    [self addSliderAt:w y:y label:@"📏 FOV:" value:fovSize min:30 max:300 tag:500];
}

// ============================================================
// ====== TAB 1: VISUALS ======================================
// ============================================================
- (void)drawVisualsTab {
    int y = 10;
    int w = _contentView.bounds.size.width;
    
    [self addSwitchAt:w y:y label:@"👁️ ESP" value:espEnabled tag:200];
    y += 50;
    [self addSwitchAt:w y:y label:@"📦 Box" value:espBoxEnabled tag:201];
    y += 50;
    [self addSwitchAt:w y:y label:@"📏 Line" value:espLineEnabled tag:202];
    y += 50;
    [self addSwitchAt:w y:y label:@"🦴 Skeleton" value:espSkeletonEnabled tag:203];
    y += 50;
    
    [self addLabelAt:w y:y text:@"🎨 ESP Color:"];
    y += 28;
    
    UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    colorBtn.frame = CGRectMake(15, y, 100, 35);
    [colorBtn setTitle:@"Chọn màu" forState:UIControlStateNormal];
    [colorBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    colorBtn.backgroundColor = themeColor;
    colorBtn.layer.cornerRadius = 8;
    [colorBtn addTarget:self action:@selector(chooseESPColor) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:colorBtn];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(125, y, 35, 35)];
    colorView.backgroundColor = espColor;
    colorView.layer.cornerRadius = 17;
    colorView.layer.borderWidth = 2;
    colorView.layer.borderColor = [UIColor whiteColor].CGColor;
    colorView.tag = 900;
    [_contentView addSubview:colorView];
    y += 50;
    
    [self addSliderAt:w y:y label:@"📡 Distance:" value:espDistance min:10 max:200 tag:501];
}

// ============================================================
// ====== TAB 2: SETTINGS =====================================
// ============================================================
- (void)drawSettingsTab {
    int y = 10;
    int w = _contentView.bounds.size.width;
    
    [self addSwitchAt:w y:y label:@"🛡️ God Mode" value:godModeEnabled tag:300];
    y += 50;
    [self addSwitchAt:w y:y label:@"⚡ Speed Hack" value:speedHackEnabled tag:301];
    y += 50;
    [self addSliderAt:w y:y label:[NSString stringWithFormat:@"Speed: %.1fx", speedValue] value:speedValue min:1 max:10 tag:502];
    y += 50;
    [self addSwitchAt:w y:y label:@"🔫 No Recoil" value:noRecoilEnabled tag:302];
    y += 50;
    [self addSwitchAt:w y:y label:@"🔄 Fast Reload" value:fastReloadEnabled tag:303];
    y += 50;
    [self addSwitchAt:w y:y label:@"📦 Teleport" value:teleportEnabled tag:304];
    y += 50;
    [self addSwitchAt:w y:y label:@"💀 Kill All" value:killAllEnabled tag:305];
}

// ============================================================
// ====== TAB 3: ACCOUNT ======================================
// ============================================================
- (void)drawAccountTab {
    int y = 15;
    int w = _contentView.bounds.size.width;
    
    // Info Box
    UIView *info = [[UIView alloc] initWithFrame:CGRectMake(15, y, w - 30, 110)];
    info.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.12 alpha:1] : [UIColor colorWithWhite:0.9 alpha:1];
    info.layer.cornerRadius = 12;
    info.layer.borderWidth = 1;
    info.layer.borderColor = themeColor.CGColor;
    [_contentView addSubview:info];
    
    [self addLabelToView:info x:15 y:8 text:@"📱 ACCOUNT INFO" color:themeColor font:[UIFont boldSystemFontOfSize:15]];
    [self addLabelToView:info x:15 y:32 text:@"👤 User: Anonymous" color:isDarkMode ? [UIColor whiteColor] : [UIColor blackColor] font:[UIFont systemFontOfSize:14]];
    [self addLabelToView:info x:15 y:54 text:@"🎯 Plan: PRO" color:isDarkMode ? [UIColor whiteColor] : [UIColor blackColor] font:[UIFont systemFontOfSize:14]];
    [self addLabelToView:info x:15 y:76 text:[NSString stringWithFormat:@"⏳ Expires: %@", [self getTimeString]] color:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1] font:[UIFont boldSystemFontOfSize:13]];
    y += 125;
    
    // Theme Color
    [self addLabelAt:w y:y text:@"🎨 Theme Color:"];
    y += 28;
    
    NSArray *colors = @[
        [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1],
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1],
        [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1],
        [UIColor colorWithRed:1.0 green:0.0 blue:0.8 alpha:1],
        [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1],
        [UIColor colorWithRed:0.8 green:0.8 blue:0.0 alpha:1]
    ];
    
    for (int i = 0; i < colors.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(15 + i * 48, y, 40, 40);
        btn.backgroundColor = colors[i];
        btn.layer.cornerRadius = 20;
        btn.layer.borderWidth = 2;
        btn.layer.borderColor = [UIColor whiteColor].CGColor;
        btn.tag = 600 + i;
        [btn addTarget:self action:@selector(themeColorChanged:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:btn];
    }
    y += 55;
    
    // Dark Mode
    [self addSwitchAt:w y:y label:@"🌙 Dark Mode" value:isDarkMode tag:306];
    y += 50;
    
    // Corner Radius
    [self addLabelAt:w y:y text:@"📐 Corner Radius:"];
    y += 28;
    UISlider *corner = [[UISlider alloc] initWithFrame:CGRectMake(15, y, w - 30, 30)];
    corner.minimumValue = 0;
    corner.maximumValue = 30;
    corner.value = menuRadius;
    corner.tag = 503;
    corner.minimumTrackTintColor = themeColor;
    [corner addTarget:self action:@selector(cornerChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:corner];
    y += 50;
    
    // Logout
    UIButton *logout = [UIButton buttonWithType:UIButtonTypeSystem];
    logout.frame = CGRectMake(30, y, w - 60, 45);
    [logout setTitle:@"🚪 LOGOUT" forState:UIControlStateNormal];
    [logout setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    logout.backgroundColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:0.9];
    logout.layer.cornerRadius = 10;
    [logout addTarget:self action:@selector(logoutPressed) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:logout];
}

// ============================================================
// ====== UI HELPERS ==========================================
// ============================================================
- (void)addSwitchAt:(int)w y:(int)y label:(NSString *)label value:(BOOL)value tag:(int)tag {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(w - 70, y, 51, 31)];
    sw.on = value;
    sw.tag = tag;
    sw.onTintColor = themeColor;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:sw];
    [self addLabelAt:w y:y text:label];
}

- (void)addLabelAt:(int)w y:(int)y text:(NSString *)text {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, y, w - 30, 30)];
    lbl.text = text;
    lbl.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    lbl.font = [UIFont systemFontOfSize:15];
    [_contentView addSubview:lbl];
}

- (void)addLabelToView:(UIView *)v x:(int)x y:(int)y text:(NSString *)text color:(UIColor *)c font:(UIFont *)f {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(x, y, v.bounds.size.width - x - 10, 25)];
    lbl.text = text;
    lbl.textColor = c;
    lbl.font = f;
    [v addSubview:lbl];
}

- (void)addSliderAt:(int)w y:(int)y label:(NSString *)label value:(float)value min:(float)min max:(float)max tag:(int)tag {
    [self addLabelAt:w y:y text:label];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(15, y + 28, w - 30, 30)];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = value;
    slider.tag = tag;
    slider.minimumTrackTintColor = themeColor;
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:slider];
}

// ============================================================
// ====== HANDLERS ============================================
// ============================================================
- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 100: aimbotEnabled = sender.on; break;
        case 101: autoAimEnabled = sender.on; break;
        case 102: wallHackEnabled = sender.on; break;
        case 200: espEnabled = sender.on; break;
        case 201: espBoxEnabled = sender.on; break;
        case 202: espLineEnabled = sender.on; break;
        case 203: espSkeletonEnabled = sender.on; break;
        case 300: godModeEnabled = sender.on; break;
        case 301: speedHackEnabled = sender.on; break;
        case 302: noRecoilEnabled = sender.on; break;
        case 303: fastReloadEnabled = sender.on; break;
        case 304: teleportEnabled = sender.on; break;
        case 305: killAllEnabled = sender.on; break;
        case 306: isDarkMode = sender.on; [self rebuildMenu]; break;
    }
    saveSettings();
}

- (void)sliderChanged:(UISlider *)sender {
    switch (sender.tag) {
        case 500: fovSize = sender.value; break;
        case 501: espDistance = sender.value; break;
        case 502: speedValue = sender.value; break;
        case 503: menuRadius = sender.value; [self rebuildMenu]; break;
    }
    [self loadTab:currentTab];
    saveSettings();
}

- (void)aimPartChanged:(UISegmentedControl *)sender {
    aimPart = (int)sender.selectedSegmentIndex;
    saveSettings();
}

- (void)themeColorChanged:(UIButton *)sender {
    themeColor = sender.backgroundColor;
    [self rebuildMenu];
    saveSettings();
}

- (void)cornerChanged:(UISlider *)sender {
    menuRadius = sender.value;
    [self rebuildMenu];
}

- (void)chooseESPColor {
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
        picker.delegate = self;
        picker.selectedColor = espColor;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)vc {
    espColor = vc.selectedColor;
    UIView *cv = [_contentView viewWithTag:900];
    if (cv) cv.backgroundColor = espColor;
    saveSettings();
}

- (void)logoutPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🚪 Logout" message:@"Bạn có chắc muốn đăng xuất?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self closeMenu];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

// ============================================================
// ====== TIMER ===============================================
// ============================================================
- (void)startTimer {
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}

- (void)updateTimer {
    if (remainingSeconds > 0) remainingSeconds--;
    UILabel *lbl = (UILabel *)[_headerView viewWithTag:999];
    if (lbl) lbl.text = [self getTimeString];
}

- (NSString *)getTimeString {
    int d = remainingSeconds / 86400;
    int h = (remainingSeconds % 86400) / 3600;
    int m = (remainingSeconds % 3600) / 60;
    int s = remainingSeconds % 60;
    return [NSString stringWithFormat:@"⏳ Expires: %dd %dh %dm %ds", d, h, m, s];
}

// ============================================================
// ====== REBUILD =============================================
// ============================================================
- (void)rebuildMenu {
    for (UIView *v in _menuView.subviews) [v removeFromSuperview];
    [self buildHeader];
    [self buildTabBar];
    [self buildContent];
    [self buildFooter];
    [self loadTab:currentTab];
}

// ============================================================
// ====== CLOSE ===============================================
// ============================================================
- (void)closeMenu {
    menuWindow.hidden = YES;
    isMenuVisible = NO;
    [_timer invalidate];
    _timer = nil;
}

@end

// ============================================================
// ====== HÀM MỞ MENU =========================================
// ============================================================
void showMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isMenuVisible) {
            menuWindow.hidden = YES;
            isMenuVisible = NO;
            return;
        }
        
        if (!menuWindow) {
            menuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuWindow.windowLevel = UIWindowLevelAlert + 2;
            menuWindow.backgroundColor = [UIColor clearColor];
            menuWindow.rootViewController = [[GrannyFFMenuVC alloc] init];
            menuWindow.userInteractionEnabled = YES;
        }
        menuWindow.hidden = NO;
        isMenuVisible = YES;
        NSLog(@"✅ MENU OPENED!");
    });
}

// ============================================================
// ====== SETUP GESTURE =======================================
// ============================================================
static void setupGestures() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        if (!win) win = [[[UIApplication sharedApplication] windows] firstObject];
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
        NSLog(@"✅ GESTURE SET!");
    });
}

// ============================================================
// ====== HOOK ================================================
// ============================================================
static void (*orig_didFinishLaunching)(id self, SEL cmd, UIApplication *app);
static void new_didFinishLaunching(id self, SEL cmd, UIApplication *app) {
    if (orig_didFinishLaunching) orig_didFinishLaunching(self, cmd, app);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
        showMenu();
    });
}

// ============================================================
// ====== CONSTRUCTOR =========================================
// ============================================================
__attribute__((constructor)) static void init() {
    NSLog(@"🔥 GRANNY MOD LOADING...");
    loadSettings();
    
    Class unityClass = NSClassFromString(@"UnityAppController");
    if (unityClass) {
        Method m = class_getInstanceMethod(unityClass, @selector(applicationDidFinishLaunching:));
        if (m) {
            orig_didFinishLaunching = (void *)method_getImplementation(m);
            method_setImplementation(m, (IMP)new_didFinishLaunching);
        }
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
        showMenu();
    });
}
