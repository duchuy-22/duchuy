#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// =====================================================================
// CUNFIGURAZIONE DI LIGAME DI A BASA DI DATI REALTIME FIREBASE
// =====================================================================
static NSString *const FIREBASE_DB_URL = @"https://duchuy-75d5d-default-rtdb.firebaseio.com";
static NSString *const APP_ID = @"granny_v1_vip";

// =====================================================================
// VARIABILI DI STATU GLUBALE DI U MENU MOD
// =====================================================================
static BOOL isKeyValidated = NO;
static NSString *currentActiveKey = @"";
static NSString *usernameInfo = @"Senza registrazione";
static NSTimeInterval keyExpirationTimestamp = 0; // Timestamp di scadenza
static NSTimer *countdownTimer = nil;

// Impostazioni di u Menu & Personalizazione
static BOOL isVietnamese = YES;
static NSInteger menuStyleCorner = 1; // 0 = Angulu rettu, 1 = Angulu arrotondatu
static UIColor *menuAccentColor;
static NSInteger accentColorIndex = 0; // 0 = Aranciu, 1 = Verde, 2 = Blu

// Impostazioni di l'Aimbot
static BOOL isAimbotActive = NO;
static NSString *aimTargetPosition = @"Capu"; // Capu, Collu, Pettu, Ventre
static BOOL isAimbotAlways = NO; // NO = Solu quandu spara, YES = Sempre attivu
static BOOL isAimThroughWall = NO; // NO = Micca attraversu u muru, YES = Attraversu u muru
static float aimbotFovRadius = 120.0f;
static BOOL showFovCircle = YES;

// Impostazioni di l'ESP
static BOOL isEspActive = NO;
static BOOL isEspLines = YES;
static BOOL isEspBoxes = YES;
static BOOL isEspSkeleton = YES;
static float espMaxDistance = 250.0f;
static UIColor *espColor;
static NSInteger espColorIndex = 0; // 0 = Rossu, 1 = Verde, 2 = Giallu

// Impostazioni Diverse
static BOOL isGodMode = NO;
static BOOL isHighSpeed = NO;
static float cameraFov = 60.0f;

// Elementi di l'Interfaccia Utente
static UIWindow *overlayMenuWindow;
static UIView *menuContainer;
static UIView *authPanel;
static UIView *mainModPanel;
static UITextField *keyInputField;
static UILabel *countdownLabel;
static UILabel *userLabel;
static UILabel *keyDisplayLabel;
static CAShapeLayer *fovCircleLayer;

// =====================================================================
// FUNZIONE PER TRUVÀ A FINESTRA ATTIVA DI IOS
// =====================================================================
static UIWindow* getActiveKeyWindow() {
    UIWindow *activeWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                for (UIWindow *win in scene.windows) {
                    if (win.isKeyWindow) {
                        activeWindow = win;
                        break;
                    }
                }
            }
        }
    }
    if (!activeWindow) {
        activeWindow = [UIApplication sharedApplication].keyWindow;
    }
    return activeWindow;
}

// =====================================================================
// IMPLEMENTAZIONE DI U CONTROLLER DI U MENU PRINCIPALE
// =====================================================================
@interface HuyMenuController : UIViewController <UITextFieldDelegate>
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *contentArea;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIButton *activeTabButton;
@end

