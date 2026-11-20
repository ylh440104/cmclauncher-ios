#import <Foundation/Foundation.h>

extern NSMutableArray<NSDictionary *> *localVersionList;
extern NSMutableArray<NSDictionary *> *remoteVersionList;

typedef void (*plc_progress_fn)(double main, double sub, const char *text);
typedef void (*plc_state_fn)(BOOL enabled, BOOL downloading);

void plc_set_progress_handler(plc_progress_fn fn);
void plc_set_state_handler(plc_state_fn fn);
void plc_progress(double main, double sub, NSString *text);
void plc_state(BOOL enabled, BOOL downloading);
extern NSString * const PLRemoteVersionsLoadedNotification;

BOOL plc_is_version_installed(NSString *versionId);
void plc_fetch_local_versions(void);
void plc_fetch_remote_versions(void);

NSString *plc_game_dir(void);
NSString *plc_home_dir(void);
NSString *plc_java_home(NSInteger major);
NSArray<NSString *> *plc_installed_java_majors(void);
