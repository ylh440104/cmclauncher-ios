#import "PLHomeViewController.h"
#import "PLInstallViewController.h"
#import "PLTheme.h"
#import "PLCore.h"
#import "PLProfiles.h"
#import "LauncherPreferences.h"
#import "MinecraftResourceDownloadTask.h"
#import "ios_uikit_bridge.h"
#import "authenticator/BaseAuthenticator.h"

static void *PLTaskProgressContext = &PLTaskProgressContext;

@interface PLVersionCell : UITableViewCell
@property(nonatomic) UIView *card;
@property(nonatomic) UIView *badge;
@property(nonatomic) UIImageView *badgeIcon;
@property(nonatomic) UILabel *nameLabel;
@property(nonatomic) UILabel *metaLabel;
@property(nonatomic) UILabel *typePill;
@property(nonatomic) UIImageView *chevron;
- (void)applyVersion:(NSDictionary *)entry;
@end

@implementation PLVersionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) {
        return nil;
    }
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.contentView.backgroundColor = UIColor.clearColor;

    _card = [[UIView alloc] initWithFrame:CGRectZero];
    _card.translatesAutoresizingMaskIntoConstraints = NO;
    [PLTheme applyCardStyle:_card];
    [self.contentView addSubview:_card];

    _badge = [[UIView alloc] initWithFrame:CGRectZero];
    _badge.translatesAutoresizingMaskIntoConstraints = NO;
    _badge.backgroundColor = [PLTheme accentSoft];
    _badge.layer.cornerRadius = 13.0;
    _badge.layer.cornerCurve = kCACornerCurveContinuous;
    [_card addSubview:_badge];

    _badgeIcon = [[UIImageView alloc] initWithImage:[PLTheme symbol:@"cube.fill" pointSize:22]];
    _badgeIcon.translatesAutoresizingMaskIntoConstraints = NO;
    _badgeIcon.tintColor = [PLTheme accent];
    _badgeIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_badge addSubview:_badgeIcon];

    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [PLTheme headlineFont];
    _nameLabel.textColor = [PLTheme primaryText];
    [_card addSubview:_nameLabel];

    _metaLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _metaLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _metaLabel.font = [PLTheme captionFont];
    _metaLabel.textColor = [PLTheme secondaryText];
    [_card addSubview:_metaLabel];

    _typePill = [[UILabel alloc] initWithFrame:CGRectZero];
    _typePill.translatesAutoresizingMaskIntoConstraints = NO;
    _typePill.textAlignment = NSTextAlignmentCenter;
    _typePill.layer.cornerRadius = 7.0;
    _typePill.layer.cornerCurve = kCACornerCurveContinuous;
    _typePill.layer.masksToBounds = YES;
    [_card addSubview:_typePill];

    _chevron = [[UIImageView alloc] initWithImage:[PLTheme symbol:@"chevron.right" pointSize:13 weight:UIFontWeightBold]];
    _chevron.translatesAutoresizingMaskIntoConstraints = NO;
    _chevron.tintColor = [PLTheme secondaryText];
    _chevron.contentMode = UIViewContentModeScaleAspectFit;
    [_card addSubview:_chevron];

    [NSLayoutConstraint activateConstraints:@[
        [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:5],
        [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-5],
        [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:[PLTheme gutter]],
        [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-[PLTheme gutter]],

        [_badge.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:14],
        [_badge.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_badge.widthAnchor constraintEqualToConstant:46],
        [_badge.heightAnchor constraintEqualToConstant:46],

        [_badgeIcon.centerXAnchor constraintEqualToAnchor:_badge.centerXAnchor],
        [_badgeIcon.centerYAnchor constraintEqualToAnchor:_badge.centerYAnchor],
        [_badgeIcon.widthAnchor constraintEqualToConstant:24],
        [_badgeIcon.heightAnchor constraintEqualToConstant:24],

        [_nameLabel.leadingAnchor constraintEqualToAnchor:_badge.trailingAnchor constant:13],
        [_nameLabel.topAnchor constraintEqualToAnchor:_card.topAnchor constant:15],
        [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_chevron.leadingAnchor constant:-8],

        [_metaLabel.leadingAnchor constraintEqualToAnchor:_nameLabel.leadingAnchor],
        [_metaLabel.topAnchor constraintEqualToAnchor:_nameLabel.bottomAnchor constant:3],
        [_metaLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_typePill.leadingAnchor constant:-8],

        [_typePill.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_typePill.trailingAnchor constraintEqualToAnchor:_chevron.leadingAnchor constant:-10],
        [_typePill.widthAnchor constraintGreaterThanOrEqualToConstant:56],
        [_typePill.heightAnchor constraintEqualToConstant:22],

        [_chevron.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-14],
        [_chevron.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_chevron.widthAnchor constraintEqualToConstant:9],
        [_chevron.heightAnchor constraintEqualToConstant:15]
    ]];

    return self;
}

- (void)applyVersion:(NSDictionary *)entry {
    NSString *versionId = entry[@"id"] ?: @"unknown";
    NSString *type = entry[@"type"] ?: @"custom";
    self.nameLabel.text = versionId;
    self.metaLabel.text = [plc_game_dir() stringByAppendingPathComponent:@"versions"];

    UIColor *pillColor = [PLTheme secondaryText];
    if ([type isEqualToString:@"release"]) {
        pillColor = [PLTheme success];
    } else if ([type isEqualToString:@"snapshot"]) {
        pillColor = [PLTheme warning];
    } else if ([type isEqualToString:@"custom"]) {
        pillColor = [PLTheme accent];
    }
    self.typePill.text = [type uppercaseString];
    [PLTheme applyPillStyle:self.typePill color:pillColor];
    self.typePill.font = [PLTheme captionFont];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.card.transform = highlighted ? CGAffineTransformMakeScale(0.975, 0.975) : CGAffineTransformIdentity;
        self.card.layer.shadowOpacity = highlighted ? 0.02 : 0.05;
    } completion:nil];
}

