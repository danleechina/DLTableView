//
//  DLTableView.m
//  WMPayDayLoan
//
//  Created by LiZhengDa on 2017/12/25.
//  Copyright © 2017年 Dan Lee. All rights reserved.
//

#import "DLTableView.h"
#import <objc/runtime.h>

#pragma mark - UIView(DL_ADD)

@implementation UIView (DL_ADD)

static int _DLViewTagKey;
- (void)setDl_tag:(NSInteger)dl_tag {
    objc_setAssociatedObject(self, &_DLViewTagKey, @(dl_tag), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSInteger)dl_tag {
    NSNumber *tag = objc_getAssociatedObject(self, &_DLViewTagKey);
    return tag.integerValue;
}

- (NSArray<UIView *> *)dl_whichSubviewContains:(CGPoint)point {
    NSMutableArray *ret = [NSMutableArray arrayWithCapacity:self.subviews.count];
    for (UIView *view in self.subviews) {
        if (CGRectContainsPoint(view.frame, point)) {
            [ret addObject:view];
        }
    }
    return ret.copy;
}

- (void)dl_removeAllSubviews {
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

@end

#pragma mark - DLTableViewCell

@interface DLTableViewCell()<UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIView *selectedBackgroundColorView;
@property (nonatomic, copy) NSString *reuseID;
@end

@implementation DLTableViewCell

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.titleLabel.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.containerView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.selectedBackgroundColorView.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self customStyle];
    }
    return self;
}

- (instancetype)initWithStyle:(DLTableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        [self customStyle];
        self.titleLabel.hidden = style == DLTableViewCellStyleCustom;
        self.reuseID = reuseIdentifier;
    }
    return self;
}

- (void)customStyle {
    self.selectedBackgroundColorView = [UIView new];
    self.selectedBackgroundColorView.hidden = YES;
    self.selectedBackgroundColorView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.9];
    self.titleLabel = [UILabel new];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.textColor = [UIColor blueColor];
    self.containerView = [UIView new];
    [self.containerView addSubview:self.titleLabel];
    [self addSubview:self.containerView];
    [self addSubview:self.selectedBackgroundColorView];
}

@end

#define DLTableViewCellDidChange @"DLTableViewCellDidChange"
static CGFloat DefaultCellLength = 64;

@interface DLTableView()
@property (nonatomic, strong) NSMutableSet<DLTableViewCell *> *reuseCellsSet;
@property (nonatomic, strong) UITapGestureRecognizer *tapGest;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGest;
@property (nonatomic, strong) DLTableViewCell *pressedCell;
@property (nonatomic, assign) CGPoint lastTouchPoint;
@end

@implementation DLTableView

#pragma mark - Implement

- (void)layoutSubviews {
    [super layoutSubviews];
    [self recenterIfNecessary];
    [self tileCellsInVisibleBounds:[self convertRect:self.bounds toView:self.containerView]];
    if (self.layout) {
        self.layout(self);
    }
}

- (void)recenterIfNecessary {
    if (!self.enableCycleScroll) {
        return;
    }
    CGPoint currentOffset = self.contentOffset;
    CGFloat contentLength = self.contentSize.height;
    CGFloat centerOffsetY = (contentLength - self.bounds.size.height) / 2;
    CGFloat distanceFromCenterY = fabs(currentOffset.y - centerOffsetY);
    
    if (distanceFromCenterY > contentLength/4) {
        self.contentOffset = CGPointMake(currentOffset.x, centerOffsetY);
        for (DLTableViewCell *cell in self.visibileCells) {
            CGPoint center = [self.containerView convertPoint:cell.center toView:self];
            center.y += (centerOffsetY - currentOffset.y);
            cell.center = [self convertPoint:center toView:self.containerView];
        }
    }
}

