//
//  CycleViewController.m
//  DLTableView
//
//  Created by LiZhengDa on 2017/12/25.
//  Copyright © 2017年 Dan Lee. All rights reserved.
//

#import "CycleViewController.h"
#import "DLTableView.h"

@interface CycleViewController ()<DLTableViewDelegate, DLTableViewDataSource>
@property (nonatomic, strong) DLTableView *tableView;
@end

@implementation CycleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tableView = [[DLTableView alloc] initWithFrame:CGRectMake(0,
                                                                   64,
                                                                   CGRectGetWidth(UIScreen.mainScreen.bounds),
                                                                   CGRectGetHeight(UIScreen.mainScreen.bounds) - 64)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.enableCycleScroll = YES;
    [self.view addSubview:self.tableView];
    [self.tableView reloadViews];
}

- (void)tableView:(DLTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index {
    [tableView deselectRowAtIndexPath:indexPath withInternalIndex:index animated:indexPath];
    [tableView scrollToRowAtIndexPath:indexPath withInternalIndex:index atScrollPosition:DLTableViewScrollPositionMiddle animated:YES];
    NSLog(@"%ld", (long)indexPath.row);
}

- (NSInteger)tableView:(DLTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (DLTableViewCell *)tableView:(DLTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (cell == nil) {
        cell = [[DLTableViewCell alloc] initWithStyle:DLTableViewCellStyleDefault reuseIdentifier:@"CELL"];
    }
    cell.titleLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
    cell.backgroundColor = [UIColor colorWithRed:random() / (CGFloat)RAND_MAX
                                           green:random() / (CGFloat)RAND_MAX
                                            blue:random() / (CGFloat)RAND_MAX
                                           alpha:1.0f];
    return cell;
}

@end
