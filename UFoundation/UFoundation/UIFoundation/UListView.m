//
//  UListView.m
//  UFoundation
//
//  Created by Think on 15/11/26.
//  Copyright © 2015年 think. All rights reserved.
//

#import "UListView.h"
#import "UDefines.h"
#import "NSObject+UAExtension.h"
#import "UIView+UAExtension.h"

@interface UListViewCell ()

@property (nonatomic, strong) UIView *contentView;

@end

@implementation UListViewCell

+ (id)cell
{
    @autoreleasepool
    {
        return [[self alloc]init];
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //
    }
    
    return self;
}

- (void)cellWillAppear
{
    //
}

- (void)cellDidDisappear
{
    //
}

- (void)dealloc
{
    //
}

@end

@interface UListView ()
{
    NSLock *_dequeueLock;
    NSInteger _numberOfCells;
    NSMutableArray *_valueArray;
    NSMutableDictionary *_cellReusePool;
}

@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation UListView

@synthesize style = _style;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _style = UListViewStyleVertical;
        _numberOfCells = -1;
        
        _dequeueLock = [[NSLock alloc]init];
        _valueArray = [NSMutableArray array];
        _cellReusePool = [NSMutableDictionary dictionary];
        
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        self.backgroundColor = sysWhiteColor();
    }
    
    return self;
}

- (id)initWithStyle:(UListViewStyle)style
{
    return [self initWithFrame:CGRectZero style:style];
}

- (id)initWithFrame:(CGRect)frame style:(UListViewStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        _style = style;
        _numberOfCells = -1;
        
        _dequeueLock = [[NSLock alloc]init];
        _valueArray = [NSMutableArray array];
        _cellReusePool = [NSMutableDictionary dictionary];
        
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        self.backgroundColor = sysWhiteColor();
    }
    
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (_numberOfCells == -1) {
        [self reloadData];
    }
}

- (void)dealloc
{
    [_valueArray removeAllObjects];
    [_cellReusePool removeAllObjects];
    
    _valueArray = nil;
    _cellReusePool = nil;
    
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - Properties

- (UIScrollView *)scrollView
{
    if (_scrollView) {
        return _scrollView;
    }
    
    UIScrollView *scrollView = [[UIScrollView alloc]init];
    scrollView.backgroundColor = sysClearColor();
    [self addSubview:scrollView];
    _scrollView = scrollView;
    
    // Clear subviews
    [scrollView removeAllSubviews];
    
    // KVO
    [scrollView addObserver:self
                 forKeyPath:@"contentOffset"
                    options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                    context:NULL];
    
    return _scrollView;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    // Resize scrollView
    self.scrollView.frame = rectMake(0, 0, frame.size.width, frame.size.height);
    
    if (_style == UListViewStyleVertical) {
        _showsVerticalScrollIndicator = YES;
        _showsHorizontalScrollIndicator = NO;
        
        self.scrollView.showsVerticalScrollIndicator = YES;
        self.scrollView.showsHorizontalScrollIndicator = NO;
        self.scrollView.contentSize = sizeMake(0, frame.size.height + 0.5);
    } else if (_style == UListViewStyleHorizontal) {
        _showsVerticalScrollIndicator = NO;
        _showsHorizontalScrollIndicator = YES;
        
        self.scrollView.showsVerticalScrollIndicator = NO;
        self.scrollView.showsHorizontalScrollIndicator = YES;
        self.scrollView.contentSize = sizeMake(frame.size.width + 0.5, 0);
    }
}

- (void)setPagingEnabled:(BOOL)enable
{
    _pagingEnabled = enable;
    
    self.scrollView.pagingEnabled = enable;
}

- (void)setShowsHorizontalScrollIndicator:(BOOL)shows
{
    _showsHorizontalScrollIndicator = shows;
    
    self.scrollView.showsHorizontalScrollIndicator = shows;
}

- (void)setShowsVerticalScrollIndicator:(BOOL)shows
{
    _showsVerticalScrollIndicator = shows;
    
    self.scrollView.showsVerticalScrollIndicator = shows;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        // Dequeue all cells
        [self dequeueCellsWith:[change[@"new"]CGPointValue]];
    }
}

#pragma mark - Methods