- (void)tileCellsInVisibleBounds:(CGRect)visibleBounds {
    BOOL cellChange = NO;
    NSInteger visibleCellsCount = self.visibileCells.count;
    CGFloat minY = CGRectGetMinY(visibleBounds);
    CGFloat maxY = CGRectGetMaxY(visibleBounds);
    
    if (self.visibileCells.count == 0) {
        [self placeNewCellOnNextEdge:minY];
    }
    
    DLTableViewCell *lastCell = self.visibileCells.lastObject;
    CGFloat nextEdge = CGRectGetMaxY(lastCell.frame);
    
    while (nextEdge < maxY) {
        nextEdge = [self placeNewCellOnNextEdge:nextEdge];
    }
    
    DLTableViewCell *headCell = self.visibileCells.firstObject;
    CGFloat previousEdge = CGRectGetMinY(headCell.frame);
    while (previousEdge > minY) {
        previousEdge = [self placeNewCellOnPreviousEdge:previousEdge];
    }
    
    lastCell = self.visibileCells.lastObject;
    while (lastCell.frame.origin.y > maxY) {
        if (self.visibileCells.count == 1) {
            // don't make visibileCells empty otherwise there is a problem
            break;
        }
        [lastCell removeFromSuperview];
        NSIndexPath *delIndexPath = self.visibileCellsIndexPath.lastObject;
        [self.visibileCellsIndexPath removeLastObject];
        DLTableViewCell *delCell = self.visibileCells.lastObject;
        [self.visibileCells removeLastObject];
        [self.reuseCellsSet addObject:delCell];
        if ([self.delegate respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
            [self.delegate tableView:self didEndDisplayingCell:delCell forRowAtIndexPath:delIndexPath];
        }
        lastCell = self.visibileCells.lastObject;
        cellChange = YES;
    }
    
    headCell = self.visibileCells.firstObject;
    while (CGRectGetMaxY(headCell.frame) < minY) {
        if (self.visibileCells.count == 1) {
            break;
        }
        [headCell removeFromSuperview];
        NSIndexPath *delIndexPath = self.visibileCellsIndexPath.firstObject;
        [self.visibileCellsIndexPath removeObjectAtIndex:0];
        DLTableViewCell *delCell = self.visibileCells.firstObject;
        [self.visibileCells removeObjectAtIndex:0];
        [self.reuseCellsSet addObject:delCell];
        if ([self.delegate respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)]) {
            [self.delegate tableView:self didEndDisplayingCell:delCell forRowAtIndexPath:delIndexPath];
        }
        headCell = self.visibileCells.firstObject;
        cellChange = YES;
    }
    
    if (cellChange || visibleCellsCount != self.visibileCells.count) {
        [NSNotificationCenter.defaultCenter postNotificationName:DLTableViewCellDidChange object:self];
    }
}

- (CGFloat)placeNewCellOnNextEdge:(CGFloat)nextEdge {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (self.visibileCellsIndexPath.count == 0) {
        [self.visibileCellsIndexPath addObject:indexPath];
    } else {
        NSInteger row = self.visibileCellsIndexPath.lastObject.row + 1;
        if (row >= [self.dataSource tableView:self numberOfRowsInSection:0]) {
            if (self.enableCycleScroll) {
                row = 0;
            } else {
                return CGFLOAT_MAX;
            }
        }
        indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.visibileCellsIndexPath addObject:indexPath];
    }
    
    DLTableViewCell *view = [self insertCellWithIndexPath:indexPath];
    CGFloat offsetY = 0;
    if (self.tableHeaderView && self.visibileCells.count == 0 && !self.enableCycleScroll) {
        offsetY = self.tableHeaderView.bounds.size.height;
    }
    [self.visibileCells addObject:view];
    [self.containerView addSubview:view];
    
    CGRect frame = view.frame;
    frame.origin.y = nextEdge + offsetY;
    frame.origin.x = 0;
    frame.size.width = self.frame.size.width;
    if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        frame.size.height = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
    } else {
        frame.size.height = DefaultCellLength;
    }
    view.frame = frame;
    return CGRectGetMaxY(frame);
}

