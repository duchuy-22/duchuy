#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// ====== BIẾN TOÀN CỤC ======
static UIWindow *menuWindow = nil;
static BOOL isMenuVisible = NO;
static int currentTab = 0;
static UIColor *menuColor = nil;
static BOOL isDarkMode = YES;
static float menuCornerRadius = 20.0f;
static NSTimer *countdownTimer = nil;
static int remainingSeconds = 604800; // 7 ngày

// Settings
static BOOL isAimbot = NO;
static BOOL isESP = NO;
static BOOL isGodMode = NO;
static BOOL isSpeed = NO;
static BOOL isNoRecoil = NO;
static BOOL isFastReload = NO;
static BOOL isTeleport = NO;
static BOOL isKillAll = NO;
static BOOL isWallHack = NO;
static BOOL isAutoAim = NO;
static int aimPart = 0;
static float fovSize = 150.0f;
static float speedValue = 2.0f;
static BOOL espBox = YES;
static BOOL espLine = YES;
static BOOL espSkeleton = NO;
static float espDistance = 100.0f;
static UIColor *espColor = nil;

// ====== VIEW CONTROLLER ======
@interface GrannyFFMenuVC : UIViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *tabBar;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UITableView *settingsTable;
@property (nonatomic, strong) NSArray *tabNames;
@property (nonatomic, strong) NSArray *aimbotItems;
@property (nonatomic, strong) NSArray *visualsItems;
@property (nonatomic, strong) NSArray *settingsItems;
@property (nonatomic, strong) NSArray *accountItems;
@end

@implementation GrannyFFMenuVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    if (!menuColor) menuColor = [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1]; // Cam
    if (!espColor) espColor = [UIColor redColor];
    
    [self setupMenu];
}

- (void)setupMenu {
    // Nền tối
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.75];
    dimView.userInteractionEnabled = YES;
    [self.view addSubview:dimView];
    
    // MENU CHÍNH
    _menuView = [[UIView alloc] initWithFrame:CGRectMake(15, 40, self.view.bounds.size.width - 30, self.view.bounds.size.height - 80)];
    _menuView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.08 alpha:0.98] : [UIColor colorWithWhite:0.95 alpha:0.98];
    _menuView.layer.cornerRadius = menuCornerRadius;
    _menuView.layer.borderWidth = 2;
    _menuView.layer.borderColor = menuColor.CGColor;
    _menuView.clipsToBounds = YES;
    [self.view addSubview:_menuView];
    
    // ====== HEADER ======
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _menuView.bounds.size.width, 80)];
    _headerView.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.12 alpha:1] : [UIColor colorWithWhite:0.9 alpha:1];
    [_menuView addSubview:_headerView];
    
    // Logo
    UILabel *logo = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 30)];
    logo.text = @"🔥 GRANNY MOD";
    logo.textColor = menuColor;
    logo.font = [UIFont boldSystemFontOfSize:20];
    [_headerView addSubview:logo];
    
    // Version
    UILabel *ver = [[UILabel alloc] initWithFrame:CGRectMake(15, 38, 200, 20)];
    ver.text = @"Version 2.0.0 for game 1.123.X";
    ver.textColor = isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor];
    ver.font = [UIFont systemFontOfSize:11];
    [_headerView addSubview:ver];
    
    // Timer
    UILabel *timerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 55, 250, 18)];
    timerLabel.text = [self getTimeString];
    timerLabel.textColor = isDarkMode ? [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1] : [UIColor colorWithRed:0.8 green:0.5 blue:0.0 alpha:1];
    timerLabel.font = [UIFont systemFontOfSize:11];
    timerLabel.tag = 999;
    [_headerView addSubview:timerLabel];
    
    // Nút đóng
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(_menuView.bounds.size.width - 50, 10, 40, 40);
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:menuColor forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    [closeBtn addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:closeBtn];
    
    // ====== TAB BAR ======
    _tabNames = @[@"Aimbot", @"Visuals", @"Settings", @"Account"];
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(0, 80, _menuView.bounds.size.width, 45)];
    _tabBar.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.05 alpha:1] : [UIColor colorWithWhite:0.85 alpha:1];
    [_menuView addSubview:_tabBar];
    
    for (int i = 0; i < _tabNames.count; i++) {
        UIButton *tabBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        tabBtn.frame = CGRectMake(i * (_tabBar.bounds.size.width / 4), 0, _tabBar.bounds.size.width / 4, 45);
        [tabBtn setTitle:_tabNames[i] forState:UIControlStateNormal];
        [tabBtn setTitleColor:(i == currentTab) ? menuColor : (isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor]) forState:UIControlStateNormal];
        tabBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        tabBtn.tag = 100 + i;
        [tabBtn addTarget:self action:@selector(tabPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_tabBar addSubview:tabBtn];
        
        // Line dưới tab active
        if (i == currentTab) {
            UIView *line = [[UIView alloc] initWithFrame:CGRectMake(i * (_tabBar.bounds.size.width / 4) + 20, 42, _tabBar.bounds.size.width / 4 - 40, 3)];
            line.backgroundColor = menuColor;
            line.tag = 200 + i;
            [_tabBar addSubview:line];
        }
    }
    
    // ====== CONTENT ======
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 125, _menuView.bounds.size.width, _menuView.bounds.size.height - 125)];
    _contentView.backgroundColor = [UIColor clearColor];
    [_menuView addSubview:_contentView];
    
    // Load tab hiện tại
    [self loadTab:currentTab];
    
    // ====== FOOTER ======
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, _menuView.bounds.size.height - 30, _menuView.bounds.size.width, 30)];
    footer.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.05 alpha:1] : [UIColor colorWithWhite:0.85 alpha:1];
    [_menuView addSubview:footer];
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, _menuView.bounds.size.width, 20)];
    footerLabel.text = @"🔥 Made by Anonymous | Granny Mod";
    footerLabel.textColor = isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor];
    footerLabel.font = [UIFont systemFontOfSize:10];
    footerLabel.textAlignment = NSTextAlignmentCenter;
    [footer addSubview:footerLabel];
    
    // Chạy timer đếm ngược
    [self startCountdown];
}

