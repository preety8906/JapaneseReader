//
//  ViewController.m
//  JapaneseReader
//
//  Created by Preety Pednekar on 8/3/15.
//  Copyright (c) 2015 Preety Pednekar. All rights reserved.
//
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "ViewController.h"
#import "Constants.h"

@interface ViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) IBOutlet UIScrollView     *scrollView;
@property (nonatomic, strong) UIView                    *previousView;
@property (nonatomic, strong) UIView                    *currentView;
@property (nonatomic, strong) UIView                    *nextView;
@property (nonatomic, assign) CGPoint                   currentPoint;

@property (nonatomic, strong) NSString                  *content;
@property (nonatomic, strong) NSMutableArray            *rowStringsList;
@property (nonatomic, assign) float                     rowMaxWidth;
@property (nonatomic, assign) int                       charIndex;
@property (nonatomic, assign) int                       currentPageIndex;
@property (nonatomic, assign) int                       numberOfRows;

@end

@implementation ViewController

@synthesize scrollView;
@synthesize content;
@synthesize rowStringsList;
@synthesize rowMaxWidth;
@synthesize charIndex;
@synthesize currentPageIndex;
@synthesize numberOfRows;

// create strings to show in verticle view for one page
-(NSMutableArray *) getOnePageContent
{
    NSMutableArray *pageContentStrings = [[NSMutableArray alloc] init];
    BOOL isPageFull = NO;
    
    while (self.charIndex < self.content.length && isPageFull == NO)
    {
        int rowNumber = 0;
        while (rowNumber < numberOfRows && self.charIndex < content.length)
        {
            NSString *newChar = [self.content substringWithRange: NSMakeRange(self.charIndex, 1)];
            
            if (pageContentStrings.count < rowNumber+1)
            {
                [pageContentStrings addObject: newChar];
            }
            else
            {
                // prepend it to original string
                NSString *oldString = [pageContentStrings objectAtIndex: rowNumber];
                oldString = [NSString stringWithFormat: @"%@    %@", newChar, oldString];
                
                CGSize maxLabelSize = [oldString sizeWithAttributes: @{NSFontAttributeName: FONT_TYPE}];
                
                if (maxLabelSize.width > self.rowMaxWidth)
                {
                    isPageFull = YES;
                    break;
                }
                
                [pageContentStrings replaceObjectAtIndex: rowNumber withObject: oldString];
            }
            rowNumber++;
            charIndex++;
        }
    }
    
    return pageContentStrings;
}

// Prepare view with vertically readable the content - right to left
-(UIView *) prepareOnePageWithFrame: (CGRect) pageFrame andPageContent: (NSMutableArray *) pageContentStrings
{
    float currentY = (self.scrollView.frame.size.height - 30 - ((numberOfRows - 1) * (ROW_HEIGHT + ROW_SPACING) + ROW_HEIGHT)) / 2;
    UIView *pageView = [[UIView alloc] initWithFrame: pageFrame];
    
    for (NSString *string in pageContentStrings)
    {
        UILabel *rowLabel       = [[UILabel alloc] initWithFrame: CGRectMake(ROW_X, currentY, rowMaxWidth, ROW_HEIGHT)];
        rowLabel.textColor      = [UIColor blackColor];
        rowLabel.font           = FONT_TYPE;
        rowLabel.textAlignment  = NSTextAlignmentRight;
        rowLabel.text           = string;
        
        [pageView addSubview: rowLabel];
        
        currentY += (ROW_HEIGHT + ROW_SPACING);
    }
    
    return pageView;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.content = CONTENT_LONGEST;
}