- (CGFloat)placeNewCellOnPreviousEdge:(CGFloat)previousEdge {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    if (self.visibileCellsIndexPath.count == 0) {
        [self.visibileCellsIndexPath addObject:indexPath];
    } else {
        NSInteger row = self.visibileCellsIndexPath.firstObject.row - 1;
        if (row < 0) {
            if (self.enableCycleScroll) {
                row = [self.dataSource tableView:self numberOfRowsInSection:0] - 1;
            } else {
                return -CGFLOAT_MAX;
            }
        }
        indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [self.visibileCellsIndexPath insertObject:indexPath atIndex:0];
    }
    
    DLTableViewCell *view = [self insertCellWithIndexPath:indexPath];
    [self.visibileCells insertObject:view atIndex:0];
    [self.containerView addSubview:view];
    
    CGRect frame = view.frame;
    frame.origin.x = 0;
    frame.size.width = self.frame.size.width;
    if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        frame.size.height = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
    } else {
        frame.size.height = DefaultCellLength;
    }
    frame.origin.y = previousEdge - frame.size.height;
    view.frame = frame;
    return CGRectGetMinY(frame);
}

- (DLTableViewCell *)insertCellWithIndexPath:(NSIndexPath *)indexPath {
    DLTableViewCell *cell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
    if (self.selectedColor) {
        cell.selectedBackgroundColorView.backgroundColor = self.selectedColor;
    }
    return cell;
}

#pragma mark - Public Method

- (void)dealloc {
    NSLog(@"dltableview dealloc");
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self internalCommmonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self internalCommmonInit];
    }
    return self;
}

- (DLTableViewCell *)cellForRowAt:(NSIndexPath *)indexPath {
    NSInteger index = [self.visibileCellsIndexPath indexOfObject:indexPath];
    if (index != NSNotFound) {
        return self.visibileCells[index];
    }
    return nil;
}

- (void)reloadViews {
    self.contentSize = CGSizeMake(self.frame.size.width, [self calculateContentHeight]);
    self.contentOffset = CGPointZero;
    self.containerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    [self.reuseCellsSet removeAllObjects];
    [self.visibileCellsIndexPath removeAllObjects];
    [self.visibileCells removeAllObjects];
    [self.containerView dl_removeAllSubviews];
    
    if (!self.enableCycleScroll) {
        if (self.tableHeaderView) {
            [self.containerView addSubview:self.tableHeaderView];
            CGRect frame = self.tableHeaderView.frame;
            frame.origin.x = 0;
            frame.origin.y = 0;
            frame.size.width = self.frame.size.width;
            self.tableHeaderView.frame = frame;
        }
        if (self.tableFooterView) {
            [self.containerView addSubview:self.tableFooterView];
            CGRect frame = self.tableFooterView.frame;
            frame.origin.x = 0;
            frame.origin.y = self.contentSize.height - frame.size.height;
            frame.size.width = self.frame.size.width;
            self.tableFooterView.frame = frame;
        }
    }
    [self setNeedsLayout];
}

- (void)reloadData {
    for (NSInteger index = 0; index < self.visibileCellsIndexPath.count; index ++) {
        NSIndexPath *indexPath = self.visibileCellsIndexPath[index];
        DLTableViewCell *newCell = [self.dataSource tableView:self cellForRowAtIndexPath:indexPath];
        DLTableViewCell *cell = self.visibileCells[index];
        newCell.frame = cell.frame;
        self.visibileCells[index] = newCell;
        [cell removeFromSuperview];
        [self.reuseCellsSet addObject:cell];
        [self.containerView addSubview:newCell];
    }
}

- (void)deselectRowAt:(NSIndexPath *)indexPath animated:(BOOL)animated {
    [self deselectRowAtIndexPath:indexPath withInternalIndex:-1 animated:animated];
}

