//
//  UListTableView.m
//  UFoundation
//
//  Created by Think on 15/12/29.
//  Copyright © 2015年 think. All rights reserved.
//

#import "UListTableView.h"
#import "NSObject+UAExtension.h"
#import "UIView+UAExtension.h"

#pragma mark - Class UIndexPath

@implementation UIndexPath

+ (id)path
{
    @autoreleasepool
    {
        return [[UIndexPath alloc]init];
    }
}

@end

#pragma mark - Class UListTableSectionItem

@interface UListTableSectionItem : NSObject

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) CGFloat headerValue;
@property (nonatomic, assign) CGFloat footerValue;
@property (nonatomic, strong) UIView *headerView;
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, assign) CGFloat originValue; // Value of origin
@property (nonatomic, assign) CGFloat sizeValue;   // Value of size
@property (nonatomic, strong) NSArray *itemArray;  // Array of UListTableItem

+ (id)item;

@end

@implementation UListTableSectionItem

+ (id)item
{
    @autoreleasepool
    {
        return [[UListTableSectionItem alloc]init];
    }
}

@end

#pragma mark - Class UListTableItem

@interface UListTableItem : NSObject

@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) CGFloat originValue; // Value of origin
@property (nonatomic, assign) CGFloat sizeValue;   // Value of size

+ (id)item;

@end

@implementation UListTableItem

+ (id)item
{
    @autoreleasepool
    {
        return [[UListTableItem alloc]init];
    }
}

@end

#pragma mark - Class UListTableViewCell

@interface UListTableViewCell ()

@property (nonatomic, assign) NSInteger sectionValue;
@property (nonatomic, assign) NSInteger indexValue;

@end

@implementation UListTableViewCell

@end

#pragma mark - Class UListTableView

@interface UListTableView ()
{
    NSArray *_sectionArray;
    NSArray *_visibleSections;
    NSMutableDictionary *_cellReusePool;
}

// For cells
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;

@end

@implementation UListTableView

- (id)initWith:(UListViewStyle)style
{
    return [self initWithFrame:CGRectZero style:style];
}

- (id)initWithFrame:(CGRect)frame style:(UListViewStyle)style
{
    self = [self initWithFrame:frame];
    if (self) {
        // Default white background
        self.backgroundColor = sysWhiteColor();
        
        _style = style;
        _separatorStyle = UListViewCellSepratorLineStyleNoEnds;
    }
    
    return self;
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (_sectionArray == nil) {
        _sectionArray = [NSMutableArray array];
        
        // Reload cells
        [self reloadData];
    }
}

- (void)dealloc
{
    if (_cellReusePool) {
        [_cellReusePool removeAllObjects];
    }
    
    _sectionArray = nil;
    _cellReusePool = nil;
    
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
        
        // Remove header & footer
        [_contentView removeAllSubviews];
        [_scrollView removeAllSubviews];
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
    scrollView.panGestureRecognizer.maximumNumberOfTouches = 1;
    scrollView.panGestureRecognizer.minimumNumberOfTouches = 1;
    [self addSubview:scrollView];
    _scrollView = scrollView;
    
    // Content
    UIView *contentView = [[UIView alloc]init];
    contentView.userInteractionEnabled = YES;
    contentView.backgroundColor = sysClearColor();
    [scrollView addSubview:contentView];
    _contentView = contentView;
    
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
    
    switch (_style) {
        case UListViewStyleHorizontal:
        {
            self.scrollView.showsVerticalScrollIndicator = NO;
            self.scrollView.showsHorizontalScrollIndicator = YES;
            self.scrollView.contentSize = sizeMake(frame.size.width, 0);
        }
            break;
            
        case UListViewStyleVertical:
        {
            self.scrollView.showsVerticalScrollIndicator = YES;
            self.scrollView.showsHorizontalScrollIndicator = NO;
            self.scrollView.contentSize = sizeMake(0, frame.size.height);
        }
            break;
            
        default:
            break;
    }
    
    // Resize
    self.scrollView.frame = rectMake(0, 0, frame.size.width, frame.size.height);
    self.contentView.frame = rectMake(0, 0, frame.size.width, frame.size.height);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        // Dequeue all items
        [self dequeueAllItemsWith:[change[@"new"] CGPointValue]];
    }
}

#pragma mark - Methods

- (void)dequeueAllItemsWith:(CGPoint)offset
{
    if (_sectionArray) {
        NSArray *pathArray = [self visiableItemsWith:offset];
        if (pathArray) {
            for (NSInteger i = 0; i < pathArray.count; i ++) {
                UListTableItem *item = pathArray[i];
                NSArray *cells = [self currentVisibleCellsWith:offset];
                
                BOOL needsAttached = NO;
                if (i < cells.count) {
                    needsAttached = ![self checkCellWith:item from:cells];
                } else {
                    needsAttached = YES;
                }
                
                if (needsAttached) {
                    // Attach cell
                    [self attachCellWith:item];
                }
            }
        }
        
        // Headers & Footers
        [self dequeueAllHeadersWith:offset];
        [self dequeueAllFootersWith:offset];
        
        // Remove unused cells
        [self removeUnusedCells];
    }
}