- (void)tabPressed:(UIButton *)sender {
    int index = (int)(sender.tag - 100);
    currentTab = index;
    
    // Update tab bar
    for (int i = 0; i < _tabNames.count; i++) {
        UIButton *btn = (UIButton *)[_tabBar viewWithTag:100 + i];
        if (btn) {
            [btn setTitleColor:(i == index) ? menuColor : (isDarkMode ? [UIColor grayColor] : [UIColor darkGrayColor]) forState:UIControlStateNormal];
        }
        UIView *line = [_tabBar viewWithTag:200 + i];
        if (line) [line removeFromSuperview];
    }
    
    // Add line mới
    UIView *newLine = [[UIView alloc] initWithFrame:CGRectMake(index * (_tabBar.bounds.size.width / 4) + 20, 42, _tabBar.bounds.size.width / 4 - 40, 3)];
    newLine.backgroundColor = menuColor;
    newLine.tag = 200 + index;
    [_tabBar addSubview:newLine];
    
    [self loadTab:index];
}

- (void)loadTab:(int)index {
    // Clear content
    for (UIView *v in _contentView.subviews) {
        [v removeFromSuperview];
    }
    
    switch (index) {
        case 0: [self drawAimbotTab]; break;
        case 1: [self drawVisualsTab]; break;
        case 2: [self drawSettingsTab]; break;
        case 3: [self drawAccountTab]; break;
    }
}

