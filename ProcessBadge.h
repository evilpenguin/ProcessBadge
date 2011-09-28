@interface SBApplicationIcon
    - (id)application;
    - (id)displayName;
    + (struct CGSize)defaultIconSize;
    - (void)addSubview:(id)view;
    - (UIView *)viewWithTag:(NSInteger)tag;
@end

@interface SBIconModel 
    + (id)sharedInstance;
    - (id)leafIconForIdentifier:(id)fp8;
    - (SBApplicationIcon *)applicationIconForDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBApplication
    - (id)process;
    - (id)displayIdentifier;
    - (void)launchSucceeded:(BOOL)succeeded;
    - (void)deactivate;
    - (void)exitedCommon;
    - (void)exitedAbnormally;
    - (void)exitedNormally;
@end

@interface SBAppSwitcherController
    - (void)applicationLaunched:(SBApplication *)application;
    - (void)applicationDied:(SBApplication *)application;
@end


// My Methods
static UIColor *colorWithHexString(NSString *hexColorString);
static void loadSettings();
static void updateSettings();
static void setProcessBadge(SBApplication *app, BOOL showBadge, BOOL addIcon, BOOL removeIcon);