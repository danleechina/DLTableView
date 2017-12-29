//
//  NormalViewController.m
//  DLTableView
//
//  Created by LiZhengDa on 2017/12/25.
//  Copyright © 2017年 Dan Lee. All rights reserved.
//

#import "NormalViewController.h"
#import "DLTableView.h"


@interface OneTableViewCell: DLTableViewCell
@property (nonatomic, strong) UIView *view;
@end
@implementation OneTableViewCell
- (instancetype)initWithStyle:(DLTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.view = [UIView new];
        self.view.backgroundColor = UIColor.brownColor;
        [self.containerView addSubview:self.view];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.view.frame;
    frame.origin.x = 10;
    frame.origin.y = 10;
    frame.size.width = 0.3 * self.frame.size.width;
    frame.size.height = 50;
    self.view.frame = frame;
}
@end

@interface TwoTableViewCell: DLTableViewCell
@property (nonatomic, strong) UIView *view;
@end
@implementation TwoTableViewCell
- (instancetype)initWithStyle:(DLTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.view = [UIView new];
        self.view.backgroundColor = UIColor.magentaColor;
        [self.containerView addSubview:self.view];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.view.frame;
    frame.origin.x = 10 + 5 + 0.3 * self.frame.size.width;
    frame.origin.y = 10;
    frame.size.width = 0.3 * self.frame.size.width;
    frame.size.height = 50;
    self.view.frame = frame;
}
@end
@interface ThreeTableViewCell: DLTableViewCell
@property (nonatomic, strong) UIView *view;
@end
@implementation ThreeTableViewCell
- (instancetype)initWithStyle:(DLTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.view = [UIView new];
        self.view.backgroundColor = UIColor.orangeColor;
        [self.containerView addSubview:self.view];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect frame = self.view.frame;
    frame.origin.x = 10 + 5 + 0.3 * self.frame.size.width * 2 + 5;
    frame.origin.y = 10;
    frame.size.width = 0.3 * self.frame.size.width;
    frame.size.height = 50;
    self.view.frame = frame;
}
@end

@interface NormalViewController ()<DLTableViewDelegate, DLTableViewDataSource>
@property (nonatomic, strong) DLTableView *tableView;
@end

@implementation NormalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[DLTableView alloc] initWithFrame:CGRectMake(0,
                                                                   64,
                                                                   CGRectGetWidth(UIScreen.mainScreen.bounds),
                                                                   CGRectGetHeight(UIScreen.mainScreen.bounds) - 64)];
    
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 60)];
    self.tableView.tableHeaderView.backgroundColor = [UIColor brownColor];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 100)];
    self.tableView.tableFooterView.backgroundColor = [UIColor grayColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.selectedColor = [[UIColor redColor] colorWithAlphaComponent:0.25];
    [self.view addSubview:self.tableView];
    [self.tableView reloadViews];
}

- (void)tableView:(DLTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAt:indexPath animated:YES];
}

- (CGFloat)tableView:(DLTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (NSInteger)tableView:(DLTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 12;
}

- (DLTableViewCell *)tableView:(DLTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *reuseId = @"";
    NSInteger index = indexPath.row % 3;
    if (index == 0) {
        reuseId = @"One";
    } else if (index == 1) {
        reuseId = @"Two";
    } else if (index == 2) {
        reuseId = @"Three";
    }
    DLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseId];
    if (cell == nil) {
        if (index == 0) {
            cell = [[OneTableViewCell alloc] initWithStyle:DLTableViewCellStyleDefault reuseIdentifier:reuseId];
        } else if (index == 1) {
            cell = [[TwoTableViewCell alloc] initWithStyle:DLTableViewCellStyleDefault reuseIdentifier:reuseId];
        } else if (index == 2) {
            cell = [[ThreeTableViewCell alloc] initWithStyle:DLTableViewCellStyleDefault reuseIdentifier:reuseId];
        }
    }
    return cell;
}

@end