// ====== TAB 0: AIMBOT ======
- (void)drawAimbotTab {
    int y = 10;
    int width = _contentView.bounds.size.width;
    
    [self addSwitch:width y:y label:@"🔫 Aimbot" value:isAimbot tag:100];
    y += 50;
    
    [self addSwitch:width y:y label:@"🎯 Auto Aim" value:isAutoAim tag:101];
    y += 50;
    
    [self addSwitch:width y:y label:@"🧱 Wall Hack" value:isWallHack tag:102];
    y += 50;
    
    [self addLabel:width y:y text:@"🎯 Aim Part:"];
    y += 30;
    
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Đầu", @"Ngực", @"Cổ", @"Bụng"]];
    seg.frame = CGRectMake(15, y, width - 30, 35);
    seg.selectedSegmentIndex = aimPart;
    seg.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.2 alpha:1] : [UIColor colorWithWhite:0.8 alpha:1];
    seg.selectedSegmentTintColor = menuColor;
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
    [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
    [seg addTarget:self action:@selector(aimPartChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:seg];
    y += 50;
    
    [self addSlider:width y:y label:@"📏 FOV:" value:fovSize min:30 max:300 tag:500];
}

// ====== TAB 1: VISUALS ======
- (void)drawVisualsTab {
    int y = 10;
    int width = _contentView.bounds.size.width;
    
    [self addSwitch:width y:y label:@"👁️ ESP" value:isESP tag:200];
    y += 50;
    
    [self addSwitch:width y:y label:@"📦 Box" value:espBox tag:201];
    y += 50;
    
    [self addSwitch:width y:y label:@"📏 Line" value:espLine tag:202];
    y += 50;
    
    [self addSwitch:width y:y label:@"🦴 Skeleton" value:espSkeleton tag:203];
    y += 50;
    
    // Color picker
    [self addLabel:width y:y text:@"🎨 ESP Color:"];
    UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    colorBtn.frame = CGRectMake(15, y + 30, 100, 35);
    [colorBtn setTitle:@"Chọn màu" forState:UIControlStateNormal];
    [colorBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    colorBtn.backgroundColor = menuColor;
    colorBtn.layer.cornerRadius = 8;
    [colorBtn addTarget:self action:@selector(chooseESPColor) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:colorBtn];
    
    UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(125, y + 30, 35, 35)];
    colorView.backgroundColor = espColor;
    colorView.layer.cornerRadius = 17;
    colorView.layer.borderWidth = 2;
    colorView.layer.borderColor = [UIColor whiteColor].CGColor;
    colorView.tag = 900;
    [_contentView addSubview:colorView];
    y += 80;
    
    [self addSlider:width y:y label:@"📡 Distance:" value:espDistance min:10 max:200 tag:501];
}

// ====== TAB 2: SETTINGS ======
- (void)drawSettingsTab {
    int y = 10;
    int width = _contentView.bounds.size.width;
    
    [self addSwitch:width y:y label:@"🛡️ God Mode" value:isGodMode tag:300];
    y += 50;
    
    [self addSwitch:width y:y label:@"⚡ Speed Hack" value:isSpeed tag:301];
    y += 50;
    
    [self addSlider:width y:y label:@"Speed Value:" value:speedValue min:1 max:10 tag:502];
    y += 50;
    
    [self addSwitch:width y:y label:@"🔫 No Recoil" value:isNoRecoil tag:302];
    y += 50;
    
    [self addSwitch:width y:y label:@"🔄 Fast Reload" value:isFastReload tag:303];
    y += 50;
    
    [self addSwitch:width y:y label:@"📦 Teleport" value:isTeleport tag:304];
    y += 50;
    
    [self addSwitch:width y:y label:@"💀 Kill All" value:isKillAll tag:305];
}

// ====== TAB 3: ACCOUNT ======
- (void)drawAccountTab {
    int y = 15;
    int width = _contentView.bounds.size.width;
    
    // Info Box
    UIView *infoBox = [[UIView alloc] initWithFrame:CGRectMake(15, y, width - 30, 100)];
    infoBox.backgroundColor = isDarkMode ? [UIColor colorWithWhite:0.12 alpha:1] : [UIColor colorWithWhite:0.9 alpha:1];
    infoBox.layer.cornerRadius = 12;
    infoBox.layer.borderWidth = 1;
    infoBox.layer.borderColor = menuColor.CGColor;
    [_contentView addSubview:infoBox];
    
    [self addLabelToView:infoBox x:15 y:10 text:@"📱 ACCOUNT INFO" color:menuColor font:[UIFont boldSystemFontOfSize:14]];
    [self addLabelToView:infoBox x:15 y:35 text:@"👤 User: Anonymous" color:isDarkMode ? [UIColor whiteColor] : [UIColor blackColor] font:[UIFont systemFontOfSize:13]];
    [self addLabelToView:infoBox x:15 y:55 text:@"🎯 Plan: PRO" color:isDarkMode ? [UIColor whiteColor] : [UIColor blackColor] font:[UIFont systemFontOfSize:13]];
    [self addLabelToView:infoBox x:15 y:75 text:[NSString stringWithFormat:@"⏳ Expires: %@", [self getTimeString]] color:[UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:1] font:[UIFont boldSystemFontOfSize:13]];
    y += 115;
    
    // Theme color
    [self addLabel:width y:y text:@"🎨 Theme Color:"];
    y += 30;
    
    NSArray *colors = @[
        [UIColor colorWithRed:1.0 green:0.6 blue:0.0 alpha:1], // Cam
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1], // Đỏ
        [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1], // Xanh
        [UIColor colorWithRed:1.0 green:0.0 blue:0.8 alpha:1], // Hồng
        [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1], // Xanh lá
        [UIColor colorWithRed:0.8 green:0.8 blue:0.0 alpha:1], // Vàng
    ];
    
    for (int i = 0; i < colors.count; i++) {
        UIButton *colorBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        colorBtn.frame = CGRectMake(15 + i * 48, y, 40, 40);
        colorBtn.backgroundColor = colors[i];
        colorBtn.layer.cornerRadius = 20;
        colorBtn.layer.borderWidth = 2;
        colorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        colorBtn.tag = 600 + i;
        [colorBtn addTarget:self action:@selector(themeColorChanged:) forControlEvents:UIControlEventTouchUpInside];
        [_contentView addSubview:colorBtn];
    }
    y += 55;
    
    // Dark/Light mode
    [self addSwitch:width y:y label:@"🌙 Dark Mode" value:isDarkMode tag:306];
    y += 50;
    
    // Corner radius
    [self addLabel:width y:y text:@"📐 Corner Radius:"];
    y += 30;
    UISlider *cornerSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    cornerSlider.minimumValue = 0;
    cornerSlider.maximumValue = 30;
    cornerSlider.value = menuCornerRadius;
    cornerSlider.tag = 503;
    cornerSlider.minimumTrackTintColor = menuColor;
    [cornerSlider addTarget:self action:@selector(cornerChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:cornerSlider];
    y += 50;
    
    // Logout button
    UIButton *logoutBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    logoutBtn.frame = CGRectMake(30, y, width - 60, 45);
    [logoutBtn setTitle:@"🚪 LOGOUT" forState:UIControlStateNormal];
    [logoutBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    logoutBtn.backgroundColor = [UIColor colorWithRed:0.8 green:0.0 blue:0.0 alpha:0.9];
    logoutBtn.layer.cornerRadius = 10;
    [logoutBtn addTarget:self action:@selector(logoutPressed) forControlEvents:UIControlEventTouchUpInside];
    [_contentView addSubview:logoutBtn];
}

// ====== UI HELPERS ======
- (void)addSwitch:(int)width y:(int)y label:(NSString *)label value:(BOOL)value tag:(int)tag {
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(width - 70, y, 51, 31)];
    sw.on = value;
    sw.tag = tag;
    sw.onTintColor = menuColor;
    [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:sw];
    
    [self addLabel:width y:y text:label];
}

- (void)addLabel:(int)width y:(int)y text:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, y, width - 30, 30)];
    label.text = text;
    label.textColor = isDarkMode ? [UIColor whiteColor] : [UIColor blackColor];
    label.font = [UIFont systemFontOfSize:15];
    [_contentView addSubview:label];
}

