//
//  OPLabel.m
//

#import "OPLabel.h"
#import <QuartzCore/QuartzCore.h>

@interface OPLabel ()
{
    NSMutableArray *lineLayers;
    CABasicAnimation *alphaAnim;
}
- (NSArray *)stringsFromText:(NSString *)string;
- (void)configureStrikethrough;
@end

#define AnimationDuration 0.6
#define StrikethroughAlpha 0.3

@implementation OPLabel
@synthesize lineHeight = _lineHeight;
@synthesize anchorBottom = _anchorBottom;
@synthesize strikethrough = _strikethrough;
@synthesize animateChanges = _animateChanges;
@synthesize verticalOffset = _verticalOffset;


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _lineHeight = 10;
    }
    return self;
}

- (void)drawTextInRect:(CGRect)rect {
    NSArray *slicedStrings = [self stringsFromText:self.text];
    [self.textColor set];
    
    // @todo the original MSLabel implementation fails to use rect, so this
    // currently does nothing.
    if (self.verticalOffset) rect = CGRectOffset(rect, 0, self.verticalOffset);
    
    for (int i = 0; i < slicedStrings.count; i++) {
        if (i + 1 > self.numberOfLines && self.numberOfLines != 0)
            break;
        
        NSString *line = [slicedStrings objectAtIndex:i];
        
        // calculate drawHeight based on anchor
        int drawHeight = _anchorBottom ? (self.frame.size.height - (slicedStrings.count - i) * _lineHeight) : i * _lineHeight;        
        
        // calculate drawWidth based on textAlignment
        int drawWidth = 0;
        if (self.textAlignment == UITextAlignmentCenter) {
            drawWidth = floorf((self.frame.size.width - [line sizeWithFont:self.font].width) / 2);
        } else if (self.textAlignment == UITextAlignmentRight) {
            drawWidth = (self.frame.size.width - [line sizeWithFont:self.font].width);
        }
        
        [line drawAtPoint:CGPointMake(drawWidth, drawHeight) forWidth:self.frame.size.width withFont:self.font fontSize:self.font.pointSize lineBreakMode:UILineBreakModeClip baselineAdjustment:UIBaselineAdjustmentNone];
    }
}




#pragma mark - Properties

- (void)setLineHeight:(int)lineHeight {
    if (_lineHeight == lineHeight) { return; }
    _lineHeight = lineHeight;
    [self setNeedsDisplay];
}

- (void)setText:(NSString *)text
{
    // @todo This is getting called like crazy. Why?
    NSString *oldText = self.text;
    [super setText:text];
    if (![text isEqualToString:oldText])
        [self configureStrikethrough];
}

- (void)setStrikethrough:(BOOL)strikethrough
{
    if (strikethrough == _strikethrough) return;
    _strikethrough = strikethrough;
    [self configureStrikethrough];
}


#pragma mark - Private Methods

- (NSArray *)stringsFromText:(NSString *)string {
    NSMutableArray *stringsArray = [[string componentsSeparatedByString:@" "] mutableCopy];
    NSMutableArray *slicedString = [NSMutableArray array];
    
    while (stringsArray.count != 0) {
        NSString *line = [NSString stringWithString:@""];
        NSMutableIndexSet *wordsToRemove = [NSMutableIndexSet indexSet];
        
        for (int i = 0; i < [stringsArray count]; i++) {
            NSString *word = [stringsArray objectAtIndex:i];
            
            if ([[line stringByAppendingFormat:@"%@ ", word] sizeWithFont:self.font].width <= self.frame.size.width) {
                line = [line stringByAppendingFormat:@"%@ ", word];
                [wordsToRemove addIndex:i];
            } else {
                if (line.length == 0) {
                    line = [line stringByAppendingFormat:@"%@ ", word];
                    [wordsToRemove addIndex:i];
                }
                break;
            }
        }
        [slicedString addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
        [stringsArray removeObjectsAtIndexes:wordsToRemove];
    }
    
    if (slicedString.count > self.numberOfLines && self.numberOfLines != 0) {
        NSString *line = [slicedString objectAtIndex:(self.numberOfLines - 1)];
        line = [line stringByReplacingCharactersInRange:NSMakeRange(line.length - 3, 3) withString:@"..."];
        [slicedString removeObjectAtIndex:(self.numberOfLines - 1)];
        [slicedString insertObject:line atIndex:(self.numberOfLines - 1)];
    }
    
    return slicedString;
}

- (void)configureStrikethrough
{
    if (self.strikethrough) {
        if (lineLayers) {
            for (CAShapeLayer *layer in lineLayers) [layer removeFromSuperlayer];
        }
        
        float singleLineHeight = [@"M" sizeWithFont:self.font].height; // @todo cache somehow?
        CGSize textSize = [self.text sizeWithFont:self.font constrainedToSize:self.frame.size lineBreakMode:self.lineBreakMode];
        int numberOfLines = textSize.height / singleLineHeight;
        
        // Text is centered. Figure out where it starts vertically.
        lineLayers = [[NSMutableArray alloc] initWithCapacity:numberOfLines];
        float textStartY = self.frame.size.height/2 - textSize.height/2;
        float lineY = textStartY + (3 * singleLineHeight/5);
        for (int i=0;i<numberOfLines;i++) {
            UIBezierPath *linePath = [[UIBezierPath alloc] init];
            [linePath moveToPoint:CGPointMake(0, lineY)];
            [linePath addLineToPoint:CGPointMake(textSize.width, lineY)];
            
            CAShapeLayer *layer = [[CAShapeLayer alloc] init];
            layer.path = linePath.CGPath;
            layer.strokeColor = self.textColor.CGColor;
            layer.lineWidth = 2;
            [self.layer addSublayer:layer];
            [lineLayers addObject:layer];
            
            lineY += singleLineHeight;
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
}


@end
