
#import "TwitterPlugin.h"
#ifdef CORDOVA_FRAMEWORK
    #import <Cordova/JSONKit.h>
#else
    #import <Cordova/JSONKit.h>
#endif

#define TWITTER_URL @"http://api.twitter.com/1/"

@implementation TwitterPlugin

- (void) isTwitterAvailable:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options{
    NSString *callbackId = [arguments objectAtIndex:0];
    TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    BOOL twitterSDKAvailable = tweetViewController != nil;

    if(tweetViewController != nil){
        [tweetViewController release];
    }
    
    [super writeJavascript:[[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:twitterSDKAvailable ? 1 : 0] toSuccessCallbackString:callbackId]];
}

- (void) isTwitterSetup:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options{
    NSString *callbackId = [arguments objectAtIndex:0];
    BOOL canTweet = [TWTweetComposeViewController canSendTweet];

    [super writeJavascript:[[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:canTweet ? 1 : 0] toSuccessCallbackString:callbackId]];
}

- (void) sendTweet:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options{
    NSLog(@"Tweet");
     
    
    // arguments: callback, tweet text, url attachment, image attachment
    NSString *callbackId = [arguments objectAtIndex:0];
    NSString *tweetText = [arguments objectAtIndex:1];
    NSString *urlAttach = [arguments objectAtIndex:2];
    NSString *imageAttach = [arguments objectAtIndex:3];
    
    TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
    [tweetViewController setInitialText:tweetText];
    
    BOOL ok = YES;
    NSString *errorMessage;
    
    if(urlAttach != nil){
        ok = [tweetViewController addURL:[NSURL URLWithString:urlAttach]];
        if(!ok){
            errorMessage = @"URL too long";
        }
    }
    
    if(imageAttach != nil){
        // Note that the image is loaded syncronously
        UIImage *img = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageAttach]]];
        ok = [tweetViewController addImage:img];
        if(!ok){
            errorMessage = @"Image could not be added";
           
        }
    }
    
   
    
    if(!ok){        
        [super writeJavascript:[[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR 
                                               messageAsString:errorMessage] toErrorCallbackString:callbackId]];
    }
    else{
        [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
            switch (result) {
                case TWTweetComposeViewControllerResultDone:
                    //[super writeJavascript:[[PluginResult resultWithStatus:PGCommandStatus_OK] toSuccessCallbackString:callbackId]];
                    [super writeJavascript:@"TwitterPlugin.onTweetSuccess();"];
                    
                    break;
                case TWTweetComposeViewControllerResultCancelled:
                default:
                    [super writeJavascript:[[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR 
                                                           messageAsString:@"Cancelled"] toErrorCallbackString:callbackId]];
                    [super writeJavascript:@"TwitterPlugin.onTweetFailure();"];
                    break;
            }
            
            [super.viewController dismissModalViewControllerAnimated:YES];
            
        }];
        
        [super.viewController presentModalViewController:tweetViewController animated:YES];
    }
    
    [tweetViewController release];
}


- (void) getPublicTimeline:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options{
    NSString *callbackId = [arguments objectAtIndex:0];
    NSString *url = [NSString stringWithFormat:@"%@statuses/public_timeline.json", TWITTER_URL];
    
	TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url] parameters:nil requestMethod:TWRequestMethodGET];
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
        NSString *jsResponse;
        
		if([urlResponse statusCode] == 200) {

            NSString *dataString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NSDictionary *dict = [dataString JSONValue];
            jsResponse = [[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict] toSuccessCallbackString:callbackId];
            [dataString release];
		}
		else{
            jsResponse = [[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR 
                                        messageAsString:[NSString stringWithFormat:@"HTTP Error: %i", [urlResponse statusCode]]] 
                          toErrorCallbackString:callbackId];
		}
        
        [self performCallbackOnMainThreadforJS:jsResponse];        
	}];
    
    [postRequest release];
}

- (void) getMentions:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options{
    NSString *callbackId = [arguments objectAtIndex:0];
    NSString *url = [NSString stringWithFormat:@"%@statuses/mentions.json", TWITTER_URL];
    
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
            NSArray *accountsArray = [accountStore accountsWithAccountType:accountType];
			// making assumption they only have one twitter account configured, should probably revist
            if([accountsArray count] > 0) {
                TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:url] parameters:nil requestMethod:TWRequestMethodGET];
                [postRequest setAccount:[accountsArray objectAtIndex:0]];
                [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    NSString *jsResponse;
                    if([urlResponse statusCode] == 200) {
                        NSString *dataString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
                        NSDictionary *dict = [dataString JSONValue];
                        jsResponse = [[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dict] toSuccessCallbackString:callbackId];
                        [dataString release];
                    }
                    else{
                        jsResponse = [[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR 
                                                     messageAsString:[NSString stringWithFormat:@"HTTP Error: %i", [urlResponse statusCode]]] 
                                      toErrorCallbackString:callbackId];
                    }
                    
                    [self performCallbackOnMainThreadforJS:jsResponse];        
                }];
                [postRequest release];
            }
            else{
                NSString *jsResponse = [[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR 
                                             messageAsString:@"No Twitter accounts available"] 
                              toErrorCallbackString:callbackId];
                [self performCallbackOnMainThreadforJS:jsResponse];
            }
        }
        else{
            NSString *jsResponse = [[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR 
                                         messageAsString:@"Access to Twitter accounts denied by user"] 
                          toErrorCallbackString:callbackId];
            [self performCallbackOnMainThreadforJS:jsResponse];
        }
    }];

    [accountStore release];
}

// The JS must run on the main thread because you can't make a uikit call (uiwebview) from another thread (what twitter does for calls)
- (void) performCallbackOnMainThreadforJS:(NSString*)javascript{
    [super performSelectorOnMainThread:@selector(writeJavascript:) 
                            withObject:javascript
                         waitUntilDone:YES];
}

@end
