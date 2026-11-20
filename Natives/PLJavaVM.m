#import "PLJavaVM.h"
#import "PLCore.h"
#import "LauncherPreferences.h"
#import "PLProfiles.h"
#import "ios_uikit_bridge.h"
#import "utils.h"
#include <dlfcn.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include "jni.h"

typedef int (*PLJliLaunch)(int argc, char **argv,
                           int jargc, const char **jargv,
                           int appclassc, const char **appclassv,
                           const char *fullversion, const char *dotversion,
                           const char *pname, const char *lname,
                           jboolean javaargs, jboolean cpwildcard,
                           jboolean javaw, jint ergo);

static BOOL gVMRunning = NO;

@implementation PLJavaVM

+ (BOOL)isRunning {
    return gVMRunning;
}

+ (NSString *)javaHomeForVersion:(int)javaVersion error:(NSError **)error {
    NSArray<NSString *> *available = plc_installed_java_majors();
    if (available.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"cmc.java" code:1 userInfo:@{NSLocalizedDescriptionKey: @"No Java runtime installed"}];
        }
        return nil;
    }
    for (NSString *major in available) {
        if (major.intValue >= javaVersion) {
            return plc_java_home(major.intValue);
        }
    }
    return plc_java_home(available.lastObject.intValue);
}

+ (BOOL)prepareEnvironmentWithError:(NSError **)error {
    NSString *home = plc_home_dir();
    setenv("CMC_HOME", home.UTF8String, 1);
    setenv("HOME", home.UTF8String, 1);
    setenv("TMPDIR", NSTemporaryDirectory().UTF8String, 1);

    NSString *gameDir = plc_game_dir();
    setenv("CMC_GAME_DIR", gameDir.UTF8String, 1);
    [NSFileManager.defaultManager createDirectoryAtPath:gameDir withIntermediateDirectories:YES attributes:nil error:nil];

    return YES;
}