@implementation HuyMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    
    // Inizializazione di i culori predefiniti
    menuAccentColor = [UIColor colorWithRed:1.0 green:0.32 blue:0.18 alpha:1.0]; // Aranciu
    espColor = [UIColor redColor];
    
    // Creazione di u cuntituri di u menu
    menuContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 580, 320)];
    menuContainer.center = self.view.center;
    menuContainer.backgroundColor = [UIColor colorWithRed:0.07 green:0.08 blue:0.11 alpha:0.96];
    menuContainer.layer.borderWidth = 1.5;
    menuContainer.layer.borderColor = menuAccentColor.CGColor;
    [self updateMenuContainerStyle];
    [self.view addSubview:menuContainer];
    
    // Gestione di u trascinamentu di u menu
    UIPanGestureRecognizer *panDrag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuDrag:)];
    [menuContainer addGestureRecognizer:panDrag];
    
    // -----------------------------------------------------------------
    // PANNELLU DI AUTENTICAZIONE (AUTH PANEL)
    // -----------------------------------------------------------------
    authPanel = [[UIView alloc] initWithFrame:menuContainer.bounds];
    authPanel.backgroundColor = [UIColor clearColor];
    [menuContainer addSubview:authPanel];
    
    UILabel *authTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 40, 540, 30)];
    authTitle.text = @"SISTEMA DI VERIFICAZIONE DI SICUREZZA VIP";
    authTitle.textColor = menuAccentColor;
    authTitle.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
    authTitle.textAlignment = NSTextAlignmentCenter;
    [authPanel addSubview:authTitle];
    
    UILabel *authSub = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 540, 20)];
    authSub.text = @"Per piacè inserisci a chjave di attivazione furnita da l'Amministratore";
    authSub.textColor = [UIColor lightGrayColor];
    authSub.font = [UIFont systemFontOfSize:11];
    authSub.textAlignment = NSTextAlignmentCenter;
    [authPanel addSubview:authSub];
    
    keyInputField = [[UITextField alloc] initWithFrame:CGRectMake(110, 120, 360, 45)];
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
    submitBtn.frame = CGRectMake(110, 185, 360, 45);
    submitBtn.backgroundColor = menuAccentColor;
    submitBtn.layer.cornerRadius = 8;
    [submitBtn setTitle:@"ATTIVÀ AVÀ" forState:UIControlStateNormal];
    [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    submitBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [submitBtn addTarget:self action:@selector(verifyLicenseKeyOnFirebase) forState:UIControlEventTouchUpInside];
    [authPanel addSubview:submitBtn];
    
    // Nuvità di u buttone di chjusura di l'autenticazione
    UIButton *closeAuthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeAuthBtn.frame = CGRectMake(545, 10, 25, 25);
    closeAuthBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.1 blue:0.1 alpha:0.2];
    closeAuthBtn.layer.cornerRadius = 12.5;
    [closeAuthBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeAuthBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    closeAuthBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [closeAuthBtn addTarget:self action:@selector(closeMenuWithAnimation) forControlEvents:UIControlEventTouchUpInside];
    [authPanel addSubview:closeAuthBtn];
    
    // -----------------------------------------------------------------
    // PANNELLU PRINCIPALE DI E MODIFICAZIONI (MAIN MOD PANEL)
    // -----------------------------------------------------------------
    mainModPanel = [[UIView alloc] initWithFrame:menuContainer.bounds];
    mainModPanel.backgroundColor = [UIColor clearColor];
    mainModPanel.hidden = YES;
    [menuContainer addSubview:mainModPanel];
    
    // Barra laterale
    self.sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 320)];
    self.sidebar.backgroundColor = [UIColor colorWithRed:0.04 green:0.05 blue:0.08 alpha:0.98];
    [mainModPanel addSubview:self.sidebar];
    
    UILabel *sidebarLogo = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 120, 25)];
    sidebarLogo.text = @"💀 HUY VIP PRO";
    sidebarLogo.textColor = menuAccentColor;
    sidebarLogo.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
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
    
    // Caricamentu automaticu di a chjave salvata
    NSString *savedKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"huy_saved_activation_key"];
    if (savedKey && savedKey.length > 0) {
        keyInputField.text = savedKey;
        [self verifyLicenseKeyOnFirebase];
    }
}

- (void)handleMenuDrag:(UIPanGestureRecognizer *)gesture {
    CGPoint trans = [gesture translationInView:self.view];
    if (gesture.state == UIGestureRecognizerStateChanged) {
        menuContainer.center = CGPointMake(menuContainer.center.x + trans.x, menuContainer.center.y + trans.y);
        [gesture setTranslation:CGPointZero inView:self.view];
    }
}