- (void)addLabelToView:(UIView *)view x:(int)x y:(int)y text:(NSString *)text color:(UIColor *)color font:(UIFont *)font {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x, y, view.bounds.size.width - x - 10, 25)];
    label.text = text;
    label.textColor = color;
    label.font = font;
    [view addSubview:label];
}

- (void)addSlider:(int)width y:(int)y label:(NSString *)label value:(float)value min:(float)min max:(float)max tag:(int)tag {
    [self addLabel:width y:y text:[NSString stringWithFormat:@"%@ %.0f", label, value]];
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(15, y + 30, width - 30, 30)];
    slider.minimumValue = min;
    slider.maximumValue = max;
    slider.value = value;
    slider.tag = tag;
    slider.minimumTrackTintColor = menuColor;
    [slider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [_contentView addSubview:slider];
}

// ====== HANDLERS ======
- (void)switchChanged:(UISwitch *)sender {
    switch (sender.tag) {
        case 100: isAimbot = sender.on; break;
        case 101: isAutoAim = sender.on; break;
        case 102: isWallHack = sender.on; break;
        case 200: isESP = sender.on; break;
        case 201: espBox = sender.on; break;
        case 202: espLine = sender.on; break;
        case 203: espSkeleton = sender.on; break;
        case 300: isGodMode = sender.on; break;
        case 301: isSpeed = sender.on; break;
        case 302: isNoRecoil = sender.on; break;
        case 303: isFastReload = sender.on; break;
        case 304: isTeleport = sender.on; break;
        case 305: isKillAll = sender.on; break;
        case 306: 
            isDarkMode = sender.on;
            [self refreshMenu];
            break;
    }
    [self saveSettings];
}

