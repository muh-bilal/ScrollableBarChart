//
//  SimpleBarChart.m
//  YouLogReading
//
//  Created by Mohammed Islam on 9/18/13.
//  Copyright (c) 2013 KSI Technology, LLC. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.

#import "SimpleBarChart.h"
#import "Constants.h"

#define DATA_SPACING 10
#define START_SPACING 20

@implementation SimpleBarChart

@synthesize
delegate	= _delegate,
dataSource	= _dataSource;

- (id)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame]))
        return self;

    CGFloat fontSize        = (IS_IPHONE ? 12.0 : 17);
	self.animationDuration	= 1.0;
	self.hasGrids			= YES;
	self.incrementValue		= 10.0;
	self.barWidth			= 20.0;
	self.barAlpha			= 1.0;
	self.chartBorderColor	= [UIColor blackColor];
	self.gridColor			= [UIColor blackColor];
	self.hasYLabels			= YES;
	self.yLabelFont			= [UIFont fontWithName:@"Helvetica" size:fontSize];
	self.yLabelColor		= [UIColor blackColor];
	self.yLabelType			= SimpleBarChartYAxisLabelTypeInteger;
	self.xLabelFont			= [UIFont fontWithName:@"Helvetica" size:fontSize];
	self.xLabelColor		= [UIColor blackColor];
	self.xLabelType			= SimpleBarChartXLabelTypeVerticle;
	self.barTextFont		= [UIFont fontWithName:@"Helvetica" size:fontSize];
	self.barTextColor		= [UIColor whiteColor];
	self.barTextType		= SimpleBarChartBarTextTypeTop;
    
    scrollView              = [[UIScrollView alloc] init];
	_barPathLayers			= [[NSMutableArray alloc] init];
	_barHeights				= [[NSMutableArray alloc] init];
	_barLabels				= [[NSMutableArray alloc] init];
	_barTexts				= [[NSMutableArray alloc] init];
	
	// Grid
	_gridLayer				= [CALayer layer];
	[scrollView.layer addSublayer:_gridLayer];

	_barLayer				= [CALayer layer];
	[scrollView.layer addSublayer:_barLayer];

	_borderLayer			= [CALayer layer];
	[scrollView.layer addSublayer:_borderLayer];

	_yLabelView				= [[UIView alloc] init];
	_yLabelView.alpha		= 0.0;
	[self addSubview:_yLabelView];

	_xLabelView				= [[UIView alloc] init];
	_xLabelView.alpha		= 0.0;
	[scrollView addSubview:_xLabelView];

	_barTextView			= [[UIView alloc] init];
	_barTextView.alpha		= 0.0;
    
    scrollView.frame     = self.bounds;
    [scrollView setClipsToBounds:YES];
	[scrollView addSubview:_barTextView];
    [self addSubview:scrollView];
    return self;
}

- (void)reloadData {
	if (_dataSource)
	{
		// Collect some data
        [scrollView setContentOffset:CGPointMake(0, 0)];
		_numberOfBars = [_dataSource numberOfBarsInBarChart:self];
		[_barHeights removeAllObjects];
		[_barLabels removeAllObjects];
		[_barTexts removeAllObjects];
		
		for (NSInteger i = 0; i < _numberOfBars; i++)
		{
			[_barHeights addObject:[NSNumber numberWithFloat:[_dataSource barChart:self valueForBarAtIndex:i]]];

			if (_dataSource && [_dataSource respondsToSelector:@selector(barChart:xLabelForBarAtIndex:)])
				[_barLabels addObject:[_dataSource barChart:self xLabelForBarAtIndex:i]];

			if (_dataSource && [_dataSource respondsToSelector:@selector(barChart:textForBarAtIndex:)])
				[_barTexts addObject:[_dataSource barChart:self textForBarAtIndex:i]];
		}
		
		_maxHeight			= [_barHeights valueForKeyPath:@"@max.self"];
		_minHeight			= [_barHeights valueForKeyPath:@"@min.self"];
		
		// Round up to the next increment value
		CGFloat remainder	= fmod(_maxHeight.floatValue / self.incrementValue, 1) * self.incrementValue;
		_topValue			= (self.incrementValue - remainder) + _maxHeight.floatValue;

		// Find max height of the x Labels based on the angle of rotation of the text
		switch (self.xLabelType)
		{
			case SimpleBarChartXLabelTypeVerticle:
			default:
				_xLabelRotation = 90.0;
				break;

			case SimpleBarChartXLabelTypeHorizontal:
				_xLabelRotation = 0.0;
				break;

			case SimpleBarChartXLabelTypeAngled:
				_xLabelRotation = 45.0;
				break;
		}

		for (NSString *label in _barLabels)
		{
            CGSize size = [label sizeWithAttributes:
                           @{NSFontAttributeName:self.xLabelFont}];
            
            CGSize labelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
			CGFloat labelHeightWithAngle = sin(DEGREES_TO_RADIANS(_xLabelRotation)) * labelSize.width;

			if (labelSize.height > labelHeightWithAngle)
			{
				_xLabelMaxHeight = MAX(_xLabelMaxHeight, labelSize.height);
			}
			else
			{
				_xLabelMaxHeight = MAX(_xLabelMaxHeight, labelHeightWithAngle);
			}
		}

        [self setupYAxisLabels];
		_gridLayer.frame		= CGRectMake(1,
											 0.0,
                                             [self calculateWidth] - 2,
											 self.bounds.size.height - (_xLabelMaxHeight > 0.0 ? (_xLabelMaxHeight + 5.0) : 0.0));
		_barLayer.frame			= _gridLayer.frame;
		_borderLayer.frame		= _gridLayer.frame;
		_barTextView.frame		= _gridLayer.frame;
        
        // Begin Drawing
        
        [self setupXAxisLabels];

		// Draw dem stuff
		[self setupBorders];
		[self drawBorders];

		@autoreleasepool {
			[self setupBars];
			[self animateBarAtIndex:0];
		}

		if (self.hasGrids)
		{
			[self setupGrid];
			[self drawGrid];
		}

//		[self setupBarTexts];
	}
}

