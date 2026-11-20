#import "PLPreferences.h"
#import "LauncherPreferences.h"
#import "utils.h"
#import "config.h"

static NSMutableDictionary<NSString *, NSMutableDictionary *> *CMCConfigDefaults(BOOL global) {
    NSMutableDictionary *root = [NSMutableDictionary dictionary];

    root[@"general"] = [@{
        @"check_sha": @YES,
        @"debug_logging": @(!CONFIG_RELEASE)
    } mutableCopy];
    root[@"video"] = [@{
        @"renderer": @"auto",
        @"resolution": @(100),
        @"max_framerate": @YES,
        @"performance_hud": @NO,
        @"fullscreen_airplay": @YES,
        @"silence_other_audio": @NO,
        @"silence_with_switch": @NO
    } mutableCopy];
    root[@"control"] = [@{
        @"default_ctrl": @"default.json",
        @"control_safe_area": UIApplication.sharedApplication ? NSStringFromUIEdgeInsets(getDefaultSafeArea()) : @"",
        @"default_gamepad_ctrl": @"default.json",
        @"controller_type": @"xbox",
        @"hardware_hide": @YES,
        @"recording_hide": @YES,
        @"gesture_mouse": @YES,
        @"gesture_hotbar": @YES,
        @"disable_haptics": @NO,
        @"slideable_hotbar": @NO,
        @"press_duration": @(400),
        @"button_scale": @(100),
        @"mouse_scale": @(100),
        @"mouse_speed": @(100),
        @"virtmouse_enable": @NO,
        @"gyroscope_enable": @NO,
        @"gyroscope_invert_x_axis": @NO,
        @"gyroscope_sensitivity": @(100)
    } mutableCopy];
    root[@"java"] = [@{
        @"java_homes": [@{
            @"0": [@{
                @"1_16_5_older": @"8",
                @"1_17_newer": @"17",
                @"execute_jar": @"8"
            } mutableCopy],
            @"8": @"internal",
            @"17": @"internal",
            @"21": @"internal"
        } mutableCopy],
        @"java_args": @"",
        @"env_variables": @"",
        @"auto_ram": @(!getEntitlementValue(@"com.apple.private.memorystatus")),
        @"allocated_memory": @(roundf((NSProcessInfo.processInfo.physicalMemory / 1048576) * 0.25))
    } mutableCopy];
    root[@"internal"] = [@{
        @"isolated": @NO,
        @"latest_version": [NSDictionary new]
    } mutableCopy];

    if (global) {
        [root[@"general"] addEntriesFromDictionary:@{
            @"game_directory": @"default",
            @"appicon": @"AppIcon-Light"
        }];
        root[@"java"][@"manage_runtime"] = @"";
        root[@"debug"] = [@{
            @"debug_skip_wait_jit": @NO,
            @"debug_hide_home_indicator": @NO,
            @"debug_ipad_ui": @NO,
            @"debug_auto_correction": @YES,
            @"debug_show_layout_bounds": @NO,
            @"debug_show_layout_overlap": @NO
        } mutableCopy];
        root[@"warnings"] = [@{
            @"local_warn": @YES,
            @"mem_warn": @YES,
            @"auto_ram_warn": @YES,
            @"limited_ram_warn": @YES
        } mutableCopy];
        root[@"internal"][@"selected_account"] = @"";
    }
    return root;
}

static void CMCSplitKey(NSString *key, NSString **group, NSString **name) {
    NSRange dot = [key rangeOfString:@"."];
    if (dot.location == NSNotFound) {
        *group = @"general";
        *name = key;
    } else {
        *group = [key substringToIndex:dot.location];
        *name = [key substringFromIndex:dot.location + 1];
    }
}

@implementation PLPreferences

- (id)initWithGlobalPath:(NSString *)path {
    self = [super init];
    if (self) {
        self.globalPath = path ?: [[NSString stringWithFormat:@"%s", getenv("CMC_HOME") ?: ""] stringByAppendingPathComponent:@"preferences.plist"];
        [self loadGlobal];
    }
    return self;
}

