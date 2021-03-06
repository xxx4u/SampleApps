
#import <Foundation/Foundation.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#ifdef CORDOVA_FRAMEWORK
    #import  <Cordova/CDVPlugin.h>
#else
    #import "CDVPlugin.h"
#endif

@interface TwitterPlugin : CDVPlugin{
}

- (void) isTwitterAvailable:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;
    
- (void) isTwitterSetup:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) sendTweet:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) getPublicTimeline:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) getMentions:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

- (void) performCallbackOnMainThreadforJS:(NSString*)js;

@end
