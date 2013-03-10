#import "chain.h"
#import "Kiwi.h"

static BOOL (^const LESS_THAN_3)(id) = ^BOOL(id x) {return [x intValue] < 3;};

SPEC_BEGIN(CNChainSpec)

  describe(@"The CNChain", ^{
      NSArray *s = [NSArray arrayWithObjects:@1, @3, @2, nil];
      it(@"should return the same array without any actions", ^{
          NSArray *r = [[CNChain chainWithCollection:s] array];
          [[r should] equal:s];
          r = [[s chain] array];
          [[r should] equal:s];
      });

      it(@"should filter items with condition", ^{
          NSArray *r = [[s filter:^BOOL(id x) {return [x intValue] <= 2;}] array];
          [[r should] equal:@[@1, @2]];
      });
      it(@"should modify values with map function", ^{
          NSArray *r = [[s map:^id(id x) {return [NSNumber numberWithInt:[x intValue] * 2];}] array];
          [[r should] equal:@[@2, @6, @4]];
      });
      it(@"should perform several operations in one chain", ^{
          NSArray *r = [[[s
                  filter:LESS_THAN_3]
                     map:^id(id x) {return [NSNumber numberWithInt:[x intValue] * 2];}]
                   array];
          [[r should] equal:@[@2, @4]];
      });
      it(@".first should return first value or none", ^{
          [[[[s filter:LESS_THAN_3] first] should] equal:@1];
          [[[[s filter:^BOOL(id x) {
              return NO;
          }] first] should] equal:[CNOption none]];
      });
  });

SPEC_END