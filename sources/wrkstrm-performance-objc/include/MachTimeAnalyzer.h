#import <Foundation/Foundation.h>
#import <time.h>

extern uint64_t WSMGetGlobalStartTime(void);

@interface MachTimeAnalyzer : NSObject

+ (void)load;

@end