- (void)sliderChanged:(UISlider *)sender {
    switch (sender.tag) {
        case 500: fovSize = sender.value; break;
        case 501: espDistance = sender.value; break;
        case 502: speedValue = sender.value; break;
        case 503: 
            menuCornerRadius = sender.value;
            [self refreshMenu];
            break;
    }
    [self loadTab:currentTab];
    [self saveSettings];
}

- (void)aimPartChanged:(UISegmentedControl *)sender {
    aimPart = (int)sender.selectedSegmentIndex;
    [self saveSettings];
}

- (void)cornerChanged:(UISlider *)sender {
    menuCornerRadius = sender.value;
    [self refreshMenu];
}

- (void)themeColorChanged:(UIButton *)sender {
    menuColor = sender.backgroundColor;
    [self refreshMenu];
    [self saveSettings];
}

- (void)chooseESPColor {
    if (@available(iOS 14.0, *)) {
        UIColorPickerViewController *picker = [[UIColorPickerViewController alloc] init];
        picker.delegate = self;
        picker.selectedColor = espColor;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    espColor = viewController.selectedColor;
    UIView *colorView = [_contentView viewWithTag:900];
    if (colorView) colorView.backgroundColor = espColor;
    [self saveSettings];
}

- (void)logoutPressed {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"🚪 Logout" message:@"Bạn có chắc muốn đăng xuất?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self closeMenu];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

// ====== TIMER ======
- (void)startCountdown {
    countdownTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimer) userInfo:nil repeats:YES];
}

- (void)updateTimer {
    if (remainingSeconds > 0) {
        remainingSeconds--;
    }
    UILabel *timerLabel = (UILabel *)[_headerView viewWithTag:999];
    if (timerLabel) {
        timerLabel.text = [self getTimeString];
    }
}

- (NSString *)getTimeString {
    int days = remainingSeconds / 86400;
    int hours = (remainingSeconds % 86400) / 3600;
    int minutes = (remainingSeconds % 3600) / 60;
    int seconds = remainingSeconds % 60;
    return [NSString stringWithFormat:@"⏳ Expires: %dd %dh %dm %ds", days, hours, minutes, seconds];
}

