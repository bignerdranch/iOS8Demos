//
//  BNRPageloader.m
//  Expecterator
//
//  Created by Sean McCune (BNR) on 8/30/14.
//  Copyright (c) 2014 BNR. All rights reserved.
//

#import "BNRPageloader.h"

@implementation BNRPageloader

- (void)requestUrl:(NSString*)url
 completionHandler:(void (^)(NSString *page))completionHandler
{
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task = nil;
    
    void (^handler)(NSData *data, NSURLResponse *response, NSError *error) =
    
    ^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSHTTPURLResponse *webResponse = (NSHTTPURLResponse*)response;
        NSLog(@"Response code: %ld", webResponse.statusCode);
        
        if (webResponse.statusCode == 200) {
            NSString *page = [[NSString alloc] initWithData:data
                                                   encoding:NSUTF8StringEncoding];
            completionHandler(page);            
        }
    };
    
    
    task = [session dataTaskWithURL:[NSURL URLWithString:url]
                  completionHandler:handler];
    [task resume];
}

@end
