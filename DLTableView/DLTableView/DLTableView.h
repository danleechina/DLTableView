//
//  DLTableView.h
//  WMPayDayLoan
//
//  Created by LiZhengDa on 2017/12/25.
//  Copyright © 2017年 Dan Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DLTableViewScrollPosition) {
    DLTableViewScrollPositionTop,
    DLTableViewScrollPositionMiddle,
    DLTableViewScrollPositionBottom,
};

typedef NS_ENUM(NSUInteger, DLTableViewCellStyle) {
    DLTableViewCellStyleCustom,
    DLTableViewCellStyleDefault,
};

@interface UIView(DL_ADD)
@property (nonatomic, assign) NSInteger dl_tag;
- (NSArray<UIView *> *)dl_whichSubviewContains:(CGPoint)point;
- (void)dl_removeAllSubviews;
@end

@interface DLTableViewCell : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *containerView;
- (instancetype)initWithStyle:(DLTableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
@end

@protocol DLTableViewDelegate;
@protocol DLTableViewDataSource;

@interface DLTableView : UIScrollView
@property (nonatomic, strong) UIView *containerView;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wobjc-property-synthesis"
@property (nonatomic, weak) id<DLTableViewDelegate> delegate;
#pragma clang diagnostic pop
@property (nonatomic, weak) id<DLTableViewDataSource> dataSource;
@property (nonatomic, strong) NSMutableArray<DLTableViewCell *> *visibileCells;
@property (nonatomic, strong) NSMutableArray<NSIndexPath *> *visibileCellsIndexPath;
@property (nonatomic, strong) UIColor *selectedColor;
@property (nonatomic, copy) void(^layout)(DLTableView *tableView);
@property (nonatomic, assign) BOOL enableCycleScroll;
@property (nonatomic, strong) UIView *tableHeaderView;
@property (nonatomic, strong) UIView *tableFooterView;

- (DLTableViewCell *)cellForRowAt:(NSIndexPath *)indexPath;
- (void)reloadViews;
- (void)reloadData;
- (void)deselectRowAt:(NSIndexPath *)indexPath animated:(BOOL)animated;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index animated:(BOOL)animated;
- (DLTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (void)scrollToRowAt:(NSIndexPath *)indexPath at:(DLTableViewScrollPosition)scrollPosition animated:(BOOL)animated;
-(void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index atScrollPosition:(DLTableViewScrollPosition)scrollPosition animated:(BOOL)animated;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;
@end

@protocol DLTableViewDelegate<UIScrollViewDelegate>
@optional
- (void)tableView:(DLTableView *)tableView didEndDisplayingCell:(DLTableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath;
- (CGFloat)tableView:(DLTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(DLTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(DLTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index;
@end

@protocol DLTableViewDataSource<NSObject>
@required
- (NSInteger)tableView:(DLTableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (DLTableViewCell *)tableView:(DLTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end