- (void)closeMenuWithAnimation {
    [UIView animateWithDuration:0.25 animations:^{
        menuContainer.transform = CGAffineTransformMakeScale(0.7, 0.7);
        menuContainer.alpha = 0.0;
    } completion:^(BOOL finished) {
        overlayMenuWindow.hidden = YES;
    }];
}

+ (void)openMenuWithAnimation {
    overlayMenuWindow.hidden = NO;
    menuContainer.transform = CGAffineTransformMakeScale(0.6, 0.6);
    menuContainer.alpha = 0.0;
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        menuContainer.transform = CGAffineTransformIdentity;
        menuContainer.alpha = 1.0;
    } completion:nil];
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
    
    NSArray *tabNames = @[@"Aimbot", @"ESP Visuale", @"Funzioni", @"Cuntu"];
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
    [[UISelectionFeedbackGenerator new] selectionChanged];
}

// Verification de a chjave nantu à Firebase
- (void)verifyLicenseKeyOnFirebase {
    NSString *inputKey = [keyInputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (inputKey.length == 0) {
        [self showToast:@"Per piacè inserisci a chjave!"];
        return;
    }
    
    [self showToast:@"Verificazione in corsu..."];
    
    NSString *endpoint = [NSString stringWithFormat:@"%@/artifacts/%@/public/data/keys/%@.json", FIREBASE_DB_URL, APP_ID, inputKey];
    NSURL *url = [NSURL URLWithString:endpoint];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    [request setHTTPMethod:@"GET"];
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self showToast:@"Errore di cunnessione Firebase!"];
                return;
            }
            
            if (!data) {
                [self showToast:@"Chjave micca valida!"];
                return;
            }
            
            NSError *jsonErr = nil;
            NSDictionary *keyData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonErr];
            
            if (jsonErr || !keyData || [keyData isKindOfClass:[NSNull class]]) {
                [self showToast:@"A chjave ùn esiste micca!"];
                return;
            }
            
            NSString *username = keyData[@"username"] ? keyData[@"username"] : @"Utente VIP";
            NSTimeInterval expiration = [keyData[@"expiration"] doubleValue];
            NSTimeInterval currentEpoch = [[NSDate date] timeIntervalSince1970];
            
            if (expiration < currentEpoch) {
                [self showToast:@"Chjave scaduta!"];
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
            [self renderActiveTabScreen:0];
            
            [self startExpirationTimer];
            [self showToast:@"Attivazione Riesciuta!"];
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
        [self showToast:@"Chjave scaduta!"];
        return;
    }
    
    NSInteger days = (NSInteger)(remaining / (3600 * 24));
    NSInteger hours = (NSInteger)(((NSInteger)remaining % (3600 * 24)) / 3600);
    NSInteger minutes = (NSInteger)(((NSInteger)remaining % 3600) / 60);
    NSInteger seconds = (NSInteger)((NSInteger)remaining % 60);
    
    NSString *timeStr = [NSString stringWithFormat:@"%02ld ghjorni %02ld:%02ld:%02ld", (long)days, (long)hours, (long)minutes, (long)seconds];
    countdownLabel.text = [NSString stringWithFormat:@"Scade in: %@", timeStr];
}

- (void)showToast:(NSString *)msg {
    UILabel *toast = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 35)];
    toast.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 50);
    toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.9];
    toast.textColor = [UIColor whiteColor];
    toast.textAlignment = NSTextAlignmentCenter;
    toast.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
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