- (void)dequeueCellsWith:(CGPoint)offset
{
    [_dequeueLock lock];
    
    CGRange range = [self visibleRangeWith:offset];
    NSInteger beginIndex = (range.min < 0)?0:range.min;
    NSInteger endIndex = range.max;
    
    for (NSInteger i = beginIndex; i <= endIndex; i ++) {
        CGFloat sizeValue = [_valueArray[i] floatValue];
        CGFloat originValue = [self originValueOfIndex:i];
        NSInteger index = i - beginIndex;
        NSArray *cells = [self currentVisibleCellsWith:offset];
        
        BOOL needsAttached = NO;
        if (index <= cells.count) {
            needsAttached = ![self checkCellWith:i from:cells];
        } else {
            needsAttached = YES;
        }
        
        if (needsAttached) {
            // Attach cell
            UListViewCell *cell = [self.dataSource listView:self.weakself cellAtIndex:i];
            if (_style == UListViewStyleHorizontal) {
                cell.frame = rectMake(originValue, 0, sizeValue, self.scrollView.sizeHeight);
            } else if (_style == UListViewStyleVertical) {
                cell.frame = rectMake(0, originValue, self.scrollView.sizeWidth, sizeValue);
            }
            
            // For visible option
            [cell cellWillAppear];
            
            // Attached to scrollView
            [self.scrollView addSubview:cell];
            [self.scrollView insertSubview:cell belowSubview:[self.scrollView.subviews firstObject]];
        }
    }
    
    [_dequeueLock unlock];
}

- (CGRange)visibleRangeWith:(CGPoint)offset
{
    NSInteger beginIndex = -1;
    NSInteger endIndex = beginIndex;
    
    CGFloat deltaValue = 0;
    CGFloat offsetLValue = offset.x;
    CGFloat offsetTValue = offset.y;
    CGFloat offsetRValue = offset.x + self.scrollView.sizeWidth;
    CGFloat offsetBValue = offset.y + self.scrollView.sizeHeight;
    
    for (NSInteger index = 0; index < _valueArray.count; index ++) {
        CGFloat delta = deltaValue + [_valueArray[index] floatValue];
        
        // Left or top
        if (_style == UListViewStyleHorizontal) {
            if ((deltaValue <= offsetLValue) && (delta >= offsetLValue)) {
                beginIndex = index;
            }
        } else if (_style == UListViewStyleVertical) {
            if ((deltaValue <= offsetTValue) && (delta >= offsetTValue)) {
                beginIndex = index;
            }
        }
        
        // Right or bottom
        if (_style == UListViewStyleHorizontal) {
            if ((deltaValue <= offsetRValue) && (delta >= offsetRValue)) {
                endIndex = index;
            }
        } else if (_style == UListViewStyleVertical) {
            if ((deltaValue <= offsetBValue) && (delta >= offsetBValue)) {
                endIndex = index;
            }
        }
        
        deltaValue = delta;
    }
    
    // Modify end
    endIndex = (endIndex < 0)?(_numberOfCells - 1):endIndex;
    
    return CGRangeMake(beginIndex, endIndex);
}

- (NSArray *)currentVisibleCellsWith:(CGPoint)offset
{
    @autoreleasepool
    {
        // All added cells
        NSMutableArray *subviews = [NSMutableArray array];
        for (UIView *view in self.scrollView.subviews) {
            if (checkClass(view, UListViewCell)) {
                [subviews addObject:view];
            }
        }
        
        // Remove invisible cells
        NSArray *viewArray = [NSArray arrayWithArray:subviews];
        for (UListViewCell *cell in viewArray) {
            if (![self checkVisibleWith:cell offset:offset]) {
                if (cell.superview) {
                    // Remove
                    [cell removeFromSuperview];
                    
                    // For invisible option
                    [cell cellDidDisappear];
                }
                
                [subviews removeObject:cell];
            }
        }
        
        return [subviews copy];
    }
}

- (BOOL)checRectContainskWith:(CGRect)rect point:(CGPoint)point
{
    return ((point.x >= rect.origin.x) && (point.x <= (rect.origin.x + rect.size.width)) &&
            (point.y >= rect.origin.y) && (point.y <= (rect.origin.y + rect.size.height)));
}