+ (int)launchWithUsername:(NSString *)username
                 versionId:(NSString *)versionId
                   width:(int)width
                  height:(int)height
              javaVersion:(int)javaVersion {
    if (gVMRunning) {
        return -1;
    }
    [self prepareEnvironmentWithError:nil];

    NSError *err = nil;
    NSString *javaHome = [self javaHomeForVersion:javaVersion error:&err];
    if (!javaHome) {
        return -2;
    }

    int allocMem = getPrefBool(@"java.auto_ram")
        ? (int)roundf((NSProcessInfo.processInfo.physicalMemory / 1048576.0) * 0.4)
        : (int)getPrefInt(@"java.allocated_memory");
    if (allocMem < 256) {
        allocMem = 256;
    }

    NSMutableArray<NSString *> *args = [NSMutableArray array];
    [args addObject:[javaHome stringByAppendingPathComponent:@"bin/java"]];
    [args addObject:@"-XstartOnFirstThread"];
    [args addObject:@"-Djava.system.class.loader=com.cmc.launcher.CMCClassLoader"];
    [args addObject:@"-Xms128M"];
    [args addObject:[NSString stringWithFormat:@"-Xmx%dM", allocMem]];
    [args addObject:[NSString stringWithFormat:@"-Djava.library.path=%@/Frameworks", NSBundle.mainBundle.bundlePath]];
    [args addObject:[NSString stringWithFormat:@"-Duser.dir=%@", plc_game_dir()]];
    [args addObject:[NSString stringWithFormat:@"-Duser.home=%@", plc_home_dir()]];
    [args addObject:[NSString stringWithFormat:@"-Duser.timezone=%@", NSTimeZone.localTimeZone.name]];
    [args addObject:[NSString stringWithFormat:@"-DUIScreen.maximumFramesPerSecond=%d", (int)UIScreen.mainScreen.maximumFramesPerSecond]];
    [args addObject:@"-Dorg.lwjgl.glfw.checkThread0=false"];
    [args addObject:@"-Dorg.lwjgl.system.allocator=system"];
    [args addObject:@"-Dlog4j2.formatMsgNoLookups=true"];
    [args addObject:@"-Dfml.earlyprogresswindow=false"];
    [args addObject:@"-XX:+UnlockExperimentalVMOptions"];
    [args addObject:@"-XX:+DisablePrimordialThreadGuardPages"];
    if (!getEntitlementValue(@"com.apple.developer.kernel.extended-virtual-addressing")) {
        [args addObject:@"-XX:-UseCompressedClassPointers"];
    }

    NSString *glLib = getPrefObject(@"video.renderer");
    if (!glLib || [glLib isEqualToString:@"auto"]) {
        glLib = @"libgl4es_114.dylib";
    }
    [args addObject:[NSString stringWithFormat:@"-Dorg.lwjgl.opengl.libname=%@", glLib]];

    NSString *libsPath = [NSBundle.mainBundle.bundlePath stringByAppendingPathComponent:@"libs"];
    [args addObject:[NSString stringWithFormat:@"-javaagent:%@/patchjna_agent.jar=", libsPath]];

    [args addObject:@"-Djava.awt.headless=false"];
    [args addObject:@"-Dcacio.font.fontmanager=sun.awt.X11FontManager"];
    [args addObject:@"-Dcacio.font.fontscaler=sun.font.FreetypeFontScaler"];
    [args addObject:[NSString stringWithFormat:@"-Dcacio.managed.screensize=%dx%d", width, height]];
    [args addObject:@"-Dswing.defaultlaf=javax.swing.plaf.metal.MetalLookAndFeel"];

    NSString *libjli = [javaHome stringByAppendingPathComponent:@"lib/jli/libjli.dylib"];
    BOOL isJava8 = [NSFileManager.defaultManager fileExistsAtPath:libjli];
    if (!isJava8) {
        libjli = [javaHome stringByAppendingPathComponent:@"lib/libjli.dylib"];
        [args addObject:@"-Dawt.toolkit=com.github.caciocavallosilano.cacio.ctc.CTCToolkit"];
        [args addObject:@"-Djava.awt.graphicsenv=com.github.caciocavallosilano.cacio.ctc.CTCGraphicsEnvironment"];
        [args addObject:@"--add-exports=java.desktop/java.awt=ALL-UNNAMED"];
        [args addObject:@"--add-exports=java.desktop/java.awt.peer=ALL-UNNAMED"];
        [args addObject:@"--add-exports=java.desktop/sun.awt=ALL-UNNAMED"];
        [args addObject:@"--add-exports=java.desktop/sun.awt.image=ALL-UNNAMED"];
        [args addObject:@"--add-exports=java.desktop/sun.java2d=ALL-UNNAMED"];
        [args addObject:@"--add-exports=java.desktop/sun.font=ALL-UNNAMED"];
    } else {
        [args addObject:@"-Dawt.toolkit=net.java.openjdk.cacio.ctc.CTCToolkit"];
        [args addObject:@"-Djava.awt.graphicsenv=net.java.openjdk.cacio.ctc.CTCGraphicsEnvironment"];
    }

    NSString *cacioDir = [NSBundle.mainBundle.bundlePath
        stringByAppendingPathComponent:(isJava8 ? @"libs_caciocavallo" : @"libs_caciocavallo17")];
    NSMutableString *cacioPath = [NSMutableString stringWithFormat:@"-Xbootclasspath/%s", isJava8 ? "p" : "a"];
    for (NSString *file in [NSFileManager.defaultManager contentsOfDirectoryAtPath:cacioDir error:nil]) {
        if ([file hasSuffix:@".jar"]) {
            [cacioPath appendFormat:@":%@/%@", cacioDir, file];
        }
    }
    [args addObject:cacioPath];

    NSString *userArgs = getPrefObject(@"java.java_args");
    if (userArgs.length > 0) {
        for (NSString *piece in [userArgs componentsSeparatedByString:@" "]) {
            if (piece.length > 0) {
                [args addObject:piece];
            }
        }
    }

    [args addObject:@"-cp"];
    [args addObject:[NSString stringWithFormat:@"%@/*", libsPath]];
    [args addObject:@"com.cmc.launcher.CMCLauncher"];
    [args addObject:username ?: @"Player"];
    [args addObject:versionId ?: @""];

    const int capacity = 512;
    char **argv = calloc(capacity, sizeof(char *));
    int argc = 0;
    for (NSString *item in args) {
        if (argc >= capacity - 1) {
            break;
        }
        argv[argc++] = strdup(item.UTF8String);
    }
    argv[argc] = NULL;

    void *handle = dlopen(libjli.UTF8String, RTLD_GLOBAL);
    if (!handle) {
        NSLog(@"[PLJavaVM] jli load failed: %s", dlerror());
        return -3;
    }
    PLJliLaunch launch = (PLJliLaunch)dlsym(handle, "JLI_Launch");
    if (!launch) {
        NSLog(@"[PLJavaVM] JLI_Launch missing");
        return -4;
    }

    signal(SIGSEGV, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGFPE, SIG_DFL);

    gVMRunning = YES;
    int rc = launch(argc, argv, 0, NULL, 0, NULL,
                    "1.8.0-internal", "1.8", "java", "openjdk",
                    JNI_FALSE, JNI_TRUE, JNI_FALSE, JNI_TRUE);
    gVMRunning = NO;
    return rc;
}

@end