// Rendering di i schermi attivi
- (void)renderActiveTabScreen:(NSInteger)idx {
    for (UIView *sub in self.scrollView.subviews) {
        [sub removeFromSuperview];
    }
    
    CGFloat y = 10;
    
    if (idx == 0) {
        // TAB 0: AIMBOT
        UILabel *secHeader = [self buildSectionHeader:@"IMPOSTAZIONI AIMBOT"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *aimSw = [self buildSwitchRow:@"Attivà Aimbot" state:isAimbotActive action:^(BOOL isOn) {
            isAimbotActive = isOn;
        }];
        aimSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:aimSw];
        y += 55;
        
        UILabel *aimPosLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 150, 30)];
        aimPosLbl.text = @"Posizione di Scopu:";
        aimPosLbl.textColor = [UIColor whiteColor];
        aimPosLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:aimPosLbl];
        
        UISegmentedControl *posSeg = [[UISegmentedControl alloc] initWithItems:@[@"Capu", @"Collu", @"Pettu", @"Ventre"]];
        posSeg.frame = CGRectMake(160, y, 230, 30);
        posSeg.selectedSegmentIndex = [aimTargetPosition isEqualToString:@"Capu"] ? 0 : ([aimTargetPosition isEqualToString:@"Collu"] ? 1 : ([aimTargetPosition isEqualToString:@"Pettu"] ? 2 : 3));
        posSeg.selectedSegmentTintColor = menuAccentColor;
        [posSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [posSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [posSeg addTarget:self action:@selector(posSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:posSeg];
        y += 45;
        
        UILabel *modeLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 150, 30)];
        modeLbl.text = @"Modu di Attivazione:";
        modeLbl.textColor = [UIColor whiteColor];
        modeLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:modeLbl];
        
        UISegmentedControl *modeSeg = [[UISegmentedControl alloc] initWithItems:@[@"Spara per ghim", @"Sempre attivu"]];
        modeSeg.frame = CGRectMake(160, y, 230, 30);
        modeSeg.selectedSegmentIndex = isAimbotAlways ? 1 : 0;
        modeSeg.selectedSegmentTintColor = menuAccentColor;
        [modeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [modeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [modeSeg addTarget:self action:@selector(modeSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:modeSeg];
        y += 45;
        
        UIView *wallCheckSw = [self buildSwitchRow:@"Ghim tâm attraversu u muru" state:isAimThroughWall action:^(BOOL isOn) {
            isAimThroughWall = isOn;
        }];
        wallCheckSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:wallCheckSw];
        y += 55;
        
        UIView *fovSw = [self buildSwitchRow:@"Mostra u Cerchju FOV" state:showFovCircle action:^(BOOL isOn) {
            showFovCircle = isOn;
            [HuyMenuController drawFovCircleOnScreen];
        }];
        fovSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:fovSw];
        y += 55;
        
        UIView *fovSlider = [self buildSliderRow:@"Raghju di u Cerchju FOV" val:aimbotFovRadius min:30 max:300 unit:@"px" action:^(float newVal) {
            aimbotFovRadius = newVal;
            [HuyMenuController drawFovCircleOnScreen];
        }];
        fovSlider.frame = CGRectMake(0, y, 410, 65);
        [self.scrollView addSubview:fovSlider];
        y += 75;
        
    } else if (idx == 1) {
        // TAB 1: ESP
        UILabel *secHeader = [self buildSectionHeader:@"VISUALIZAZIONE DI L'ESP"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *espSw = [self buildSwitchRow:@"Attivà l'ESP" state:isEspActive action:^(BOOL isOn) {
            isEspActive = isOn;
        }];
        espSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espSw];
        y += 55;
        
        UIView *espLin = [self buildSwitchRow:@"Linee di l'ESP" state:isEspLines action:^(BOOL isOn) {
            isEspLines = isOn;
        }];
        espLin.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espLin];
        y += 55;
        
        UIView *espBox = [self buildSwitchRow:@"Scatuli ESP (Boxes)" state:isEspBoxes action:^(BOOL isOn) {
            isEspBoxes = isOn;
        }];
        espBox.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espBox];
        y += 55;
        
        UIView *espSke = [self buildSwitchRow:@"Scheletru ESP" state:isEspSkeleton action:^(BOOL isOn) {
            isEspSkeleton = isOn;
        }];
        espSke.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:espSke];
        y += 55;
        
        UILabel *colorLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 150, 30)];
        colorLbl.text = @"Culore di l'ESP:";
        colorLbl.textColor = [UIColor whiteColor];
        colorLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:colorLbl];
        
        UISegmentedControl *colorSeg = [[UISegmentedControl alloc] initWithItems:@[@"Rossu", @"Verde", @"Giallu"]];
        colorSeg.frame = CGRectMake(160, y, 230, 30);
        colorSeg.selectedSegmentIndex = espColorIndex;
        colorSeg.selectedSegmentTintColor = menuAccentColor;
        [colorSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [colorSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [colorSeg addTarget:self action:@selector(espColorChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:colorSeg];
        y += 45;
        
        UIView *distSlider = [self buildSliderRow:@"Distanza Massima di l'ESP" val:espMaxDistance min:50 max:1000 unit:@"m" action:^(float newVal) {
            espMaxDistance = newVal;
        }];
        distSlider.frame = CGRectMake(0, y, 410, 65);
        [self.scrollView addSubview:distSlider];
        y += 75;
        
    } else if (idx == 2) {
        // TAB 2: FUNZIONI (FEATURES)
        UILabel *secHeader = [self buildSectionHeader:@"FUNZIONI SPECIALE DI U TWEAK"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *godSw = [self buildSwitchRow:@"Modu Diu (Immunità)" state:isGodMode action:^(BOOL isOn) {
            isGodMode = isOn;
        }];
        godSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:godSw];
        y += 55;
        
        UIView *spdSw = [self buildSwitchRow:@"Velocità Superba" state:isHighSpeed action:^(BOOL isOn) {
            isHighSpeed = isOn;
        }];
        spdSw.frame = CGRectMake(0, y, 410, 45);
        [self.scrollView addSubview:spdSw];
        y += 55;
        
        UIView *fovCam = [self buildSliderRow:@"Angulu di a Camera (FOV)" val:cameraFov min:60 max:130 unit:@"°" action:^(float newVal) {
            cameraFov = newVal;
        }];
        fovCam.frame = CGRectMake(0, y, 410, 65);
        [self.scrollView addSubview:fovCam];
        y += 75;
        
        UILabel *killHeader = [self buildSectionHeader:@"UCCIDE A NANNA (KILL ENEMIES)"];
        [self.scrollView addSubview:killHeader];
        y += 35;
        
        UIButton *killBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        killBtn.frame = CGRectMake(10, y, 380, 45);
        killBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.2 blue:0.2 alpha:0.8];
        killBtn.layer.cornerRadius = 8;
        [killBtn setTitle:@"💀 UCCIDE A NANNA INSTANTANEAMENTE" forState:UIControlStateNormal];
        [killBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        killBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [killBtn addTarget:self action:@selector(killGrannyCommand) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:killBtn];
        y += 55;
        
        UILabel *uiHeader = [self buildSectionHeader:@"PERSONALIZAZIONE DI L'INTERFACCIA"];
        [self.scrollView addSubview:uiHeader];
        y += 35;
        
        UILabel *themeColorLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 150, 30)];
        themeColorLbl.text = @"Culore Principale di u Menu:";
        themeColorLbl.textColor = [UIColor whiteColor];
        themeColorLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:themeColorLbl];
        
        UISegmentedControl *themeSeg = [[UISegmentedControl alloc] initWithItems:@[@"Aranciu", @"Verde", @"Blu"]];
        themeSeg.frame = CGRectMake(160, y, 230, 30);
        themeSeg.selectedSegmentIndex = accentColorIndex;
        themeSeg.selectedSegmentTintColor = menuAccentColor;
        [themeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [themeSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [themeSeg addTarget:self action:@selector(themeSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:themeSeg];
        y += 45;
        
        UILabel *styleLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 150, 30)];
        styleLbl.text = @"Stilu di l'Anguli:";
        styleLbl.textColor = [UIColor whiteColor];
        styleLbl.font = [UIFont systemFontOfSize:13];
        [self.scrollView addSubview:styleLbl];
        
        UISegmentedControl *styleSeg = [[UISegmentedControl alloc] initWithItems:@[@"Rettu", @"Arrotondatu"]];
        styleSeg.frame = CGRectMake(160, y, 230, 30);
        styleSeg.selectedSegmentIndex = menuStyleCorner;
        styleSeg.selectedSegmentTintColor = menuAccentColor;
        [styleSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];
        [styleSeg setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateSelected];
        [styleSeg addTarget:self action:@selector(styleSegChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:styleSeg];
        y += 50;
        
    } else if (idx == 3) {
        // TAB 3: ACCOUNT
        UILabel *secHeader = [self buildSectionHeader:@"DETTAGLI DI U CUNTU VIP"];
        [self.scrollView addSubview:secHeader];
        y += 35;
        
        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(10, y, 380, 180)];
        card.backgroundColor = [UIColor colorWithRed:0.1 green:0.12 blue:0.18 alpha:0.4];
        card.layer.borderColor = menuAccentColor.CGColor;
        card.layer.borderWidth = 1.0;
        card.layer.cornerRadius = 10;
        
        userLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 350, 20)];
        userLabel.text = [NSString stringWithFormat:@"Pruprietariu: %@", usernameInfo];
        userLabel.textColor = [UIColor whiteColor];
        userLabel.font = [UIFont boldSystemFontOfSize:14];
        [card addSubview:userLabel];
        
        keyDisplayLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 45, 350, 20)];
        keyDisplayLabel.text = [NSString stringWithFormat:@"Chjave: %@", currentActiveKey];
        keyDisplayLabel.textColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
        keyDisplayLabel.font = [UIFont fontWithName:@"Courier-Bold" size:14];
        [card addSubview:keyDisplayLabel];
        
        NSDate *expDate = [NSDate dateWithTimeIntervalSince1970:keyExpirationTimestamp];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        UILabel *exactExpLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 75, 350, 20)];
        exactExpLabel.text = [NSString stringWithFormat:@"Data di Scadenza: %@", [formatter stringFromDate:expDate]];
        exactExpLabel.textColor = [UIColor lightGrayColor];
        exactExpLabel.font = [UIFont systemFontOfSize:11];
        [card addSubview:exactExpLabel];
        
        countdownLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 110, 350, 25)];
        countdownLabel.textColor = [UIColor greenColor];
        countdownLabel.font = [UIFont fontWithName:@"Courier-Bold" size:13];
        [card addSubview:countdownLabel];
        
        [self.scrollView addSubview:card];
        y += 200;
        
        [self updateCountdownRealtime];
        
        UIButton *unlinkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        unlinkBtn.frame = CGRectMake(10, y, 380, 45);
        unlinkBtn.backgroundColor = [UIColor colorWithRed:1.0 green:0.1 blue:0.1 alpha:0.15];
        unlinkBtn.layer.borderColor = [UIColor redColor].CGColor;
        unlinkBtn.layer.borderWidth = 1;
        unlinkBtn.layer.cornerRadius = 8;
        [unlinkBtn setTitle:@"🔴 DISCONNETTE A CHJAVE DA U DISPOSITIVU" forState:UIControlStateNormal];
        [unlinkBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        unlinkBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [unlinkBtn addTarget:self action:@selector(unlinkKeyAction) forControlEvents:UIControlEventTouchUpInside];
        [self.scrollView addSubview:unlinkBtn];
        y += 55;
    }
    
    self.scrollView.contentSize = CGSizeMake(410, y + 20);
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
    [self showToast:@"Chjave disconnessa cù successu!"];
}