- (DLTableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier {
    DLTableViewCell *theCell = nil;
    for (DLTableViewCell *cell in self.reuseCellsSet) {
        if ([cell.reuseID isEqualToString:identifier]) {
            theCell = cell;
            break;
        }
    }
    if (theCell) {
        [self.reuseCellsSet removeObject:theCell];
    }
    return theCell;
}

- (void)scrollToRowAt:(NSIndexPath *)indexPath at:(DLTableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    [self scrollToRowAtIndexPath:indexPath withInternalIndex:-1 atScrollPosition:scrollPosition animated:animated];
}

-(void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index atScrollPosition:(DLTableViewScrollPosition)scrollPosition animated:(BOOL)animated {
    CGPoint finialOffset = [self getOffsetAtIndexPath:indexPath withInternalIndex:index atScrollPosition:scrollPosition];
    [self setContentOffset:finialOffset animated:animated];
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section {
    return [self.dataSource tableView:self numberOfRowsInSection:section];
}

#pragma mark - Private Method

- (void)internalCommmonInit {
    self.visibileCells = [NSMutableArray arrayWithCapacity:10];
    self.visibileCellsIndexPath = [NSMutableArray arrayWithCapacity:10];
    self.reuseCellsSet = [NSMutableSet setWithCapacity:10];
    self.containerView = [UIView new];
    [self addSubview:self.containerView];
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.longPressGest = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewLongPressDetected:)];
    self.longPressGest.minimumPressDuration = 0.5;
    self.tapGest = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableViewTapped:)];
    self.tapGest.cancelsTouchesInView = NO;
    [self.tapGest requireGestureRecognizerToFail:self.longPressGest];
    [self addGestureRecognizer:self.tapGest];
    [self addGestureRecognizer:self.longPressGest];
    self.lastTouchPoint = CGPointMake(-CGFLOAT_MAX, -CGFLOAT_MAX);
}

- (CGFloat)calculateContentHeight {
    if (self.enableCycleScroll) {
        return 100000;
    }
    NSInteger rowCount = [self numberOfRowsInSection:0];
    if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        CGFloat height = 0;
        for (NSInteger row = 0; row < rowCount; row ++) {
            NSIndexPath *tmpIndexpath = [NSIndexPath indexPathForRow:row inSection:0];
            height += [self.delegate tableView:self heightForRowAtIndexPath:tmpIndexpath];
        }
        if (self.tableHeaderView) {
            height += CGRectGetHeight(self.tableHeaderView.frame);
        }
        if (self.tableFooterView) {
            height += CGRectGetHeight(self.tableFooterView.frame);
        }
        return height;
    } else {
        return rowCount * DefaultCellLength;
    }
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated {
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index animated:(BOOL)animated {
    NSInteger idx = index;
    if (idx == -1) {
        for (NSInteger i = 0; i < self.visibileCellsIndexPath.count; i ++) {
            NSIndexPath *ip = self.visibileCellsIndexPath[i];
            if (indexPath.row == ip.row && indexPath.section == ip.section) {
                idx = i;
                break;
            }
        }
    }
    if (idx != -1) {
        DLTableViewCell *cell = self.visibileCells[idx];
        cell.selectedBackgroundColorView.hidden = NO;
        if (animated) {
            [UIView animateWithDuration:0.5 animations:^{
                cell.selectedBackgroundColorView.alpha = 0;
            } completion:^(BOOL finished) {
                cell.selectedBackgroundColorView.hidden = YES;
                cell.selectedBackgroundColorView.alpha = 1;
            }];
        }
    }
}

- (CGPoint)getOffsetAtIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index atScrollPosition:(DLTableViewScrollPosition)scrollPosition {
    CGPoint finialOffset = CGPointZero;
    if (self.enableCycleScroll) {
        finialOffset = [self getOffsetForIndexPath:indexPath withInternalIndex:index];
    } else {
        finialOffset = [self getOffsetWithNoCycleForIndexPath:indexPath];
    }
    CGFloat cellLength = DefaultCellLength;
    if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
        cellLength = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
    }
    switch (scrollPosition) {
        case DLTableViewScrollPositionBottom: {
            finialOffset.y -= (self.frame.size.height - cellLength);
            break;
        }
        case DLTableViewScrollPositionMiddle: {
            finialOffset.y -= (self.frame.size.height/2 - cellLength/2);
            break;
        }
        case DLTableViewScrollPositionTop: {
            break;
        }
    }
    if (!self.enableCycleScroll) {
        CGFloat offSetY = MIN(MAX(finialOffset.y, 0), self.contentSize.height - self.frame.size.height);
        finialOffset = CGPointMake(0, offSetY);
    }
    return finialOffset;
}

