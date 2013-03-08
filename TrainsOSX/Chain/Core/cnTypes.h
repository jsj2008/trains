#import "CNYield.h"

@class CNChain;
typedef void (^cnChainBuildBlock)(CNChain * chain);
typedef BOOL (^cnPredicate)(id x);
typedef id (^cnF)(id x);

@protocol CNChainLink <NSObject>
- (CNYield *)buildYield:(CNYield *)yield;
@end


