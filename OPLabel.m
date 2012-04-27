//
//  OPLabel.m
//

#import "OPLabel.h"
#import <QuartzCore/QuartzCore.h>

@interface OPLabel ()
{
    NSMutableArray *lineLayers;
    CABasicAnimation *alphaAnim;
    NSArray *slicedStrings;
    NSArray *lineWidths;
    NSArray *linePositions;
}
- (void)calculateLinesOfText;
- (void)drawStrikethrough;
@end

#define AnimationDuration 0.6
#define StrikethroughAlpha 0.3

@implementation OPLabel
@synthesize lineHeight = _lineHeight;
@synthesize strikethrough = _strikethrough;
@synthesize animateChanges = _animateChanges;
@synthesize verticalOffset = _verticalOffset;
@synthesize contentVerticalAlignment = _contentVerticalAlignment;


- (void)drawTextInRect:(CGRect)rect {
    [self calculateLinesOfText];
    [self.textColor set];
    
    // @todo the original MSLabel implementation fails to use rect, so this
    // currently does nothing.
    if (self.verticalOffset) rect = CGRectOffset(rect, 0, self.verticalOffset);
    
    // linePositions is the only global array reflecting the actual number of lines
    for (int i = 0; i < linePositions.count; i++) {
        NSString *line = [slicedStrings objectAtIndex:i];
        [line drawAtPoint:[[linePositions objectAtIndex:i] CGPointValue] forWidth:self.frame.size.width withFont:self.font fontSize:self.font.pointSize lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentNone];
    }
    
    [self drawStrikethrough];
}




#pragma mark - Properties

- (void)setLineHeight:(int)lineHeight {
    if (_lineHeight == lineHeight) { return; }
    _lineHeight = lineHeight;
    [self setNeedsDisplay];
}
- (int)lineHeight
{
    if (!_lineHeight) {
        _lineHeight = [@"M" sizeWithFont:self.font].height;
    }
    return _lineHeight;
}

- (void)setText:(NSString *)text
{
    if (![text isEqualToString:self.text]) {
        [super setText:text];
        [self setNeedsDisplay]; // @todo necessary?
    }
}

- (void)setStrikethrough:(BOOL)strikethrough
{
    if (strikethrough != _strikethrough) {
        _strikethrough = strikethrough;
        [self setNeedsDisplay];
    }
}



#pragma mark - Private Methods

