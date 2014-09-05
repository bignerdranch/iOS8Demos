//
//  BNRTimeBlock.h
//  CoreDataBatching
//
//  Created by Robert Edwards on 8/27/14.
//  Copyright (c) 2014 Big Nerd Ranch. All rights reserved.
//

CGFloat BNRTimeBlock (void (^block)(void));

#import <mach/mach_time.h>  // for mach_absolute_time() and friends

CGFloat BNRTimeBlock (void (^block)(void)) {
    mach_timebase_info_data_t info;
    if (mach_timebase_info(&info) != KERN_SUCCESS) return -1.0;

    uint64_t start = mach_absolute_time ();
    block ();
    uint64_t end = mach_absolute_time ();
    uint64_t elapsed = end - start;

    uint64_t nanos = elapsed * info.numer / info.denom;
    return (CGFloat)nanos / NSEC_PER_SEC;

} // BNRTimeBlock