- (id)initWithAutomaticMigrator {
    self = [self initWithGlobalPath:nil];
    if (self) {
        NSString *isolated = self.globalPref[@"internal"][@"isolated"];
        if ([isolated boolValue]) {
            self.instancePath = [NSString stringWithFormat:@"%s/launcher_preferences.plist", getenv("CMC_GAME_DIR") ?: ""];
            [self loadInstance];
        }
    }
    return self;
}

- (void)loadGlobal {
    NSDictionary *stored = [NSDictionary dictionaryWithContentsOfFile:self.globalPath] ?: @{};
    NSMutableDictionary *merged = CMCConfigDefaults(YES);
    for (NSString *group in stored) {
        if ([merged[group] isKindOfClass:NSMutableDictionary.class] && [stored[group] isKindOfClass:NSDictionary.class]) {
            [merged[group] addEntriesFromDictionary:stored[group]];
        } else {
            merged[group] = [stored[group] mutableCopy];
        }
    }
    self.globalPref = merged;
}

- (void)loadInstance {
    if (!self.instancePath) {
        return;
    }
    NSDictionary *stored = [NSDictionary dictionaryWithContentsOfFile:self.instancePath] ?: @{};
    NSMutableDictionary *base = CMCConfigDefaults(NO);
    for (NSString *group in stored) {
        if ([base[group] isKindOfClass:NSMutableDictionary.class] && [stored[group] isKindOfClass:NSDictionary.class]) {
            [base[group] addEntriesFromDictionary:stored[group]];
        } else {
            base[group] = [stored[group] mutableCopy];
        }
    }
    self.instancePref = base;
}

- (NSDictionary *)activePref {
    return self.instancePref ?: self.globalPref;
}

- (void)saveGlobal {
    [self.globalPref writeToFile:self.globalPath atomically:YES];
}

- (void)saveInstance {
    if (self.instancePath && self.instancePref) {
        [self.instancePref writeToFile:self.instancePath atomically:YES];
    }
}

- (id)getObject:(NSString *)key {
    NSString *group = nil;
    NSString *name = nil;
    CMCSplitKey(key, &group, &name);

    if (self.instancePref && self.instancePref[group]) {
        id value = self.instancePref[group][name];
        if (value) {
            return value;
        }
    }
    id value = self.globalPref[group][name];
    if (value) {
        return value;
    }
    return CMCConfigDefaults(YES)[group][name];
}

- (BOOL)setObject:(NSString *)key value:(id)value {
    NSString *group = nil;
    NSString *name = nil;
    CMCSplitKey(key, &group, &name);

    NSMutableDictionary *target = nil;
    if (self.instancePref) {
        if (!self.instancePref[group]) {
            self.instancePref[group] = [NSMutableDictionary dictionary];
        }
        target = self.instancePref[group];
    } else {
        if (!self.globalPref[group]) {
            self.globalPref[group] = [NSMutableDictionary dictionary];
        }
        target = self.globalPref[group];
    }

    id previous = target[name];
    if (value == nil) {
        [target removeObjectForKey:name];
    } else {
        target[name] = value;
    }

    if (self.instancePref) {
        [self saveInstance];
    } else {
        [self saveGlobal];
    }
    return previous && ![previous isEqual:value] ? YES : NO;
}

- (void)toggleIsolationForced:(BOOL)forced {
    BOOL current = [self.globalPref[@"internal"][@"isolated"] boolValue];
    if (current == forced) {
        if (forced && !self.instancePref) {
            self.instancePath = [NSString stringWithFormat:@"%s/launcher_preferences.plist", getenv("CMC_GAME_DIR") ?: ""];
            [self loadInstance];
        }
        return;
    }
    self.globalPref[@"internal"][@"isolated"] = @(forced);
    [self saveGlobal];
    if (forced) {
        self.instancePath = [NSString stringWithFormat:@"%s/launcher_preferences.plist", getenv("CMC_GAME_DIR") ?: ""];
        [self loadInstance];
    } else {
        self.instancePref = nil;
        self.instancePath = nil;
    }
}

- (void)reset {
    self.globalPref = CMCConfigDefaults(YES);
    self.instancePref = nil;
    [self saveGlobal];
}

@end