- (void)calculateLinesOfText {
    NSMutableArray *stringsArray = [[self.text componentsSeparatedByString:@" "] mutableCopy];
    NSMutableArray *newSlicedStrings = [NSMutableArray array];
    NSMutableArray *newLineWidths = [NSMutableArray array];
    
    while (stringsArray.count != 0) {
        NSString *line = [NSString stringWithString:@""];
        NSMutableIndexSet *wordsToRemove = [NSMutableIndexSet indexSet];
        float lastWidth;

        for (int i = 0; i < [stringsArray count]; i++) {
            NSString *word = [stringsArray objectAtIndex:i];
            
            CGSize lineSize = [[line stringByAppendingFormat:@"%@", word] sizeWithFont:self.font];
            if (lineSize.width <= self.frame.size.width) {
                line = [line stringByAppendingFormat:@"%@ ", word];
                [wordsToRemove addIndex:i];
                lastWidth = lineSize.width;
            } else {
                if (line.length == 0) {
                    line = [line stringByAppendingFormat:@"%@ ", word];
                    [wordsToRemove addIndex:i];
                    lastWidth = [line sizeWithFont:self.font].width;
                }
                break;
            }
        }
        [newSlicedStrings addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        [newLineWidths addObject:[NSNumber numberWithFloat:lastWidth]];
        [stringsArray removeObjectsAtIndexes:wordsToRemove];
    }
    lineWidths = newLineWidths;
    
    if (newSlicedStrings.count > self.numberOfLines && self.numberOfLines != 0) {
        NSString *line = [newSlicedStrings objectAtIndex:(self.numberOfLines - 1)];
        line = [line stringByReplacingCharactersInRange:NSMakeRange(line.length - 3, 3) withString:@"..."];
        [newSlicedStrings removeObjectAtIndex:(self.numberOfLines - 1)];
        [newSlicedStrings insertObject:line atIndex:(self.numberOfLines - 1)];
    }
    slicedStrings = newSlicedStrings;

    int actualNumberOfLines = (self.numberOfLines > 0) ? MIN(slicedStrings.count, self.numberOfLines) : slicedStrings.count;
    NSMutableArray *newLinePositions = [NSMutableArray array];
    
    // Figure out where to start drawing the text based on vertical alignment setting
    float startY;
    if (self.contentVerticalAlignment == UIControlContentVerticalAlignmentTop) startY = 0;
    else if (self.contentVerticalAlignment == UIControlContentVerticalAlignmentBottom) startY = self.frame.size.height - (self.lineHeight * actualNumberOfLines);
    else startY = self.frame.size.height/2 - (self.lineHeight * actualNumberOfLines)/2 + self.verticalOffset;
    
    for (int i = 0; i < actualNumberOfLines; i++) {
        CGPoint pos;
        // calculate y based on anchor
        //int drawHeight = _anchorBottom ? (self.frame.size.height - (slicedStrings.count - i) * _lineHeight) : i * _lineHeight;        
        pos.y = startY + (i * self.lineHeight);
        
        // calculate x based on textAlignment
        pos.x = 0;
        if (self.textAlignment == UITextAlignmentCenter) {
            pos.x = floorf((self.frame.size.width - [[newLineWidths objectAtIndex:i] floatValue]) / 2);
        } else if (self.textAlignment == UITextAlignmentRight) {
            pos.x = (self.frame.size.width - [[newLineWidths objectAtIndex:i] floatValue]);
        }
        
        [newLinePositions addObject:[NSValue valueWithCGPoint:pos]];
    }
    slicedStrings = newSlicedStrings;
    linePositions = newLinePositions;
}

- (void)drawStrikethrough
{
    if (self.strikethrough) {
        if (lineLayers) {
            for (CAShapeLayer *layer in lineLayers) [layer removeFromSuperlayer];
        }
        
        // Text is centered. Figure out where it starts vertically.
        lineLayers = [[NSMutableArray alloc] initWithCapacity:linePositions.count];
        float lineOffset = self.lineHeight/2;
        for (int i=0;i<linePositions.count;i++) {
            CGPoint textPos = [[linePositions objectAtIndex:i] CGPointValue];
            float lineY = textPos.y + lineOffset;
            UIBezierPath *linePath = [[UIBezierPath alloc] init];
            [linePath moveToPoint:CGPointMake(textPos.x, lineY)];
            [linePath addLineToPoint:CGPointMake(textPos.x + [[lineWidths objectAtIndex:i] floatValue], lineY)];
            
            CAShapeLayer *layer = [[CAShapeLayer alloc] init];
            layer.path = linePath.CGPath;
            layer.strokeColor = self.textColor.CGColor;
            layer.lineWidth = 2;
            [self.layer addSublayer:layer];
            [lineLayers addObject:layer];
        }
        
        if (self.animateChanges) {
            for (CAShapeLayer *lineLayer in lineLayers) {
                lineLayer.strokeEnd = 0;
                
                CABasicAnimation *drawAnim = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
                drawAnim.duration = AnimationDuration;
                drawAnim.fromValue = [NSNumber numberWithFloat:0];
                drawAnim.toValue = [NSNumber numberWithFloat:1];
                drawAnim.removedOnCompletion = NO;
                drawAnim.fillMode = kCAFillModeForwards;
                
                [lineLayer addAnimation:drawAnim forKey:@"drawAnim"];
                lineLayer.strokeEnd = 1;
            }
            
            [UIView animateWithDuration:2*AnimationDuration/3 delay:AnimationDuration/3 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.alpha = StrikethroughAlpha;
            } completion:nil];
        } else self.layer.opacity = StrikethroughAlpha;
    } else {
        if (lineLayers) {
            for (CAShapeLayer *layer in lineLayers) [layer removeFromSuperlayer];
        }
        lineLayers = nil;
        self.alpha = 1;
    }
    self.animateChanges = NO;
}


@end
