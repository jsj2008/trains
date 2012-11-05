#import "cr.h"

@class CRRailroad;
@class CRLevel;

@interface CRTrain : CCNode
@property(nonatomic, readonly) CRCityColor color;

+ (id)trainWithLevel:(CRLevel *)level railroad:(CRRailroad *)railroad color:(CRCityColor)color;

- (id)initWithLevel:(CRLevel *)level railroad:(CRRailroad *)railroad color:(CRCityColor)color;

- (void)addCarWithType:(CRCarType)type;

- (void)startFromCityWithColor:(CRCityColor)color;
@end