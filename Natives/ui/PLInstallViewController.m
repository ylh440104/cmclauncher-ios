#import "PLInstallViewController.h"
#import "PLTheme.h"
#import "PLCore.h"
#import "MinecraftResourceDownloadTask.h"

static void *PLInstallProgressContext = &PLInstallProgressContext;

@interface PLRemoteCell : UITableViewCell
@property(nonatomic) UIView *card;
@property(nonatomic) UILabel *nameLabel;
@property(nonatomic) UILabel *typePill;
@property(nonatomic) UIImageView *action;
- (void)applyVersion:(NSDictionary *)entry;
@end

@implementation PLRemoteCell

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

    _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _nameLabel.font = [PLTheme headlineFont];
    _nameLabel.textColor = [PLTheme primaryText];
    [_card addSubview:_nameLabel];

    _typePill = [[UILabel alloc] initWithFrame:CGRectZero];
    _typePill.translatesAutoresizingMaskIntoConstraints = NO;
    _typePill.textAlignment = NSTextAlignmentCenter;
    _typePill.layer.cornerRadius = 7.0;
    _typePill.layer.cornerCurve = kCACornerCurveContinuous;
    _typePill.layer.masksToBounds = YES;
    [_card addSubview:_typePill];

    _action = [[UIImageView alloc] initWithImage:[PLTheme symbol:@"arrow.down.circle.fill" pointSize:22]];
    _action.translatesAutoresizingMaskIntoConstraints = NO;
    _action.tintColor = [PLTheme accent];
    _action.contentMode = UIViewContentModeScaleAspectFit;
    [_card addSubview:_action];

    [NSLayoutConstraint activateConstraints:@[
        [_card.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:4],
        [_card.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-4],
        [_card.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:[PLTheme gutter]],
        [_card.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-[PLTheme gutter]],

        [_nameLabel.leadingAnchor constraintEqualToAnchor:_card.leadingAnchor constant:16],
        [_nameLabel.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_typePill.leadingAnchor constant:-8],

        [_typePill.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_typePill.trailingAnchor constraintEqualToAnchor:_action.leadingAnchor constant:-10],
        [_typePill.widthAnchor constraintGreaterThanOrEqualToConstant:58],
        [_typePill.heightAnchor constraintEqualToConstant:22],

        [_action.trailingAnchor constraintEqualToAnchor:_card.trailingAnchor constant:-16],
        [_action.centerYAnchor constraintEqualToAnchor:_card.centerYAnchor],
        [_action.widthAnchor constraintEqualToConstant:22],
        [_action.heightAnchor constraintEqualToConstant:22]
    ]];

    return self;
}

- (void)applyVersion:(NSDictionary *)entry {
    NSString *type = entry[@"type"] ?: @"custom";
    self.nameLabel.text = entry[@"id"];

    UIColor *color = [PLTheme secondaryText];
    if ([type isEqualToString:@"release"]) {
        color = [PLTheme success];
    } else if ([type isEqualToString:@"snapshot"]) {
        color = [PLTheme warning];
    } else if ([type isEqualToString:@"old_beta"] || [type isEqualToString:@"old_alpha"]) {
        color = [PLTheme secondaryText];
    }
    self.typePill.text = [type uppercaseString];
    [PLTheme applyPillStyle:self.typePill color:color];
    self.typePill.font = [PLTheme captionFont];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [UIView animateWithDuration:0.16 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.card.transform = highlighted ? CGAffineTransformMakeScale(0.975, 0.975) : CGAffineTransformIdentity;
    } completion:nil];
}

@end

@interface PLInstallViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) UIActivityIndicatorView *spinner;
@property(nonatomic) UILabel *hintLabel;
@property(nonatomic) UIView *loadingView;
@property(nonatomic) UIView *progressPanel;
@property(nonatomic) UIProgressView *progressBar;
@property(nonatomic) UILabel *progressLabel;
@property(nonatomic) MinecraftResourceDownloadTask *task;
@property(nonatomic) NSArray *versions;
@end

@implementation PLInstallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [PLTheme canvas];
    self.navigationItem.title = @"Install";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[PLTheme symbol:@"xmark" pointSize:16 weight:UIFontWeightBold]
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(close)];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.contentInset = UIEdgeInsetsMake(4, 0, 40, 0);
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    [self buildLoadingView];
    [self buildProgressPanel];
    [self loadRemoteVersions];
}

