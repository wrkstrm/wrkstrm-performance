#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WSMBootTimeMonitor : NSObject

@property(class, nonatomic, readonly, strong) WSMBootTimeMonitor *shared;

+ (void)markEarlyTimestamp:(NSString *)event;

@end

NS_ASSUME_NONNULL_END
