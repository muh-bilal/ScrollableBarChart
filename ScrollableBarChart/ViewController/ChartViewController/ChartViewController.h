//
//  ChartViewController.h
//  ScrollableBarChart
//
//  Created by M.Bilal on 25/03/2016.
//  Copyright © 2016 M.Bilal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SimpleBarChart.h"

@interface ChartViewController : UIViewController<SimpleBarChartDataSource, SimpleBarChartDelegate> {
    NSArray *arrValues;
    SimpleBarChart *barChart;
}

@end
