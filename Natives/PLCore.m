#import "PLCore.h"
#import <UIKit/UIKit.h>

NSMutableArray<NSDictionary *> *localVersionList = nil;
NSMutableArray<NSDictionary *> *remoteVersionList = nil;

static plc_progress_fn g_progressFn = NULL;
static plc_state_fn g_stateFn = NULL;

void (^pl_open_game_menu)(void) = NULL;

void plc_set_progress_handler(plc_progress_fn fn) {
    g_progressFn = fn;
}

void plc_set_state_handler(plc_state_fn fn) {
    g_stateFn = fn;
}

void plc_progress(double main, double sub, NSString *text) {
    if (g_progressFn) {
        g_progressFn(main, sub, text ? text.UTF8String : "");
    }
}

void plc_state(BOOL enabled, BOOL downloading) {
    if (g_stateFn) {
        g_stateFn(enabled, downloading);
    }
}

NSString *plc_home_dir(void) {
    const char *home = getenv("CMC_HOME");
    return home ? @(home) : NSHomeDirectory();
}

NSString *plc_game_dir(void) {
    const char *dir = getenv("CMC_GAME_DIR");
    if (dir) {
        return @(dir);
    }
    return [plc_home_dir() stringByAppendingPathComponent:@"Library/Application Support/minecraft"];
}

BOOL plc_is_version_installed(NSString *versionId) {
    if (versionId.length == 0) {
        return NO;
    }
    NSString *path = [[plc_game_dir() stringByAppendingPathComponent:@"versions"] stringByAppendingPathComponent:versionId];
    BOOL isDir = NO;
    [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDir];
    return isDir;
}

void plc_fetch_local_versions(void) {
    if (!localVersionList) {
        localVersionList = [NSMutableArray new];
    }
    [localVersionList removeAllObjects];
    NSString *versionsPath = [plc_game_dir() stringByAppendingPathComponent:@"versions"];
    NSArray *entries = [NSFileManager.defaultManager contentsOfDirectoryAtPath:versionsPath error:nil];
    for (NSString *versionId in entries) {
        if (!plc_is_version_installed(versionId)) {
            continue;
        }
        [localVersionList addObject:@{@"id": versionId, @"type": @"custom"}];
    }
}

NSString * const PLRemoteVersionsLoadedNotification = @"PLRemoteVersionsLoaded";

void plc_fetch_remote_versions(void) {
    if (!remoteVersionList) {
        remoteVersionList = [NSMutableArray new];
    }
    [remoteVersionList removeAllObjects];
    [remoteVersionList addObjectsFromArray:@[
        @{@"id": @"latest-release", @"type": @"release"},
        @{@"id": @"latest-snapshot", @"type": @"snapshot"}
    ]];
    plc_progress(0.0, 0.0, @"Fetching version list");
    NSURL *url = [NSURL URLWithString:@"https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"];
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data.length > 0 && !error) {
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            NSArray *versions = json[@"versions"];
            if (versions.count > 0) {
                [remoteVersionList addObjectsFromArray:versions];
            }
            NSDictionary *latest = json[@"latest"];
            if (latest) {
                [[NSUserDefaults standardUserDefaults] setObject:latest forKey:@"internal.latest_version"];
            }
        }
        plc_progress(1.0, 0.0, @"");
        [NSNotificationCenter.defaultCenter postNotificationName:PLRemoteVersionsLoadedNotification object:nil];
    }];
    [task resume];
}

NSArray<NSString *> *plc_installed_java_majors(void) {
    NSMutableArray *result = [NSMutableArray new];
    NSString *runtimes = [[NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"java_runtimes"] copy];
    NSArray *entries = [NSFileManager.defaultManager contentsOfDirectoryAtPath:runtimes error:nil];
    for (NSString *entry in entries) {
        if (![entry hasPrefix:@"java-"] || ![entry hasSuffix:@"-openjdk"]) {
            continue;
        }
        NSString *major = [entry substringWithRange:NSMakeRange(5, entry.length - 5 - 8)];
        NSString *bin = [runtimes stringByAppendingPathComponent:entry];
        if ([NSFileManager.defaultManager fileExistsAtPath:bin]) {
            [result addObject:major];
        }
    }
    return [result sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return a.integerValue < b.integerValue ? NSOrderedAscending : NSOrderedDescending;
    }];
}

NSString *plc_java_home(NSInteger major) {
    NSArray *installed = plc_installed_java_majors();
    NSString *picked = nil;
    for (NSString *item in installed) {
        if (item.integerValue >= major) {
            picked = item;
            break;
        }
    }
    if (!picked && installed.count > 0) {
        picked = installed.lastObject;
    }
    if (!picked) {
        return nil;
    }
    return [NSString stringWithFormat:@"%@/java_runtimes/java-%@-openjdk", NSBundle.mainBundle.bundlePath, picked];
}