#pragma mark Borders

- (void)setupBorders {
	if (_borderPathLayer != nil)
	{
		[_borderPathLayer removeFromSuperlayer];
		_borderPathLayer = nil;
	}

	CGPoint bottomLeft 	= CGPointMake(CGRectGetMinX(_borderLayer.bounds), CGRectGetMinY(_borderLayer.bounds));
	CGPoint bottomRight = CGPointMake(CGRectGetMaxX(_borderLayer.bounds), CGRectGetMinY(_borderLayer.bounds));
	CGPoint topLeft		= CGPointMake(CGRectGetMinX(_borderLayer.bounds), CGRectGetMaxY(_borderLayer.bounds));
	CGPoint topRight	= CGPointMake(CGRectGetMaxX(_borderLayer.bounds), CGRectGetMaxY(_borderLayer.bounds));

	UIBezierPath *path	= [UIBezierPath bezierPath];
	[path moveToPoint:bottomRight];
	[path addLineToPoint:topRight];
	[path addLineToPoint:topLeft];
	[path addLineToPoint:bottomLeft];
	[path addLineToPoint:bottomRight];

	_borderPathLayer					= [CAShapeLayer layer];
	_borderPathLayer.frame				= _borderLayer.bounds;
	_borderPathLayer.bounds				= _borderLayer.bounds;
	_borderPathLayer.geometryFlipped	= YES;
	_borderPathLayer.path				= path.CGPath;
	_borderPathLayer.strokeColor		= self.chartBorderColor.CGColor;
	_borderPathLayer.fillColor			= nil;
	_borderPathLayer.lineWidth			= 0.6f;
	_borderPathLayer.lineJoin			= kCALineJoinBevel;

	[_borderLayer addSublayer:_borderPathLayer];
}