- (void)dequeueAllHeadersWith:(CGPoint)offset
{
    if (_visibleSections) {
        for (NSInteger i = 0; i < _visibleSections.count; i ++) {
            UListTableSectionItem *section = _visibleSections[i];
            if (section.headerValue > 0 && !section.headerView && [self.dataSource respondsToSelector:@selector(tableView:viewForHeaderInSection:)])
            {
                section.headerView = [self.dataSource tableView:self.weakself viewForHeaderInSection:section.section];
            }
            [self.contentView addSubview:section.headerView];
            
            if (section.itemArray.count > 0 && i == 0 && offset.y >= 0) {
                section.headerView.frame = rectMake(0, offset.y, self.sizeWidth, section.headerValue);
            } else {
                section.headerView.frame = rectMake(0, section.originValue, self.sizeWidth, section.headerValue);
            }
        }
    }
}

- (void)dequeueAllFootersWith:(CGPoint)offset
{
    if (_visibleSections) {
        for (NSInteger i = 0; i < _visibleSections.count; i ++) {
            UListTableSectionItem *section = _visibleSections[i];
            if (section.footerValue > 0 && !section.footerView && [self.dataSource respondsToSelector:@selector(tableView:viewForFooterInSection:)])
            {
                section.footerView = [self.dataSource tableView:self.weakself viewForFooterInSection:section.section];
            }
            [self.contentView addSubview:section.footerView];
            
            CGFloat offsetValue = self.scrollView.contentSize.height - self.scrollView.sizeHeight;
            if (section.itemArray.count > 0 && i == _visibleSections.count - 1 && (offset.y <= offsetValue)) {
                CGFloat originValue = offset.y + self.sizeHeight - section.footerValue;
                section.footerView.frame = rectMake(0, originValue, self.sizeWidth, section.footerValue);
            } else {
                CGFloat originValue = section.originValue + section.sizeValue - section.footerValue;
                section.footerView.frame = rectMake(0, originValue, self.sizeWidth, section.footerValue);
            }
        }
    }
}

- (NSArray *)visiableItemsWith:(CGPoint)offset
{
    @autoreleasepool
    {
        if (_sectionArray) {
            CGFloat offsetLValue = offset.x;
            CGFloat offsetTValue = offset.y;
            CGFloat offsetRValue = offset.x + self.scrollView.sizeWidth;
            CGFloat offsetBValue = offset.y + self.scrollView.sizeHeight;
            NSMutableArray *sections = [NSMutableArray array];
            
            for (UListTableSectionItem *section in _sectionArray) {
                CGFloat startValue = section.originValue;
                CGFloat endValue = startValue + section.sizeValue;
                
                switch (_style) {
                    case UListViewStyleVertical:
                    {
                        if (!((startValue > offsetBValue) || (endValue < offsetTValue))) {
                            [sections addObject:section];
                        }
                    }
                        break;
                        
                    case UListViewStyleHorizontal:
                    {
                        if (!((startValue > offsetRValue) || (endValue < offsetLValue))) {
                            [sections addObject:section];
                        }
                    }
                        break;
                        
                    default:
                        break;
                }
            }
            
            // Reset sections
            [self refreshSectionsWith:sections];
            
            // Index path
            if (sections.count > 0) {
                NSMutableArray *imarray = [NSMutableArray array];
                for (UListTableSectionItem *section in sections) {
                    // Cell items
                    for (UListTableItem *item in section.itemArray) {
                        CGFloat startValue = item.originValue;
                        CGFloat endValue = startValue + item.sizeValue;
                        
                        switch (_style) {
                            case UListViewStyleVertical:
                            {
                                if (!((startValue > offsetBValue) || (endValue < offsetTValue))) {
                                    [imarray addObject:item];
                                }
                            }
                                break;
                                
                            case UListViewStyleHorizontal:
                            {
                                if (!((startValue > offsetRValue) || (endValue < offsetLValue))) {
                                    [imarray addObject:item];
                                }
                            }
                                break;
                                
                            default:
                                break;
                        }
                    }
                }
                
                return [imarray copy];
            }
        }
        
        return nil;
    }
}

