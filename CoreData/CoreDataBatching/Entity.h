//
//  Entity.h
//  CoreDataBatching
//
//  Created by Robert Edwards on 8/26/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Entity : NSManagedObject

@property (nonatomic, retain) NSNumber * acknowledged;
@property (nonatomic, retain) NSString * title;

@end