- (void)killGrannyCommand {
    [self showToast:@"LIGAME DI UCCISIONE DI A NANNA MANDATU!"];
}

- (void)posSegChanged:(UISegmentedControl *)sender {
    NSArray *pos = @[@"Capu", @"Collu", @"Pettu", @"Ventre"];
    aimTargetPosition = pos[sender.selectedSegmentIndex];
    [[UISelectionFeedbackGenerator new] selectionChanged];
}

- (void)modeSegChanged:(UISegmentedControl *)sender {
    isAimbotAlways = (sender.selectedSegmentIndex == 1);
    [[UISelectionFeedbackGenerator new] selectionChanged];
}

- (void)espColorChanged:(UISegmentedControl *)sender {
    espColorIndex = sender.selectedSegmentIndex;
    if (espColorIndex == 0) espColor = [UIColor redColor];
    else if (espColorIndex == 1) espColor = [UIColor greenColor];
    else espColor = [UIColor yellowColor];
    [[UISelectionFeedbackGenerator new] selectionChanged];
}

- (void)themeSegChanged:(UISegmentedControl *)sender {
    accentColorIndex = sender.selectedSegmentIndex;
    if (accentColorIndex == 0) menuAccentColor = [UIColor colorWithRed:1.0 green:0.32 blue:0.18 alpha:1.0]; // Aranciu
    else if (accentColorIndex == 1) menuAccentColor = [UIColor greenColor];
    else menuAccentColor = [UIColor colorWithRed:0.0 green:0.47 blue:1.0 alpha:1.0]; // Blu
    
    menuContainer.layer.borderColor = menuAccentColor.CGColor;
    [self buildSidebarTabs];
    [self renderActiveTabScreen:2];
}

