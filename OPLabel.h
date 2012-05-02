//
//  OPLabel.h
//

#import <UIKit/UIKit.h>

@interface OPLabel : UILabel

@property (nonatomic, assign) int lineHeight;
@property (nonatomic) BOOL strikethrough;
@property (nonatomic) UIControlContentVerticalAlignment contentVerticalAlignment;
@property (nonatomic) float verticalOffset;

- (float)getHeight;
- (void)animateAddingStrikethroughWithCompletion:(void (^)(void))completion;

@end
