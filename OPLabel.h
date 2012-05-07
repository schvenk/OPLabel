//
//  OPLabel.h
//

#import <UIKit/UIKit.h>

@interface OPLabel : UILabel

@property (nonatomic, assign) int lineHeight;
@property (nonatomic) BOOL strikethrough;
@property (nonatomic) CGFloat strikethroughAlpha;
@property (nonatomic) BOOL animateChanges;
@property (nonatomic) UIControlContentVerticalAlignment contentVerticalAlignment;
@property (nonatomic) float verticalOffset;

- (float)getHeight;

@end
