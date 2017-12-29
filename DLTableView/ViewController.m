//
//  ViewController.m
//  DLTableView
//
//  Created by LiZhengDa on 2017/12/25.
//  Copyright © 2017年 Dan Lee. All rights reserved.
//

#import "ViewController.h"
#import "CycleViewController.h"
#import "NormalViewController.h"
#import "DLTableView.h"

@interface ViewController ()<DLTableViewDelegate, DLTableViewDataSource>
@property (nonatomic, strong) DLTableView *tableView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[DLTableView alloc] initWithFrame:CGRectMake(0,
                                                                   64,
                                                                   CGRectGetWidth(UIScreen.mainScreen.bounds),
                                                                   CGRectGetHeight(UIScreen.mainScreen.bounds) - 64)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.selectedColor = [[UIColor redColor] colorWithAlphaComponent:0.25];
    [self.view addSubview:self.tableView];
    [self.tableView reloadViews];
}

- (void)tableView:(DLTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%ld", (long)indexPath.row);
    [tableView deselectRowAt:indexPath animated:YES];
    if (indexPath.row == 0) {
        [self.navigationController pushViewController:[CycleViewController new] animated:YES];
    } else {
        [self.navigationController pushViewController:[NormalViewController new] animated:YES];
    }
}


- (NSInteger)tableView:(DLTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (DLTableViewCell *)tableView:(DLTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DLTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CELL"];
    if (cell == nil) {
        cell = [[DLTableViewCell alloc] initWithStyle:DLTableViewCellStyleDefault reuseIdentifier:@"CELL"];
    }
    if (indexPath.row == 0) {
        cell.titleLabel.text = @"无限循环滚动";
    } else {
        cell.titleLabel.text = @"自定义多种 Cell";
    }
    return cell;
}

@end
