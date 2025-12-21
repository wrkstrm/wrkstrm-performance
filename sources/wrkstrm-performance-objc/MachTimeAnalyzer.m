#import "MachTimeAnalyzer.h"

uint64_t kGlobalStartTime = 0; // Define the global variable

void InitializeGlobalStartTime(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      // Use CLOCK_UPTIME_RAW to mirror clock_gettime_nsec_np usage in Swift
      kGlobalStartTime = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    });
}

extern uint64_t WSMGetGlobalStartTime(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    InitializeGlobalStartTime();
  });
  return kGlobalStartTime;
}

@implementation MachTimeAnalyzer

+ (void)load {
  InitializeGlobalStartTime();
}

@end
