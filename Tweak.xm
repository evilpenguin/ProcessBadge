/* 
 * Name: ProcessBadge
 * Version: 0.4.0-1
 * Author: EvilPenguin (James Emrich)
 * Idea: Place a view on an application that is running. Remove the view when the application is not running.
 * Copyright (c) 2011 EvilPenguin (James Emrich)
 */

#import "ProcessBadge.h"
#import <QuartzCore/QuartzCore.h>

#define isAppEnabled(app) [runningApps containsObject:app]
#define PROCESSBADGE_ENABLED [plistDict objectForKey:@"ProcessBadgeEnabled"] ? [[plistDict objectForKey:@"ProcessBadgeEnabled"] boolValue] : YES
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
#define PROCESSBADGE_PLIST @"/var/mobile/Library/Preferences/com.understruction.processbar.plist"
#define listenToNotification$withCallBack(notification, callback); 	\
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), \
        NULL, \
        (CFNotificationCallback)&callback, \
        CFSTR(notification), \
        NULL, \
        CFNotificationSuspensionBehaviorHold);

/* ================================ Public Methods ====================================== */

static NSMutableDictionary *plistDict;
static NSMutableArray *runningApps = nil;
%class SBIconModel;

static UIColor *colorWithHexString(NSString *hexColorString) { 
    NSString *cString = [[hexColorString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];   
    if ([cString length] < 6) return [UIColor purpleColor];   
     
    unsigned int color;  
    if ([cString hasPrefix:@"#"]) { [[NSScanner scannerWithString:[cString substringFromIndex:1]] scanHexInt:&color]; } 
	else if ([cString hasPrefix:@"0X"]) { [[NSScanner scannerWithString:[cString substringFromIndex:1]] scanHexInt:&color]; } 
	else { [[NSScanner scannerWithString:cString] scanHexInt:&color]; };  
  
    return UIColorFromRGB(color);  
}


static void loadSettings() {
    NSLog(@"ProcessBadge: I take your kitties and shave them.");
	if (plistDict) {
		[plistDict release];
		plistDict = nil;
	}
	plistDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PROCESSBADGE_PLIST];
    if (plistDict == nil) { plistDict = [[NSMutableDictionary alloc] init]; }
}

static void updateSettings() {
    NSLog(@"ProcessBadge: I put the hair back on the kitties.");
	loadSettings();
	BOOL shouldRemove = NO;
	for (SBApplication *appIcon in runningApps) {
		SBIconModel *iconModel = [%c(SBIconModel) sharedInstance];
		SBApplicationIcon *icon = [iconModel applicationIconForDisplayIdentifier:[appIcon displayIdentifier]];
		UIView *badgeView = [icon viewWithTag:1000];
		if (badgeView) { 
			[badgeView removeFromSuperview];
			if (PROCESSBADGE_ENABLED) {
				setProcessBadge(appIcon, YES, NO, NO);
			}
			else { shouldRemove = YES; }
		}
	}
	if (shouldRemove) [runningApps removeAllObjects];
}

static void setProcessBadge(SBApplication *app, BOOL showBadge, BOOL addIcon, BOOL removeIcon) {
	SBIconModel *iconModel = [%c(SBIconModel) sharedInstance];
	SBApplicationIcon *icon = [iconModel applicationIconForDisplayIdentifier:[app displayIdentifier]]; 
	if (icon) {
		CGSize size = [%c(SBIcon) defaultIconSize];
		CGPoint point = CGPointMake(-12.0f, 39.0f);
	
		if (showBadge) {
			NSLog(@"Process Running: %@", [app displayIdentifier]);
			if (addIcon) [runningApps addObject:app];
			float badgeSize = [plistDict objectForKey:@"badgeSize"] ? [[plistDict objectForKey:@"badgeSize"] floatValue] : 25.0f;
			UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, badgeSize, badgeSize)];
			view.frame.origin = point;
			view.backgroundColor = colorWithHexString([plistDict objectForKey:@"badgeColor"] ? [plistDict objectForKey:@"badgeColor"] : @"333366");
	 		view.tag = 1000;
			view.alpha = [plistDict objectForKey:@"badgeAlpha"] ? [[plistDict objectForKey:@"badgeAlpha"] floatValue] : 1.0f;
			[view.layer setCornerRadius:[plistDict objectForKey:@"badgeRadius"] ? [[plistDict objectForKey:@"badgeRadius"] floatValue] : 8.0f];
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.8];
			[icon addSubview:view];
			[UIView commitAnimations];
			[view release];
		}
		else { 
			NSLog(@"Process Not Running: %@", [app displayIdentifier]);
			if (removeIcon) [runningApps removeObject:app];
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.8];
			[[icon viewWithTag:1000] removeFromSuperview];
			[UIView commitAnimations];
		}
	}
}

/* ================================ HOOKING ====================================== */

%hook SBApplication
- (void)launchSucceeded:(BOOL)succeeded {
	if (PROCESSBADGE_ENABLED) {
		if (!isAppEnabled(self)) {
			setProcessBadge(self, YES, YES, NO);
		}
	}
	%orig;
}

- (void)exitedCommon {
	if (PROCESSBADGE_ENABLED) { 
		if (isAppEnabled(self)) {
			setProcessBadge(self, NO, NO, YES);
		}
	}
	%orig;
}

/*- (void)deactivate {
	if (PROCESSBADGE_ENABLED) { 
		if (isAppEnabled(self)) {
			setProcessBadge(self, NO, NO, YES);
		}
	}
	%orig;
}*/
%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	%init;
	listenToNotification$withCallBack("com.understruction.processbar.update", updateSettings);
	loadSettings();
	runningApps = [[NSMutableSet alloc] init];
	[pool drain];
}