// ====== SAVE SETTINGS ======
- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:isAimbot forKey:@"aim"];
    [defaults setBool:isESP forKey:@"esp"];
    [defaults setBool:isGodMode forKey:@"god"];
    [defaults setBool:isSpeed forKey:@"speed"];
    [defaults setBool:isNoRecoil forKey:@"recoil"];
    [defaults setBool:isFastReload forKey:@"reload"];
    [defaults setBool:isTeleport forKey:@"tele"];
    [defaults setBool:isKillAll forKey:@"kill"];
    [defaults setBool:isWallHack forKey:@"wall"];
    [defaults setBool:isAutoAim forKey:@"autoaim"];
    [defaults setInteger:aimPart forKey:@"aimpart"];
    [defaults setFloat:fovSize forKey:@"fov"];
    [defaults setFloat:speedValue forKey:@"speedval"];
    [defaults setFloat:espDistance forKey:@"espdist"];
    [defaults setBool:espBox forKey:@"espbox"];
    [defaults setBool:espLine forKey:@"espline"];
    [defaults setBool:espSkeleton forKey:@"espskel"];
    [defaults synchronize];
}

- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    isAimbot = [defaults boolForKey:@"aim"];
    isESP = [defaults boolForKey:@"esp"];
    isGodMode = [defaults boolForKey:@"god"];
    isSpeed = [defaults boolForKey:@"speed"];
    isNoRecoil = [defaults boolForKey:@"recoil"];
    isFastReload = [defaults boolForKey:@"reload"];
    isTeleport = [defaults boolForKey:@"tele"];
    isKillAll = [defaults boolForKey:@"kill"];
    isWallHack = [defaults boolForKey:@"wall"];
    isAutoAim = [defaults boolForKey:@"autoaim"];
    aimPart = (int)[defaults integerForKey:@"aimpart"];
    fovSize = [defaults floatForKey:@"fov"];
    speedValue = [defaults floatForKey:@"speedval"];
    espDistance = [defaults floatForKey:@"espdist"];
    espBox = [defaults boolForKey:@"espbox"];
    espLine = [defaults boolForKey:@"espline"];
    espSkeleton = [defaults boolForKey:@"espskel"];
}

// ====== REFRESH MENU ======
- (void)refreshMenu {
    [self setupMenu];
    [self loadTab:currentTab];
}

// ====== CLOSE MENU ======
- (void)closeMenu {
    menuWindow.hidden = YES;
    isMenuVisible = NO;
}

@end

// ====== HÀM MỞ MENU ======
void showMenu() {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isMenuVisible) {
            menuWindow.hidden = YES;
            isMenuVisible = NO;
            return;
        }
        
        if (!menuWindow) {
            menuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            menuWindow.windowLevel = UIWindowLevelAlert + 1;
            menuWindow.backgroundColor = [UIColor clearColor];
            menuWindow.rootViewController = [[GrannyFFMenuVC alloc] init];
            menuWindow.userInteractionEnabled = YES;
        }
        menuWindow.hidden = NO;
        isMenuVisible = YES;
        NSLog(@"📱 MENU OPENED!");
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
        
        // Thêm gesture mới: 3 ngón chạm 2 lần
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:nil action:@selector(showMenu)];
        tap.numberOfTouchesRequired = 3;
        tap.numberOfTapsRequired = 2;
        tap.cancelsTouchesInView = NO;
        [win addGestureRecognizer:tap];
    });
}

// ====== HOOK ======
static void (*orig_applicationDidFinishLaunching)(id self, SEL cmd, UIApplication *app);
static void new_applicationDidFinishLaunching(id self, SEL cmd, UIApplication *app) {
    if (orig_applicationDidFinishLaunching) {
        orig_applicationDidFinishLaunching(self, cmd, app);
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        setupGestures();
        showMenu();
    });
}

// ====== CONSTRUCTOR ======
__attribute__((constructor)) static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        Class unityClass = NSClassFromString(@"UnityAppController");
        if (unityClass) {
            Method origMethod = class_getInstanceMethod(unityClass, @selector(applicationDidFinishLaunching:));
            if (origMethod) {
                orig_applicationDidFinishLaunching = (void *)method_getImplementation(origMethod);
                method_setImplementation(origMethod, (IMP)new_applicationDidFinishLaunching);
            }
        }
        setupGestures();
        showMenu();
    });
}