- (void)drawBorders {
	if (self.animationDuration == 0.0)
		return;
	
	[_borderPathLayer removeAllAnimations];

    CABasicAnimation *pathAnimation	= [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration			= self.animationDuration;
    pathAnimation.fromValue			= [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue			= [NSNumber numberWithFloat:1.0f];
    [_borderPathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
}

- (CGFloat)calculateWidth {
    float width = _numberOfBars * DATA_SPACING + _numberOfBars * self.barWidth;
    if(width > self.frame.size.width) {
        return width;
    }
    
    return self.frame.size.width - _yLabelView.frame.size.width - _yLabelView.frame.origin.x;
}

#pragma mark Bars

- (void)setupBars {
	// Clear all bars for each drawing
	for (CAShapeLayer *layer in _barPathLayers)
	{
		if (layer != nil)
		{
			[layer removeFromSuperlayer];
		}
	}
	[_barPathLayers removeAllObjects];

	CGFloat barHeightRatio	= _barLayer.bounds.size.height / _topValue;
    CGFloat	xPos			= START_SPACING;
    
	for (NSInteger i = 0; i < _numberOfBars; i++)
	{
		CGPoint bottom					= CGPointMake(xPos, _barLayer.bounds.origin.y);
		CGPoint top						= CGPointMake(xPos, ((NSNumber *)[_barHeights objectAtIndex:i]).floatValue * barHeightRatio);
        xPos							+= DATA_SPACING + self.barWidth;

		UIBezierPath *path				= [UIBezierPath bezierPath];
		[path moveToPoint:bottom];
		[path addLineToPoint:top];

		UIColor *barColor				= [UIColor darkGrayColor];
		if (_dataSource && [_dataSource respondsToSelector:@selector(barChart:colorForBarAtIndex:)])
			barColor = [_dataSource barChart:self colorForBarAtIndex:i];

		CAShapeLayer *barPathLayer		= [CAShapeLayer layer];
		barPathLayer.frame				= _barLayer.bounds;
		barPathLayer.bounds				= _barLayer.bounds;
		barPathLayer.geometryFlipped	= YES;
		barPathLayer.path				= path.CGPath;
		barPathLayer.strokeColor		= [barColor CGColor];
		barPathLayer.fillColor			= nil;
		barPathLayer.lineWidth			= self.barWidth;
		barPathLayer.lineJoin			= kCALineJoinBevel;
		barPathLayer.hidden				= YES;
		[_barLayer addSublayer:barPathLayer];
		[_barPathLayers addObject:barPathLayer];
	}
    
    CGRect frame        = self.bounds;
    frame.size.width    -= _yLabelView.frame.size.width + _yLabelView.frame.origin.x;
    frame.origin.x      = _yLabelView.frame.size.width + _yLabelView.frame.origin.x;
    [scrollView setFrame:frame];
    
    CGSize size = scrollView.contentSize;
    size.width = [self calculateWidth] + 2;
    [scrollView setContentSize:size];

}

- (void)animateBarAtIndex:(NSInteger)index {
	if (index >= _barPathLayers.count)
	{
		// Last bar, begin drawing grids
		[self displayAxisLabels];
		return;
	}

	__block NSInteger i				= index + 1;
	__weak SimpleBarChart *weakSelf = self;
	[CATransaction begin];
	[CATransaction setAnimationDuration:(self.animationDuration / (CGFloat)_barPathLayers.count)];
	[CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
	[CATransaction setCompletionBlock:^{
		[weakSelf animateBarAtIndex:i];
	}];

	CAShapeLayer *barPathLayer		= [_barPathLayers objectAtIndex:index];
	barPathLayer.hidden				= NO;
	[self drawBar:barPathLayer];

	[CATransaction commit];
}

- (void)drawBar:(CAShapeLayer *)barPathLayer {
	if (self.animationDuration == 0.0)
		return;
	
	[barPathLayer removeAllAnimations];

	CABasicAnimation *pathAnimation	= [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
	pathAnimation.fromValue			= [NSNumber numberWithFloat:0.0f];
	pathAnimation.toValue			= [NSNumber numberWithFloat:1.0f];
	[barPathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
}

#pragma mark Grid

- (void)setupGrid {
	if (_gridPathLayer != nil)
	{
		[_gridPathLayer removeFromSuperlayer];
		_gridPathLayer = nil;
	}
	
	CGFloat xPos			= self.barWidth + DATA_SPACING;
	UIBezierPath *path		= [UIBezierPath bezierPath];
    
    NSInteger numberOfBars  = _numberOfBars;
    if( _yLabelView.frame.origin.x + _yLabelView.frame.size.width + ((numberOfBars - 1) * (DATA_SPACING + self.barWidth)) < self.frame.size.width) { // In case number of bars are less than View width (draw extra lines)
        numberOfBars += (self.frame.size.width - (scrollView.frame.origin.x + (numberOfBars - 1) * (self.barWidth + DATA_SPACING)))/ (DATA_SPACING + self.barWidth);
    }

    // Draw Vertical Lines
    for(int i = 0; i < numberOfBars - 1; i++) {
      
        CGPoint top     = CGPointMake(xPos, 0.0);
        CGPoint bottom	= CGPointMake(xPos, _gridLayer.bounds.size.height);
        xPos			+= self.barWidth + DATA_SPACING;
        
        [path moveToPoint:top];
        [path addLineToPoint:bottom];
    }
    
    // Draw Center Line
    [path moveToPoint:CGPointMake(0, CGRectGetMidY(_gridLayer.frame))];
    [path addLineToPoint:CGPointMake(_gridLayer.frame.size.width, CGRectGetMidY(_gridLayer.frame))];
    
	_gridPathLayer					= [CAShapeLayer layer];
	_gridPathLayer.frame			= _gridLayer.bounds;
	_gridPathLayer.bounds			= _gridLayer.bounds;
	_gridPathLayer.geometryFlipped	= YES;
	_gridPathLayer.path				= path.CGPath;
	_gridPathLayer.strokeColor		= self.gridColor.CGColor;
	_gridPathLayer.fillColor		= nil;
	_gridPathLayer.lineWidth		= 0.6f;
	_gridPathLayer.lineJoin			= kCALineJoinBevel;

	[_gridLayer addSublayer:_gridPathLayer];
}

- (BOOL)floatsAlmostEqualBetweenValue1:(CGFloat)value1 value2:(CGFloat)value2 andPrecision:(CGFloat)precision {
    if (value1 == value2)
        return YES;
    CGFloat relativeError = fabs((value1 - value2) / value2);
    if (relativeError <= precision)
        return YES;
    return NO;
}

- (void)drawGrid {
	if (self.animationDuration == 0.0)
		return;
	
	[_gridPathLayer removeAllAnimations];

    CABasicAnimation *pathAnimation	= [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration			= self.animationDuration;
    pathAnimation.fromValue			= [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue			= [NSNumber numberWithFloat:1.0f];
	pathAnimation.timingFunction	= [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [_gridPathLayer addAnimation:pathAnimation forKey:@"strokeEnd"];
}

#pragma mark Axis Labels

- (void)setupYAxisLabels {
	if (!self.hasYLabels)
		return;

	if (_yLabelView.alpha > 0.0)
	{
		_yLabelView.alpha = 0.0;
		[[_yLabelView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}

	CGFloat yLabelFrameHeight	= self.bounds.size.height - (_xLabelMaxHeight > 0.0 ? (_xLabelMaxHeight + 5.0) : 0.0);
    CGFloat gridUnit			= yLabelFrameHeight / _topValue;
    CGFloat gridSeperation		= gridUnit * self.incrementValue;
	CGFloat yPos				= 0.0;
	CGFloat maxVal				= _topValue;
	CGFloat maxWidth			= 0.0;

	while (yPos <= yLabelFrameHeight)
	{
		NSString *stringFormat	= (_yLabelType == SimpleBarChartYAxisLabelTypeFloat) ? @"%.1f" : @"%.0f";
		NSString *yLabelString	= [NSString stringWithFormat:stringFormat, maxVal];
        
        CGSize size = [yLabelString sizeWithAttributes:
                       @{NSFontAttributeName:self.yLabelFont}];
        
        CGSize yLabelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
		CGRect yLabelFrame		= CGRectMake(0.0,
											 0.0,
											 yLabelSize.width,
											 yLabelSize.height);
		UILabel *yLabel			= [[UILabel alloc] initWithFrame:yLabelFrame];
		yLabel.font				= self.yLabelFont;
		yLabel.backgroundColor	= [UIColor clearColor];
		yLabel.textColor		= self.yLabelColor;
		yLabel.textAlignment	= NSTextAlignmentLeft;
		yLabel.center			= CGPointMake(yLabel.center.x, yPos);
		yLabel.text				= yLabelString;

		[_yLabelView addSubview:yLabel];

		maxWidth				= MAX(maxWidth, yLabelSize.width);
        maxVal					-= self.incrementValue;
        yPos					+= gridSeperation;
	}

	_yLabelView.frame		= CGRectMake(5.0,
										 0.0,
										 self.hasYLabels ? maxWidth + 5.0 : 0.0,
										 yLabelFrameHeight);
}

- (void)setupXAxisLabels {
	if (_barLabels.count == 0)
		return;

	if (_xLabelView.alpha > 0.0)
	{
		_xLabelView.alpha = 0.0;
		[[_xLabelView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}

	CGFloat xLabelFrameWidth	= self.bounds.size.width - (_yLabelView.frame.origin.x + _yLabelView.frame.size.width);
    CGFloat	xPos				= START_SPACING;

	for (NSInteger i = 0; i < _numberOfBars; i++)
	{
		NSString *xLabelText	= [_barLabels objectAtIndex:i];
        CGSize size = [xLabelText sizeWithAttributes:
                       @{NSFontAttributeName:self.xLabelFont}];
        
        CGSize xLabelSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
		CGRect xLabelFrame		= CGRectMake(0.0,
											 0.0,
											 xLabelSize.width,
											 xLabelSize.height);
		UILabel *xLabel			= [[UILabel alloc] initWithFrame:xLabelFrame];
		xLabel.font				= self.xLabelFont;
		xLabel.backgroundColor	= [UIColor clearColor];
		xLabel.textColor		= self.xLabelColor;
		xLabel.textAlignment	= NSTextAlignmentCenter;
		xLabel.text				= xLabelText;
		xLabel.transform		= CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(-_xLabelRotation));

		// Position the label appropriately
		switch (self.xLabelType)
		{
			case SimpleBarChartXLabelTypeVerticle:
			default:
				xLabel.center = CGPointMake(xPos, (xLabelSize.width / 2.0));
				break;

			case SimpleBarChartXLabelTypeHorizontal:
				xLabel.center = CGPointMake(xPos, _xLabelMaxHeight / 2.0);
				break;

			case SimpleBarChartXLabelTypeAngled:
			{
				CGFloat labelHeightWithAngle	= sin(DEGREES_TO_RADIANS(_xLabelRotation)) * xLabelSize.width;
				xLabel.center					= CGPointMake(xPos - (labelHeightWithAngle / 2.0), labelHeightWithAngle / 2.0);
				break;
			}
		}

		[_xLabelView addSubview:xLabel];

        xPos					+= DATA_SPACING + self.barWidth;
	}

	_xLabelView.frame			= CGRectMake(0,
											 self.bounds.size.height - _xLabelMaxHeight,
											 xLabelFrameWidth,
											 _xLabelMaxHeight);
}

- (void)setupBarTexts {
	if (_barTexts.count == 0)
		return;
	
	if (_barTextView.alpha > 0.0)
	{
		_barTextView.alpha = 0.0;
		[[_barTextView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}

    CGFloat	xPos				= START_SPACING;

	for (NSInteger i = 0; i < _numberOfBars; i++)
	{
		NSString *barLabelText	= [_barTexts objectAtIndex:i];
        CGSize size = [barLabelText sizeWithAttributes:
                       @{NSFontAttributeName:self.barTextFont}];
        
        CGSize barTextSize = CGSizeMake(ceilf(size.width), ceilf(size.height));
		CGRect barTextFrame		= CGRectMake(0.0,
											 0.0,
											 barTextSize.width,
											 barTextSize.height);
		UILabel *barText		= [[UILabel alloc] initWithFrame:barTextFrame];
		barText.font			= self.barTextFont;
		barText.backgroundColor	= [UIColor clearColor];
		barText.textColor		= self.barTextColor;
		barText.textAlignment	= NSTextAlignmentCenter;
		barText.text			= barLabelText;

		CGFloat barHeight		= (_barLayer.bounds.size.height / _topValue) * ((NSNumber *)[_barHeights objectAtIndex:i]).floatValue;
		
		// Position the label appropriately
		switch (self.barTextType)
		{
			case SimpleBarChartBarTextTypeTop:
			default:
				barText.center = CGPointMake(xPos, _barLayer.bounds.size.height - (barHeight - (barTextSize.height / 2.0)));
				break;

			case SimpleBarChartBarTextTypeRoof:
				barText.center = CGPointMake(xPos, _barLayer.bounds.size.height - (barHeight + (barTextSize.height / 2.0)));
				break;

			case SimpleBarChartBarTextTypeMiddle:
			{
				CGFloat minBarHeight	= (_barLayer.bounds.size.height / _topValue) * _minHeight.floatValue;
				barText.center			= CGPointMake(xPos, _barLayer.bounds.size.height - (minBarHeight / 2.0));
				break;
			}
		}

		[_barTextView addSubview:barText];
        xPos += DATA_SPACING + self.barWidth;
	}
}

- (void)displayAxisLabels {
	if (self.hasYLabels || _barTexts.count > 0 || _barLabels.count > 0)
	{
		if (self.animationDuration > 0.0)
		{
			__weak SimpleBarChart *weakSelf = self;
			[UIView animateWithDuration:self.animationDuration / 2.0 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
				_yLabelView.alpha	= 1.0;
				_xLabelView.alpha	= 1.0;
				_barTextView.alpha	= 1.0;
			} completion:^(BOOL finished) {
				if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(animationDidEndForBarChart:)])
					[weakSelf.delegate animationDidEndForBarChart:weakSelf];
			}];
		}
		else
		{
			_yLabelView.alpha	= 1.0;
			_xLabelView.alpha	= 1.0;
			_barTextView.alpha	= 1.0;
			
			if (_delegate && [_delegate respondsToSelector:@selector(animationDidEndForBarChart:)])
				[_delegate animationDidEndForBarChart:self];
		}
	}
	else
	{
		if (_delegate && [_delegate respondsToSelector:@selector(animationDidEndForBarChart:)])
			[_delegate animationDidEndForBarChart:self];
	}
}

@end