@end

@interface PLHomeViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIView *heroCard;
@property(nonatomic) UILabel *heroTitle;
@property(nonatomic) UILabel *heroSubtitle;
@property(nonatomic) UILabel *statusLabel;
@property(nonatomic) UIProgressView *progressBar;
@property(nonatomic) MinecraftResourceDownloadTask *task;
@property(nonatomic) UIView *emptyView;
@end

@implementation PLHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLTheme canvas];
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.title = @"Instances";
    self.navigationController.navigationBar.tintColor = [PLTheme accent];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 96, 0);
    if (@available(iOS 15.0, *)) {
        self.tableView.sectionHeaderTopPadding = 0;
    }
    [self.view addSubview:self.tableView];

    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.statusLabel.font = [PLTheme captionFont];
    self.statusLabel.textColor = [PLTheme secondaryText];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.hidden = YES;
    [self.view addSubview:self.statusLabel];

    self.progressBar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressBar.progressTintColor = [PLTheme accent];
    self.progressBar.trackTintColor = [PLTheme hairline];
    self.progressBar.layer.cornerRadius = 2.0;
    self.progressBar.layer.masksToBounds = YES;
    self.progressBar.hidden = YES;
    [self.view addSubview:self.progressBar];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.progressBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:[PLTheme gutter]],
        [self.progressBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-[PLTheme gutter]],
        [self.progressBar.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-14],
        [self.progressBar.heightAnchor constraintEqualToConstant:4],

        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:[PLTheme gutter]],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-[PLTheme gutter]],
        [self.statusLabel.bottomAnchor constraintEqualToAnchor:self.progressBar.topAnchor constant:-7]
    ]];

    UIImage *plus = [PLTheme symbol:@"plus" pointSize:17 weight:UIFontWeightBold];
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:plus style:UIBarButtonItemStylePlain target:self action:@selector(openInstaller)];
    self.navigationItem.rightBarButtonItem = add;

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onInstallFinished:) name:@"PLInstallFinished" object:nil];
    [self reloadVersions];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadVersions];
}

- (void)reloadVersions {
    plc_fetch_local_versions();
    [self.tableView reloadData];
    self.emptyView.hidden = localVersionList.count > 0;
    self.tableView.backgroundView = localVersionList.count > 0 ? nil : [self buildEmptyState];
}

- (UIView *)buildEmptyState {
    if (self.emptyView) {
        return self.emptyView;
    }
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 320)];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[PLTheme symbol:@"square.stack.3d.up.slash" pointSize:52 weight:UIFontWeightRegular]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [[PLTheme secondaryText] colorWithAlphaComponent:0.55];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    [container addSubview:icon];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectZero];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"No instances yet";
    title.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    title.textColor = [PLTheme primaryText];
    title.textAlignment = NSTextAlignmentCenter;
    [container addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectZero];
    detail.translatesAutoresizingMaskIntoConstraints = NO;
    detail.text = @"Install a version to get started";
    detail.font = [PLTheme bodyFont];
    detail.textColor = [PLTheme secondaryText];
    detail.textAlignment = NSTextAlignmentCenter;
    detail.numberOfLines = 0;
    [container addSubview:detail];

    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-52],
        [icon.widthAnchor constraintEqualToConstant:56],
        [icon.heightAnchor constraintEqualToConstant:56],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:20],
        [title.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:20],
        [title.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-20],
        [detail.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:7],
        [detail.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:24],
        [detail.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-24]
    ]];

    self.emptyView = container;
    return container;
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return localVersionList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 78.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLVersionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ver"];
    if (!cell) {
        cell = [[PLVersionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ver"];
    }
    [cell applyVersion:localVersionList[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.task) {
        return;
    }
    [self launchVersion:localVersionList[indexPath.row][@"id"]];
}

- (void)launchVersion:(NSString *)versionId {
    if (BaseAuthenticator.current == nil) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No account selected"
                                                                      message:@"Pick an account before launching"
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    NSDictionary *entry = [remoteVersionList filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(id == %@)", versionId]].firstObject;
    if (!entry) {
        entry = @{@"id": versionId, @"type": @"custom"};
    }

    self.task = [MinecraftResourceDownloadTask new];
    [self setWorking:YES text:@"Preparing"];

    __weak PLHomeViewController *weakSelf = self;
    self.task.handleError = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf setWorking:NO text:nil];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Launch failed"
                                                                          message:@"Unable to prepare this version"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
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

- (void)setWorking:(BOOL)working text:(NSString *)text {
    self.statusLabel.hidden = !working;
    self.progressBar.hidden = !working;
    self.statusLabel.text = text;
    if (!working) {
        self.progressBar.progress = 0;
    }
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
        [self setWorking:NO text:nil];
        self.task = nil;
        if (metadata) {
            UIKit_launchMinecraftSurfaceVC(self.view.window, metadata);
        }
    });
}

- (void)dealloc {
    @try {
        [self.task.progress removeObserver:self forKeyPath:@"fractionCompleted" context:PLTaskProgressContext];
    } @catch (NSException *e) {
    }
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end