#import "PLSettingsViewController.h"
#import "PLCore.h"
#import "LauncherPreferences.h"
#import "utils.h"
#import "JavaLauncher.h"

@interface PLSettingsViewController ()
@property(nonatomic) UITableView *tableView;
@property(nonatomic) NSArray<NSString *> *sections;
@property(nonatomic) NSArray<NSArray *> *rows;
@end

@implementation PLSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = localize(@"preference.title", nil);
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.sections = @[@"Java", @"Video", @"Debug", @"Storage"];
    self.rows = @[
        @[@"Memory", @"Java arguments", @"Java runtime"],
        @[@"Renderer"],
        @[@"Verbose logging"],
        @[@"Game directory", @"Installed runtimes"]
    ];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.rows[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"set"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"set"];
    }
    NSString *row = self.rows[indexPath.section][indexPath.row];
    cell.textLabel.text = row;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.detailTextLabel.text = @"";

    if ([row isEqualToString:@"Memory"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld MB", (long)getPrefInt(@"java.allocated_memory")];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([row isEqualToString:@"Java arguments"]) {
        NSString *args = getPrefObject(@"java.java_args");
        cell.detailTextLabel.text = args.length > 0 ? args : @"default";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([row isEqualToString:@"Java runtime"]) {
        NSArray<NSString *> *majors = plc_installed_java_majors();
        cell.detailTextLabel.text = majors.count > 0 ? [majors componentsJoinedByString:@", "] : @"none";
    } else if ([row isEqualToString:@"Renderer"]) {
        cell.detailTextLabel.text = getPrefObject(@"video.renderer") ?: @"auto";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([row isEqualToString:@"Verbose logging"]) {
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.on = getPrefBool(@"general.debug_logging");
        [toggle addTarget:self action:@selector(toggleLogging:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else if ([row isEqualToString:@"Game directory"]) {
        cell.detailTextLabel.text = @"open";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if ([row isEqualToString:@"Installed runtimes"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)plc_installed_java_majors().count];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *row = self.rows[indexPath.section][indexPath.row];
    if ([row isEqualToString:@"Memory"]) {
        [self promptMemory];
    } else if ([row isEqualToString:@"Java arguments"]) {
        [self promptJavaArgs];
    } else if ([row isEqualToString:@"Renderer"]) {
        [self promptRenderer];
    } else if ([row isEqualToString:@"Game directory"]) {
        [self revealGameDirectory];
    }
}

- (void)toggleLogging:(UISwitch *)toggle {
    setPrefBool(@"general.debug_logging", toggle.on);
}

- (void)promptMemory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Memory" message:@"Allocated heap in MB" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.keyboardType = UIKeyboardTypeNumberPad;
        field.text = [NSString stringWithFormat:@"%ld", (long)getPrefInt(@"java.allocated_memory")];
    }];
    __weak PLSettingsViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSInteger value = alert.textFields.firstObject.text.integerValue;
        if (value < 128) {
            value = 128;
        }
        setPrefInt(@"java.allocated_memory", value);
        [weakSelf.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptJavaArgs {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Java arguments" message:@"Extra JVM flags" preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = getPrefObject(@"java.java_args");
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    __weak PLSettingsViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        setPrefObject(@"java.java_args", alert.textFields.firstObject.text ?: @"");
        [weakSelf.tableView reloadData];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)promptRenderer {
    NSArray *keys = getRendererKeys(NO);
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Renderer" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *key in keys) {
        [sheet addAction:[UIAlertAction actionWithTitle:key style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            setPrefObject(@"video.renderer", key);
            [self.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = self.view.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)revealGameDirectory {
    NSURL *url = [NSURL fileURLWithPath:plc_game_dir()];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithURL:url inMode:UIDocumentPickerModeOpen];
    [self presentViewController:picker animated:YES completion:nil];
}

@end