-(void) viewWillAppear:(BOOL)animated
{
    CGRect pageFrame = CGRectMake(0, 20, self.scrollView.frame.size.width, self.scrollView.frame.size.height - 30);
    self.rowStringsList     = [[NSMutableArray alloc] init];
    self.charIndex          = 0;
    self.currentPageIndex   = 0;
    
    CGRect viewFrame    = self.scrollView.frame;
    self.rowMaxWidth    = viewFrame.size.width - 2 * ROW_X;
    self.numberOfRows   = (viewFrame.size.height - ROW_SPACING) / (ROW_HEIGHT + ROW_SPACING);
    
    while (self.charIndex != content.length)
    {
        NSMutableArray *onePageStings = [self getOnePageContent];
        [self.rowStringsList addObject: onePageStings];
    }
    
    int maxPages                    = (self.rowStringsList.count < 3) ? (int)self.rowStringsList.count : 3;
    self.scrollView.contentSize     = CGSizeMake(maxPages * pageFrame.size.width, self.scrollView.frame.size.height);
    self.scrollView.contentOffset   = CGPointMake((maxPages - 1) * pageFrame.size.width, 0.0);
    self.currentPoint               = self.scrollView.contentOffset;
    
    // add max 3 pages
    for (int index = 1; index <= maxPages; index++)
    {
        NSMutableArray *rowContent = [self.rowStringsList objectAtIndex: index-1];
        pageFrame.origin.x = (maxPages - index) * self.scrollView.frame.size.width;
        
        UIView *pageView = [self prepareOnePageWithFrame: pageFrame andPageContent: rowContent];
        
        switch (index)
        {
            case 1:
                self.currentView = pageView;
                break;
                
            case 2:
            {
                self.nextView = self.currentView;
                self.currentView = pageView;
            }
                break;
            
            case 3:
            {
                self.previousView = pageView;
            }
                break;
                
            default:
                break;
        }
        
        [self.scrollView addSubview: pageView];
    }
}

#pragma mark - UIScrollView Delegate

-(void) scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    CGPoint contentOffset = self.scrollView.contentOffset;
    float selfWidth     = self.view.frame.size.width;
    
    float limitX = self.currentPoint.x + (selfWidth/2);
    
    if (contentOffset.x > limitX)
    {
        // scrolled right
        
        if (currentPageIndex == 0)
        {
            return;
        }
        
        currentPageIndex--;
        
        if (currentPageIndex == (self.rowStringsList.count - 2))
        {
            contentOffset.x = selfWidth;
            [self.scrollView setContentOffset: contentOffset];
            self.currentPoint = self.scrollView.contentOffset;
            return;
        }
        
        if (currentPageIndex == 0)
        {
            contentOffset.x = 2 * selfWidth;
            [self.scrollView setContentOffset: contentOffset];
            self.currentPoint = self.scrollView.contentOffset;
            return;
        }
        
        [self.previousView removeFromSuperview];
        [self.currentView removeFromSuperview];
        [self.nextView removeFromSuperview];
        
        self.nextView.frame     = self.currentView.frame;
        self.currentView.frame  = self.previousView.frame;
        
        self.previousView   = self.currentView;
        self.currentView    = self.nextView;
        
        [self.scrollView addSubview: self.previousView];
        [self.scrollView addSubview: self.currentView];
        
        // modify the current month details
        
        CGRect frame = self.currentView.frame;
        frame.origin.x += frame.size.width;
        
        self.nextView = [self prepareOnePageWithFrame: frame andPageContent: [self.rowStringsList objectAtIndex: currentPageIndex - 1]];
        [self.scrollView addSubview: self.nextView];
        
        contentOffset.x = selfWidth;
        [self.scrollView setContentOffset: contentOffset];
        self.currentPoint = self.scrollView.contentOffset;
    }
    else if (contentOffset.x < self.currentPoint.x)
    {
        // scrolled left
        
        if (currentPageIndex == self.rowStringsList.count - 1)
        {
            return;
        }
        
        currentPageIndex++;
        
        if (currentPageIndex == 1)
        {
            contentOffset.x = selfWidth;
            [self.scrollView setContentOffset: contentOffset];
            self.currentPoint = self.scrollView.contentOffset;
            return;
        }
        
        if (currentPageIndex == (self.rowStringsList.count - 1))
        {
            contentOffset.x = 0.0;
            [self.scrollView setContentOffset: contentOffset];
            self.currentPoint = self.scrollView.contentOffset;
            return;
        }
        
        [self.previousView removeFromSuperview];
        [self.currentView removeFromSuperview];
        [self.nextView removeFromSuperview];
        
        self.previousView.frame   = self.currentView.frame;
        self.currentView.frame    = self.nextView.frame;
        
        self.nextView       = self.currentView;
        self.currentView    = self.previousView;
        
        [self.scrollView addSubview: self.nextView];
        [self.scrollView addSubview: self.currentView];
        
        // modify currentmonth details
        CGRect frame = self.currentView.frame;
        frame.origin.x -= frame.size.width;
        
        self.previousView = [self prepareOnePageWithFrame: frame andPageContent: [self.rowStringsList objectAtIndex: currentPageIndex + 1]];
        [self.scrollView addSubview: self.previousView];
        
        contentOffset.x = selfWidth;
        [self.scrollView setContentOffset: contentOffset];
        self.currentPoint = self.scrollView.contentOffset;
    }
    else
    {
        // scrolled but on same pages
    }
}

#pragma mark - Memory Warning

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
