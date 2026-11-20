#import "PLHomeViewController.h"
#import "PLInstallViewController.h"
#import "PLCore.h"
#import "PLProfiles.h"
#import "LauncherPreferences.h"
#import "MinecraftResourceDownloadTask.h"
#import "ios_uikit_bridge.h"
#import "authenticator/BaseAuthenticator.h"
#import "utils.h"

static void *PLTaskProgressContext = &PLTaskProgressContext;

@interface PLHomeViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIProgressView *progressBar;
@property(nonatomic) UILabel *statusLabel;
@property(nonatomic) MinecraftResourceDownloadTask *task;
@property(nonatomic) NSString *launchingVersionId;
@end

@implementation PLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = localize(@"launcher.menu.select_instance", nil);
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.statusLabel.textColor = UIColor.secondaryLabelColor;
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.hidden = YES;
    [self.view addSubview:self.statusLabel];

    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.hidden = YES;
    [self.view addSubview:self.progressBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.progressBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.progressBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.progressBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.progressBar.topAnchor constant:-4]
    ]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(openInstaller)];

    [self reloadVersions];
    [self registerObservers];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadVersions];
}

- (void)registerObservers {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onInstallFinished:) name:@"PLInstallFinished" object:nil];
}

- (void)reloadVersions {
    plc_fetch_local_versions();
    [self.tableView reloadData];
    if (localVersionList.count == 0) {
        [self showEmptyHint];
    } else {
        self.tableView.backgroundView = nil;
    }
}

- (void)showEmptyHint {
    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectZero];
    hint.numberOfLines = 0;
    hint.textAlignment = NSTextAlignmentCenter;
    hint.textColor = UIColor.secondaryLabelColor;
    hint.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    hint.text = @"No version installed\nTap + to install one";
    self.tableView.backgroundView = hint;
}

- (void)openInstaller {
    if (self.task) {
        return;
    }
    PLInstallViewController *installer = [[PLInstallViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:installer];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onInstallFinished:(NSNotification *)note {
    [self reloadVersions];
}

#pragma mark Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return localVersionList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ver"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ver"];
    }
    NSDictionary *entry = localVersionList[indexPath.row];
    cell.textLabel.text = entry[@"id"];
    cell.detailTextLabel.text = entry[@"type"];
    cell.imageView.image = [UIImage systemImageNamed:@"cube.box"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.task) {
        return;
    }
    NSString *versionId = localVersionList[indexPath.row][@"id"];
    [self launchVersion:versionId];
}

#pragma mark Launch

- (void)launchVersion:(NSString *)versionId {
    if (BaseAuthenticator.current == nil) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No account" message:@"Select an account first" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    NSDictionary *entry = [remoteVersionList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(id == %@)", versionId]].firstObject;
    if (!entry) {
        entry = @{@"id": versionId, @"type": @"custom"};
    }

    self.launchingVersionId = versionId;
    self.task = [MinecraftResourceDownloadTask new];
    self.statusLabel.text = @"Preparing";
    self.statusLabel.hidden = NO;
    self.progressBar.progress = 0;
    self.progressBar.hidden = NO;

    __weak PLHomeViewController *weakSelf = self;
    self.task.handleError = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf finishLaunchUI];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Launch failed" message:@"Unable to prepare this version" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf.task downloadVersion:entry];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.task.progress addObserver:weakSelf forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionInitial context:PLTaskProgressContext];
        });
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != PLTaskProgressContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    NSProgress *progress = (NSProgress *)object;
    double fraction = progress.fractionCompleted;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBar.progress = fraction;
        if (fraction >= 1.0) {
            self.statusLabel.text = @"Starting";
        }
    });
    if (!progress.finished) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.task.progress removeObserver:self forKeyPath:@"fractionCompleted" context:PLTaskProgressContext];
        NSDictionary *metadata = self.task.metadata;
        [self finishLaunchUI];
        if (metadata) {
            UIKit_launchMinecraftSurfaceVC(self.view.window, metadata);
        }
    });
}

- (void)finishLaunchUI {
    self.statusLabel.hidden = YES;
    self.progressBar.hidden = YES;
    self.task = nil;
    self.launchingVersionId = nil;
}

- (void)dealloc {
    @try {
        [self.task.progress removeObserver:self forKeyPath:@"fractionCompleted" context:PLTaskProgressContext];
    } @catch (NSException *e) {
    }
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end