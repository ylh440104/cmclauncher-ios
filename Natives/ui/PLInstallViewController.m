#import "PLInstallViewController.h"
#import "PLCore.h"
#import "MinecraftResourceDownloadTask.h"
#import "utils.h"

static void *PLInstallProgressContext = &PLInstallProgressContext;

@interface PLInstallViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIActivityIndicatorView *spinner;
@property(nonatomic) UIProgressView *progressBar;
@property(nonatomic) MinecraftResourceDownloadTask *task;
@property(nonatomic) NSArray *versions;
@end

@implementation PLInstallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = localize(@"launcher.menu.install_new", nil);
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemClose target:self action:@selector(close)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.hidden = YES;
    [self.view addSubview:self.progressBar];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.spinner.translatesAutoresizingMaskIntoConstraints = NO;
    self.spinner.hidesWhenStopped = YES;
    [self.view addSubview:self.spinner];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.spinner.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.spinner.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-12],
        [self.progressBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.progressBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.progressBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8]
    ]];

    [self loadRemoteVersions];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadRemoteVersions {
    [self.spinner startAnimating];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onRemoteLoaded:) name:PLRemoteVersionsLoadedNotification object:nil];
    plc_fetch_remote_versions();
}

- (void)onRemoteLoaded:(NSNotification *)note {
    [self.spinner stopAnimating];
    self.versions = remoteVersionList.copy;
    [self.tableView reloadData];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    @try {
        [self.task.progress removeObserver:self forKeyPath:@"fractionCompleted" context:PLInstallProgressContext];
    } @catch (NSException *e) {
    }
}

#pragma mark Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.versions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rem"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"rem"];
    }
    NSDictionary *entry = self.versions[indexPath.row];
    cell.textLabel.text = entry[@"id"];
    cell.detailTextLabel.text = entry[@"type"];
    cell.imageView.image = [UIImage systemImageNamed:@"arrow.down.circle"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.task) {
        return;
    }
    NSDictionary *entry = self.versions[indexPath.row];
    [self startInstall:entry];
}

- (void)startInstall:(NSDictionary *)entry {
    self.task = [MinecraftResourceDownloadTask new];
    self.progressBar.hidden = NO;
    self.progressBar.progress = 0;
    self.tableView.userInteractionEnabled = NO;

    __weak PLInstallViewController *weakSelf = self;
    self.task.handleError = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressBar.hidden = YES;
            weakSelf.tableView.userInteractionEnabled = YES;
            weakSelf.task = nil;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Install failed" message:@"Unable to download this version" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        });
    };

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [weakSelf.task downloadVersion:entry];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.task.progress addObserver:weakSelf forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionInitial context:PLInstallProgressContext];
        });
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != PLInstallProgressContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    NSProgress *progress = (NSProgress *)object;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressBar.progress = progress.fractionCompleted;
    });
    if (!progress.finished) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.task.progress removeObserver:self forKeyPath:@"fractionCompleted" context:PLInstallProgressContext];
        BOOL hadMetadata = self.task.metadata != nil;
        self.task = nil;
        self.progressBar.hidden = YES;
        self.tableView.userInteractionEnabled = YES;
        [NSNotificationCenter.defaultCenter postNotificationName:@"PLInstallFinished" object:nil];
        if (hadMetadata) {
            [self close];
        }
    });
}

@end