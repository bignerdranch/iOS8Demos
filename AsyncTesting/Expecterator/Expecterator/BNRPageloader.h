//
//  BNRPageloader.h
//  Expecterator
//
//  Created by Sean McCune (BNR) on 8/30/14.
//  Copyright (c) 2014 BNR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BNRPageloader : NSObject

- (void)requestUrl:(NSString*)url
 completionHandler:(void (^)(NSString *page))completionHandler;

@end