- (CGPoint)getOffsetForIndexPath:(NSIndexPath *)indexPath withInternalIndex:(NSInteger)index {
    if (index != -1) {
        return self.visibileCells[index].frame.origin;
    }
    for (NSInteger i = 0; i < self.visibileCellsIndexPath.count; i ++) {
        NSIndexPath *index = self.visibileCellsIndexPath[i];
        if (index.row == indexPath.row && index.section == indexPath.section) {
            return self.visibileCells[i].frame.origin;
        }
    }
    NSIndexPath *headIndexPath = self.visibileCellsIndexPath.firstObject;
    NSIndexPath *lastIndexPath = self.visibileCellsIndexPath.lastObject;
    if (!headIndexPath || !lastIndexPath) {
        return CGPointZero;
    }
    NSInteger rowsCount = [self numberOfRowsInSection:indexPath.section];
    
    long distance1FromHead = labs(indexPath.row - headIndexPath.row);
    long distance2FromHead = rowsCount - distance1FromHead;
    long distanceFromHead = MIN(distance1FromHead, distance2FromHead);
    
    long distance1FromLast = labs(indexPath.row - lastIndexPath.row);
    long distance2FromLast = rowsCount - distance1FromLast;
    long distanceFromLast = MIN(distance1FromLast, distance2FromLast);
    
    NSInteger addIdentity = -1;
    DLTableViewCell *startCell = self.visibileCells.firstObject;
    NSIndexPath *tmpIndexPath = self.visibileCellsIndexPath.firstObject;
    if (distanceFromLast < distanceFromHead) {
        addIdentity = 1;
        startCell = self.visibileCells.lastObject;
        tmpIndexPath = self.visibileCellsIndexPath.lastObject;
    }
    
    CGFloat finalY = startCell.frame.origin.y;
    while (YES) {
        NSInteger nextRow = tmpIndexPath.row + addIdentity;
        if (nextRow < 0) {
            nextRow = rowsCount - 1;
        } else if (nextRow > rowsCount - 1) {
            nextRow = 0;
        }
        tmpIndexPath = [NSIndexPath indexPathForRow:nextRow inSection:tmpIndexPath.section];
        if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
            finalY += (addIdentity * [self.delegate tableView:self heightForRowAtIndexPath:tmpIndexPath]);
        } else {
            finalY += (addIdentity * DefaultCellLength);
        }
        if (tmpIndexPath.row == indexPath.row && tmpIndexPath.section == indexPath.section) {
            break;
        }
    }
    return CGPointMake(0, finalY);;
}

- (CGPoint)getOffsetWithNoCycleForIndexPath:(NSIndexPath *)indexPath {
    for (NSInteger i = 0; i < self.visibileCellsIndexPath.count; i ++) {
        NSIndexPath *index = self.visibileCellsIndexPath[i];
        if (index.row == indexPath.row && index.section == indexPath.section) {
            return self.visibileCells[i].frame.origin;
        }
    }
    
    CGFloat finalY = 0;
    NSIndexPath *headIndexPath = self.visibileCellsIndexPath.firstObject;
    NSIndexPath *lastIndexPath = self.visibileCellsIndexPath.lastObject;
    if (indexPath.row < headIndexPath.row) {
        // -
        finalY = self.visibileCells.firstObject.frame.origin.y;
        NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:headIndexPath.row inSection:headIndexPath.section];
        while (indexPath.row < tmpIndexPath.row) {
            tmpIndexPath = [NSIndexPath indexPathForRow:tmpIndexPath.row - 1 inSection:tmpIndexPath.section];
            CGFloat subValue = DefaultCellLength;
            if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
                subValue = [self.delegate tableView:self heightForRowAtIndexPath:[NSIndexPath indexPathForRow:tmpIndexPath.row inSection:tmpIndexPath.section]];
            }
            finalY -= subValue;
        }
    } else {
        // +
        finalY = self.visibileCells.lastObject.frame.origin.y;
        NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:lastIndexPath.row inSection:lastIndexPath.section];
        while (indexPath.row > tmpIndexPath.row) {
            tmpIndexPath = [NSIndexPath indexPathForRow:tmpIndexPath.row + 1 inSection:tmpIndexPath.section];
            CGFloat addValue = DefaultCellLength;
            if ([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
                addValue = [self.delegate tableView:self heightForRowAtIndexPath:[NSIndexPath indexPathForRow:tmpIndexPath.row inSection:tmpIndexPath.section]];
            }
            finalY += addValue;
        }
    }
    return CGPointMake(0, finalY);
}

