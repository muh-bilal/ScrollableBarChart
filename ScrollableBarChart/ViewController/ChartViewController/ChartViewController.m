//
//  ChartViewController.m
//  ScrollableBarChart
//
//  Created by M.Bilal on 25/03/2016.
//  Copyright © 2016 M.Bilal. All rights reserved.
//

#import "ChartViewController.h"
#import "Constants.h"

@implementation ChartViewController

#pragma mark UIViewController Delegate Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    arrValues                       = @[@5.0, @10.0, @15.0, @20.0, @25.0, @30.0, @35.0, @30.0, @25.0, @20.0, @15.0, @10.0, @5.0];
    CGRect chartFrame				= CGRectMake(SCREEN_WIDTH * 0.05, SCREEN_HEIGHT * 0.05, SCREEN_WIDTH * 0.9, SCREEN_HEIGHT * 0.9);
    barChart                        = [[SimpleBarChart alloc] initWithFrame:chartFrame];
    barChart.dataSource				= self;
    barChart.delegate               = self;
    barChart.animationDuration		= 0.8f;
    barChart.barWidth				= (IS_IPHONE ? 30.0 : 45);
    barChart.xLabelType				= SimpleBarChartXLabelTypeVerticle;
    barChart.incrementValue			= 10;
    barChart.barTextType			= SimpleBarChartBarTextTypeTop;
    barChart.barTextColor			= [UIColor whiteColor];
    barChart.gridColor				= [UIColor grayColor];
    [self.view addSubview:barChart];
    [barChart reloadData];
}

#pragma mark SimpleBarChartDataSource
- (NSUInteger)numberOfBarsInBarChart:(SimpleBarChart *)barChart {
    return arrValues.count;
}

- (CGFloat)barChart:(SimpleBarChart *)barChart valueForBarAtIndex:(NSUInteger)index {
    return [[arrValues objectAtIndex:index] floatValue];
}

- (NSString *)barChart:(SimpleBarChart *)barChart textForBarAtIndex:(NSUInteger)index {
    return [[arrValues objectAtIndex:index] stringValue];
}

- (NSString *)barChart:(SimpleBarChart *)barChart xLabelForBarAtIndex:(NSUInteger)index {
    return [[arrValues objectAtIndex:index] stringValue];
}

- (UIColor *)barChart:(SimpleBarChart *)barChart colorForBarAtIndex:(NSUInteger)index {
    return [UIColor colorWithRed:61/255.0 green:184/255.0 blue:145/255.0 alpha:0.8];
}

@end
