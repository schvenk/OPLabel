//
//  OPLabel.h
//

#import <UIKit/UIKit.h>

@interface OPLabel : UILabel

@property (nonatomic, assign) int lineHeight;
@property (nonatomic, assign) BOOL anchorBottom;

@property (nonatomic) BOOL strikethrough;
@property (nonatomic) BOOL animateChanges;
@property (nonatomic) float verticalOffset;

@end
