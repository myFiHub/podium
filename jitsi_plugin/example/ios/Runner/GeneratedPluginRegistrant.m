//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<integration_test/IntegrationTestPlugin.h>)
#import <integration_test/IntegrationTestPlugin.h>
#else
@import integration_test;
#endif

#if __has_include(<jitsi_meet_flutter_sdk/JitsiMeetPlugin.h>)
#import <jitsi_meet_flutter_sdk/JitsiMeetPlugin.h>
#else
@import jitsi_meet_flutter_sdk;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [IntegrationTestPlugin registerWithRegistrar:[registry registrarForPlugin:@"IntegrationTestPlugin"]];
  [JitsiMeetPlugin registerWithRegistrar:[registry registrarForPlugin:@"JitsiMeetPlugin"]];
}

@end