- (void)styleSegChanged:(UISegmentedControl *)sender {
    menuStyleCorner = sender.selectedSegmentIndex;
    [self updateMenuContainerStyle];
    [[UISelectionFeedbackGenerator new] selectionChanged];
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
        
        UIWindow *win = getActiveKeyWindow();
        if (!win || !showFovCircle) return;
        
        CGPoint center = win.center;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:aimbotFovRadius startAngle:0 endAngle:2 * M_PI clockwise:YES];
        
        fovCircleLayer = [CAShapeLayer layer];
        fovCircleLayer.path = path.CGPath;
        fovCircleLayer.fillColor = [UIColor clearColor].CGColor;
        fovCircleLayer.strokeColor = menuAccentColor.CGColor;
        fovCircleLayer.lineWidth = 1.0f;
        fovCircleLayer.opacity = 0.6f;
        
        [win.layer addSublayer:fovCircleLayer];
    });
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

// =====================================================================
// REGISTRAZIONE DI I GESTI (TRIPLE FINGER TAP TO SHOW/HIDE)
// =====================================================================
@interface HuyMenuInitializer : NSObject
+ (void)setupTapRecognizer;
@end

@implementation HuyMenuInitializer

+ (void)setupTapRecognizer {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *activeWin = getActiveKeyWindow();
        if (!activeWin) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [HuyMenuInitializer setupTapRecognizer];
            });
            return;
        }
        
        overlayMenuWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        overlayMenuWindow.backgroundColor = [UIColor clearColor];
        overlayMenuWindow.windowLevel = UIWindowLevelAlert + 100;
        overlayMenuWindow.hidden = YES;
        
        HuyMenuController *controller = [[HuyMenuController alloc] init];
        overlayMenuWindow.rootViewController = controller;
        
        // Cử chỉ ẩn: Nhấn 3 ngón tay 2 lần để bật menu
        UITapGestureRecognizer *tripleFingerDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleHiddenTripleFingerTap:)];
        tripleFingerDoubleTap.numberOfTouchesRequired = 3;
        tripleFingerDoubleTap.numberOfTapsRequired = 2;
        
        [activeWin addGestureRecognizer:tripleFingerDoubleTap];
    });
}

+ (void)handleHiddenTripleFingerTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        if (overlayMenuWindow.hidden) {
            [HuyMenuController openMenuWithAnimation];
            [HuyMenuController drawFovCircleOnScreen];
        }
    }
}

@end

__attribute__((constructor)) static void initialize() {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
        [HuyMenuInitializer setupTapRecognizer];
    }];
}

