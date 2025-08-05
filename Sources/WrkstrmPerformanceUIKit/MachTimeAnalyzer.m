#import "MachTimeAnalyzer.h"
#import "WSMBootTimeMonitor.h"

uint64_t kGlobalStartTime = 0; // Define the global variable

extern uint64_t WSMGetGlobalStartTime(void) {
    return kGlobalStartTime;
}

void InitializeGlobalStartTime(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      // Use CLOCK_UPTIME_RAW to mirror clock_gettime_nsec_np usage in Swift
      kGlobalStartTime = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    });
}

__attribute__((constructor))
static void GymkhanaConstructor(void) {
  // Call into Swift code via selector to mark timestamp
  [WSMBootTimeMonitor markEarlyTimestamp:@"monitor_static_constructor"];
}

@implementation MachTimeAnalyzer

+ (void)load {
  InitializeGlobalStartTime();
  // This method is called when the class is loaded into the runtime
  [WSMBootTimeMonitor markEarlyTimestamp:@"monitor_class_load"];
}

@end