- (void)refreshSectionsWith:(NSArray *)sections
{
    if (checkValidNSArray(_visibleSections)) {
        for (UListTableSectionItem *vsection in _visibleSections) {
            BOOL contains = NO;
            for (UListTableSectionItem *section in sections) {
                if (vsection.section == section.section) {
                    contains = YES;
                    break;
                }
            }
            
            if (!contains) {
                if (vsection.headerView) {
                    [vsection.headerView removeFromSuperview];
                }
                
                if (vsection.footerView) {
                    [vsection.footerView removeFromSuperview];
                }
            }
        }
        
        for (UListTableSectionItem *section in _sectionArray) {
            BOOL contains = NO;
            for (UListTableSectionItem *tsection in sections) {
                if (tsection.section == section.section) {
                    contains = YES;
                    break;
                }
            }
            
            if (!contains) {
                // Remove unused header & footer
                [section.headerView removeFromSuperview];
                [section.footerView removeFromSuperview];
                
                section.headerView = nil;
                section.footerView = nil;
            }
        }
    }
    
    _visibleSections = sections;
}

- (NSArray *)currentVisibleCellsWith:(CGPoint)offset
{
    // All added cells
    NSMutableArray *subviews = [NSMutableArray array];
    for (UListTableViewCell *cell in self.contentView.subviews) {
        if (checkClass(cell, UListTableViewCell) && ![self checkVisibleWith:cell offset:offset]) {
            if (cell.superview) {
                // Remove
                [cell removeFromSuperview];
            }
        } else {
            [subviews addObject:cell];
        }
    }
    
    return subviews;
}

- (BOOL)checkVisibleWith:(UIView *)view offset:(CGPoint)offset
{
    if (!checkClass(view, UIView)) {
        return NO;
    }
    
    CGFloat width = self.scrollView.sizeWidth;
    CGFloat height = self.scrollView.sizeHeight;
    
    // Visible rect
    CGRect frame = rectMake(offset.x, offset.y, width, height);
    
    // To be detected
    CGPoint pointLT = pointMake(view.left, view.top);
    CGPoint pointLB = pointMake(view.left, view.bottom);
    CGPoint pointRT = pointMake(view.right, view.top);
    CGPoint pointRB = pointMake(view.right, view.bottom);
    
    return (CGRectContainsPoint(frame, pointLT) ||
            CGRectContainsPoint(frame, pointLB) ||
            CGRectContainsPoint(frame, pointRT) ||
            CGRectContainsPoint(frame, pointRB));
}

- (BOOL)checkCellWith:(UListTableItem *)item from:(NSArray *)cells
{
    BOOL contains = NO;
    
    if (checkValidNSArray(cells)) {
        for (UListTableViewCell *cellItem in cells) {
            switch (_style) {
                case UListViewStyleHorizontal:
                {
                    if (cellItem.originX == item.originValue) {
                        contains = YES;
                    }
                }
                    break;
                    
                case UListViewStyleVertical:
                {
                    if (cellItem.originY == item.originValue) {
                        contains = YES;
                    }
                }
                    break;
                    
                default:
                    break;
            }
            
            if (contains) {
                break;
            }
        }
    }
    
    return contains;
}

- (void)attachCellWith:(UListTableItem *)item
{
    UIndexPath *path = [UIndexPath path];
    path.section = item.section;
    path.index = item.index;
    
    UListTableViewCell *cell = [self.dataSource tableView:self.weakself cellAtPath:path];
    [self.contentView addSubview:cell];
    
    if (checkClass(cell, UListTableViewCell)) {
        switch (_style) {
            case UListViewStyleVertical:
            {
                cell.frame = rectMake(0, item.originValue, self.sizeWidth, item.sizeValue);
            }
                break;
                
            case UListViewStyleHorizontal:
            {
                cell.frame = rectMake(item.originValue, 0, item.sizeValue, self.sizeHeight);
            }
                break;
                
            default:
                break;
        }
    }
    
    [self resetSepratorWith:cell item:item];
}