- (void)buildLoadingView {
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];
    container.translatesAutoresizingMaskIntoConstraints = NO;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    spinner.color = [PLTheme accent];
    [spinner startAnimating];
    [container addSubview:spinner];

    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectZero];
    hint.translatesAutoresizingMaskIntoConstraints = NO;
    hint.text = @"Loading version list";
    hint.font = [PLTheme captionFont];
    hint.textColor = [PLTheme secondaryText];
    hint.textAlignment = NSTextAlignmentCenter;
    [container addSubview:hint];

    [NSLayoutConstraint activateConstraints:@[
        [spinner.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:container.centerYAnchor constant:-14],
        [hint.topAnchor constraintEqualToAnchor:spinner.bottomAnchor constant:10],
        [hint.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [hint.trailingAnchor constraintEqualToAnchor:container.trailingAnchor]
    ]];

    self.loadingView = container;
    self.spinner = spinner;
    self.hintLabel = hint;
    self.tableView.backgroundView = container;
}

- (void)buildProgressPanel {
    UIView *panel = [[UIView alloc] initWithFrame:CGRectZero];
    panel.translatesAutoresizingMaskIntoConstraints = NO;
    [PLTheme applyCardStyle:panel];
    panel.hidden = YES;
    [self.view addSubview:panel];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Downloading";
    label.font = [PLTheme captionFont];
    label.textColor = [PLTheme secondaryText];
    [panel addSubview:label];

    UIProgressView *bar = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    bar.translatesAutoresizingMaskIntoConstraints = NO;
    bar.progressTintColor = [PLTheme accent];
    bar.trackTintColor = [PLTheme hairline];
    bar.layer.cornerRadius = 2.0;
    bar.layer.masksToBounds = YES;
    [panel addSubview:bar];

    [NSLayoutConstraint activateConstraints:@[
        [panel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:[PLTheme gutter]],
        [panel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-[PLTheme gutter]],
        [panel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [panel.heightAnchor constraintEqualToConstant:64],

        [label.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16],
        [label.topAnchor constraintEqualToAnchor:panel.topAnchor constant:13],

        [bar.leadingAnchor constraintEqualToAnchor:panel.leadingAnchor constant:16],
        [bar.trailingAnchor constraintEqualToAnchor:panel.trailingAnchor constant:-16],
        [bar.topAnchor constraintEqualToAnchor:label.bottomAnchor constant:9],
        [bar.heightAnchor constraintEqualToConstant:4]
    ]];

    self.progressPanel = panel;
    self.progressLabel = label;
    self.progressBar = bar;
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadRemoteVersions {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onRemoteLoaded:) name:PLRemoteVersionsLoadedNotification object:nil];
    plc_fetch_remote_versions();
}

- (void)onRemoteLoaded:(NSNotification *)note {
    [self.spinner stopAnimating];
    self.versions = remoteVersionList.copy;
    self.tableView.backgroundView = self.versions.count > 0 ? nil : [self buildEmptyLabel];
    [self.tableView reloadData];
}

- (UIView *)buildEmptyLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 300, 120)];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [PLTheme bodyFont];
    label.textColor = [PLTheme secondaryText];
    label.text = @"Version list unavailable\nCheck your connection";
    return label;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    @try {
        [self.task.progress removeObserver:self forKeyPath:@"fractionCompleted" context:PLInstallProgressContext];
    } @catch (NSException *e) {
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.versions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PLRemoteCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rem"];
    if (!cell) {
        cell = [[PLRemoteCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"rem"];
    }
    [cell applyVersion:self.versions[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (self.task) {
        return;
    }
    [self startInstall:self.versions[indexPath.row]];
}

- (void)startInstall:(NSDictionary *)entry {
    self.task = [MinecraftResourceDownloadTask new];
    self.progressPanel.hidden = NO;
    self.progressLabel.text = [NSString stringWithFormat:@"Downloading %@", entry[@"id"]];
    self.progressBar.progress = 0;
    self.tableView.userInteractionEnabled = NO;

    __weak PLInstallViewController *weakSelf = self;
    self.task.handleError = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressPanel.hidden = YES;
            weakSelf.tableView.userInteractionEnabled = YES;
            weakSelf.task = nil;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Install failed"
                                                                          message:@"Unable to download this version"
                                                                   preferredStyle:UIAlertControllerStyleAlert];
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
        BOOL succeeded = self.task.metadata != nil;
        self.task = nil;
        self.progressPanel.hidden = YES;
        self.tableView.userInteractionEnabled = YES;
        [NSNotificationCenter.defaultCenter postNotificationName:@"PLInstallFinished" object:nil];
        if (succeeded) {
            [self close];
        }
    });
}

@end