- (BOOL)checkVisibleWith:(UListViewCell *)cell offset:(CGPoint)offset
{
    if (!cell) {
        return NO;
    }
    
    CGFloat width = self.scrollView.sizeWidth;
    CGFloat height = self.scrollView.sizeHeight;
    
    // Visible rect
    CGRect frame = rectMake(offset.x, offset.y, width, height);
    
    // To be detected
    CGPoint pointLT = pointMake(cell.left, cell.top);
    CGPoint pointLB = pointMake(cell.left, cell.bottom);
    CGPoint pointRT = pointMake(cell.right, cell.top);
    CGPoint pointRB = pointMake(cell.right, cell.bottom);
    
    return ([self checRectContainskWith:frame point:pointLT] ||
            [self checRectContainskWith:frame point:pointLB] ||
            [self checRectContainskWith:frame point:pointRT] ||
            [self checRectContainskWith:frame point:pointRB]);
}

- (CGFloat)originValueOfIndex:(NSInteger)index
{
    index = (index < 0)?0:index;
    index = (index > _numberOfCells)?_numberOfCells - 1:index;
    
    CGFloat value = 0;
    for (NSInteger i = 0; i < _valueArray.count; i ++) {
        if (index == i) {
            break;
        }
        
        value += [_valueArray[i]floatValue];
    }
    
    return value;
}

- (BOOL)checkCellWith:(NSInteger)index from:(NSArray *)cells
{
    BOOL contains = NO;
    CGFloat originValue = [self originValueOfIndex:index];
    
    for (UListViewCell *cell in cells) {
        if (_style == UListViewStyleHorizontal) {
            if (cell.originX == originValue) {
                contains = YES;
                break;
            }
        } else if (_style == UListViewStyleVertical) {
            if (cell.originY == originValue) {
                contains = YES;
                break;
            }
        }
    }
    
    return contains;
}

#pragma mark - Outer Methods

- (void)registerCell:(NSString *)cellName forIdentifier:(NSString *)identifier
{
    if (!checkValidNSString(cellName) || !checkValidNSString(identifier)) {
        return;
    }
    
    Class class = NSClassFromString(cellName);
    if (class) {
        NSArray *array = _cellReusePool[identifier];
        NSMutableArray *marray = (!array)?[NSMutableArray array]:[NSMutableArray arrayWithArray:array];
        [marray addObject:[class cell]];
        [_cellReusePool setObject:[marray copy] forKey:identifier];
    }
}

- (UListViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    UListViewCell *cell = nil;
    for (UListViewCell *item in _cellReusePool[identifier]) {
        if (item.superview == nil) {
            cell = item;
            break;
        }
    }
    
    return cell;
}

- (void)reloadData
{
    [self reloadDataWithAnimated:NO];
}

- (void)reloadDataWithAnimated:(BOOL)animated
{
    // Remove all cells
    NSArray *subviews = [NSArray arrayWithArray:self.scrollView.subviews];
    for (UListViewCell *cell in subviews) {
        if (checkClass(cell, UListViewCell)) {
            if (cell.superview) {
                // Remove
                [cell removeFromSuperview];
                
                // For invisible option
                [cell cellDidDisappear];
            }
        }
    }
    
    // Reset all cache
    [_valueArray removeAllObjects];
    [_cellReusePool removeAllObjects];
    _numberOfCells = [self.dataSource numberOfRowInListView:self.weakself];
    
    CGFloat sizeValue = 0;
    for (NSInteger index = 0; index < _numberOfCells; index ++) {
        CGFloat value = [self.delegate listView:self.weakself heightOrWidthForIndex:index];
        [_valueArray addObject:@(value)];
        
        sizeValue += value;
    }
    
    if (_style == UListViewStyleHorizontal) {
        self.scrollView.contentSize = sizeMake(sizeValue, 0);
    } else if (_style == UListViewStyleVertical) {
        self.scrollView.contentSize = sizeMake(0, sizeValue);
    }
    
    // Load cells
    if (CGPointEqualToPoint(self.scrollView.contentOffset, CGPointZero)) {
        self.scrollView.contentOffset = CGPointZero;
    } else {
        [self.scrollView setContentOffset:CGPointZero animated:animated];
    }
}

@end