#import <Foundation/Foundation.h>
#import "cnTypes.h"


@interface CNPrependLink : NSObject <CNChainLink>
- (id)initWithCollection:(id)collection;

+ (id)linkWithCollection:(id)collection;

@end