- (void)resetSepratorWith:(UListTableViewCell *)cell item:(UListTableItem *)item
{
    UIView *headerLineView = [cell valueForKey:@"headerLineView"];
    UIView *footerLineView = [cell valueForKey:@"footerLineView"];;
    
    switch (_separatorStyle) {
        case UListViewCellSepratorLineStyleNone:
        {
            headerLineView.hidden = YES;
            footerLineView.hidden = YES;
        }
            break;
            
        case UListViewCellSepratorLineStyleNoEnds:
        {
            UListTableSectionItem *section = _sectionArray[item.section];
            if (item.index == section.itemArray.count - 1) {
                headerLineView.hidden = YES;
                footerLineView.hidden = YES;
            } else {
                headerLineView.hidden = YES;
                footerLineView.hidden = NO;
            }
        }
            break;
            
        case UListViewCellSepratorLineStyleFull:
        {
            if (item.index == 0) {
                headerLineView.hidden = NO;
                footerLineView.hidden = NO;
            } else {
                headerLineView.hidden = YES;
                footerLineView.hidden = NO;
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)removeUnusedCells
{
    for (NSString *key in _cellReusePool) {
        NSArray *cells = _cellReusePool[key];
        if (checkValidNSArray(cells)) {
            NSMutableArray *marray = [NSMutableArray arrayWithArray:cells];
            for (UListViewCell *cellItem in cells) {
                if (cellItem.superview == nil) {
                    [marray removeObject:cellItem];
                }
            }
            
            // Refresh
            [_cellReusePool setObject:marray forKey:key];
        }
    }
}

- (void)reloadData
{
    if (_sectionArray == nil) {
        return;
    }
    
    // Load cells
    [self reloadAllData];
    self.scrollView.contentOffset = CGPointZero;
}

- (void)reloadAllData
{
    if (_sectionArray == nil) {
        return;
    }
    
    // Remove all cells
    for (UListViewCell *cell in self.contentView.subviews) {
        if (checkClass(cell, UListViewCell) && cell.superview) {
            // Remove
            [cell removeFromSuperview];
        }
    }
    
    for (UListTableSectionItem *section in _visibleSections) {
        if (section.headerView) {
            [section.headerView removeFromSuperview];
            section.headerView = nil;
        }
        
        if (section.footerView) {
            [section.footerView removeFromSuperview];
            section.footerView = nil;
        }
    }
    
    _sectionArray = nil;
    _visibleSections = nil;
    [_cellReusePool removeAllObjects];
    
    CGFloat originValue = 0;
    NSInteger sections = [self.dataSource numberOfSectionsInListView:self.weakself];
    NSMutableArray *marray = [NSMutableArray array];
    
    for (NSInteger section = 0; section < sections; section ++) {
        @autoreleasepool
        {
            NSInteger count = [self.dataSource tableView:self.weakself numberOftemsInSection:section];
            UListTableSectionItem *sitem = [UListTableSectionItem item];
            sitem.section = section;
            sitem.originValue = originValue;
            
            // Header
            if ([self.delegate respondsToSelector:@selector(tableView:sizeValueForHeaderInSection:)]) {
                sitem.headerValue = [self.delegate tableView:self.weakself sizeValueForHeaderInSection:section];
            }
            
            // Footer
            if ([self.delegate respondsToSelector:@selector(tableView:sizeValueForFooterInSection:)]) {
                sitem.footerValue = [self.delegate tableView:self.weakself sizeValueForFooterInSection:section];
            }
            
            originValue += sitem.headerValue;
            
            CGFloat deltaValue = sitem.headerValue + sitem.footerValue;
            NSMutableArray *imarray = [NSMutableArray array];
            for (NSInteger index = 0; index < count; index ++) {
                @autoreleasepool
                {
                    UIndexPath *path = [UIndexPath path];
                    path.section = section;
                    path.index = index;
                    
                    CGFloat sizeValue = [_delegate tableView:self.weakself sizeValueForPath:path];
                    sizeValue = [@(sizeValue) floatValue];
                    originValue = [@(originValue) floatValue];
                    
                    UListTableItem *item = [UListTableItem item];
                    item.section = section;
                    item.index = index;
                    item.sizeValue = sizeValue;
                    item.originValue = originValue;
                    [imarray addObject:item];
                    
                    deltaValue += sizeValue;
                    originValue += sizeValue;
                }
            }
            
            originValue += sitem.footerValue;
            
            sitem.sizeValue = deltaValue;
            sitem.itemArray = [imarray copy];
            [marray addObject:sitem];
        }
    }
    
    _sectionArray = marray;
    
    // Resize
    switch (_style) {
        case UListViewStyleHorizontal:
        {
            self.contentView.sizeWidth = originValue;
            self.scrollView.contentSize = sizeMake(originValue, 0);
        }
            break;
            
        case UListViewStyleVertical:
        {
            self.contentView.sizeHeight = originValue;
            self.scrollView.contentSize = sizeMake(0, originValue);
        }
            break;
            
        default:
            break;
    }
}

- (void)reloadSection:(NSInteger)section
{
    [self reloadSection:section animated:YES];
}

- (void)reloadSection:(NSInteger)section animated:(BOOL)animated
{
    if (_sectionArray == nil) {
        return;
    }
    
    if (section >= 0 && section < _sectionArray.count) {
        [self reloadAllData];
        
        UListTableSectionItem *item = _sectionArray[section];
        switch (_style) {
            case UListViewStyleHorizontal:
            {
                [self.scrollView setContentOffset:pointMake(item.originValue, 0) animated:animated];
            }
                break;
                
            case UListViewStyleVertical:
            {
                [self.scrollView setContentOffset:pointMake(0, item.originValue) animated:animated];
            }
                break;
                
            default:
                break;
        }
    }
}

@end