#pragma mark - GestureRecognizer

- (void)tableViewTapped:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self.containerView];
    if (sender.state == UIGestureRecognizerStateEnded) {
        UIView *v = [self.containerView dl_whichSubviewContains:point].lastObject;
        if (v && [v isKindOfClass:[DLTableViewCell class]]) {
            DLTableViewCell *cell = (DLTableViewCell *)v;
            NSInteger index = [self.visibileCells indexOfObject:cell];
            if (index != NSNotFound) {
                cell.selectedBackgroundColorView.hidden = NO;
                self.pressedCell = cell;
                if (!self.enableCycleScroll) {
                    if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                        [self.delegate tableView:self didSelectRowAtIndexPath:self.visibileCellsIndexPath[index]];
                    }
                } else {
                    if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:withInternalIndex:)]) {
                        [self.delegate tableView:self didSelectRowAtIndexPath:self.visibileCellsIndexPath[index] withInternalIndex:index];
                    }
                }
            }
        }
    }
}

- (void)tableViewLongPressDetected:(UILongPressGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self.containerView];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            UIView *v = [self.containerView dl_whichSubviewContains:point].lastObject;
            if ([v isKindOfClass:[DLTableViewCell class]]) {
                DLTableViewCell *cell = (DLTableViewCell *)v;
                cell.selectedBackgroundColorView.hidden = NO;
                self.pressedCell = cell;
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.pressedCell) {
                DLTableViewCell *cell = self.pressedCell;
                if (!CGRectContainsPoint(self.pressedCell.frame, point)) {
                    [UIView animateWithDuration:0.5 animations:^{
                        cell.selectedBackgroundColorView.alpha = 0;
                    } completion:^(BOOL finished) {
                        cell.selectedBackgroundColorView.hidden = YES;
                        cell.selectedBackgroundColorView.alpha = 1;
                    }];
                    self.pressedCell = nil;
                } else if (!CGPointEqualToPoint(self.lastTouchPoint, CGPointMake(-CGFLOAT_MAX, -CGFLOAT_MAX))) {
                    if (fabs(self.lastTouchPoint.y - point.y) > 5) {
                        [UIView animateWithDuration:0.5 animations:^{
                            cell.selectedBackgroundColorView.alpha = 0;
                        } completion:^(BOOL finished) {
                            cell.selectedBackgroundColorView.hidden = YES;
                            cell.selectedBackgroundColorView.alpha = 1;
                        }];
                        self.pressedCell = nil;
                    }
                }
            }
            break;
        }
        default: {
            if (self.pressedCell) {
                DLTableViewCell *cell = self.pressedCell;
                NSInteger index = [self.visibileCells indexOfObject:cell];
                if (index != NSNotFound) {
                    cell.selectedBackgroundColorView.hidden = NO;
                    self.pressedCell = cell;
                    if (!self.enableCycleScroll) {
                        if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
                            [self.delegate tableView:self didSelectRowAtIndexPath:self.visibileCellsIndexPath[index]];
                        }
                    } else {
                        if ([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:withInternalIndex:)]) {
                            [self.delegate tableView:self didSelectRowAtIndexPath:self.visibileCellsIndexPath[index] withInternalIndex:index];
                        }
                    }
                }
            }
            break;
        }
    }
    self.lastTouchPoint = point;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

@end
