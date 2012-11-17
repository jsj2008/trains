#import <Foundation/Foundation.h>
#import "cocos2d.h"


@interface CEOrtoSprite : CCSprite
@property(nonatomic) CGPoint shift;

- (void)setStart:(CGPoint)start end:(CGPoint)end;
- (void)addAngle:(CGFloat)angle rect:(CGRect)rect;
@end