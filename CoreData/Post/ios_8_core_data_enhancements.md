##iOS 8 Core Data Enhancements

No single Cocoa framework has a more polarizing effect on developers than Apple's object graph framework Core Data. You'd be hard pressed to meet a Cocoa developer completely ambivalent to the topic. Well I won't pretend to mask my colors, as I am a true fan.

As such, I believe that each year Apple has made significant improvements to the framework. This year was without exception as two highly specialized APIs were introduced. Batch updating and asynchronous fetching, while somewhat esoteric, both were introduced to combat specific issues developers encounter with the framework. Both should come to be invaluable APIs to the serious Core Data developer.

###Batch Updating

An often cited shortcomings of Core Data is its inability to efficiently update a large number of objects with a new value for one of its properties. Traditional [RDBMS](http://en.wikipedia.org/wiki/Relational_database_management_system) implementations can effortlessly update a single column with a new value for thousands upon thousands of rows. With Core Data being an object graph, updating a property is a 3 step process involving pulling the object into memory, modifying the property, and finally writing the change back to the store. Iterating these steps across thousands of objects leads to long wait times for the user as well as increased memory and CPU load on the device.

####The Request

The `NSBatchUpdateRequest` allows you to go directly to the store and modify your records in a way much more similar to traditional databases than an object graph. Creating a request is quite similar to creating any other `NSFetchRequest` supplying the name of our entity to be updated along with an `NSPredicate` for filtering. The `propertiesToUpdate` value is set to an `NSDictionary` containing key/value pairs of the property names being updated along with an `NSExpression` representing the new value. The example below marks all unread `MyObject` instances as read.

```
NSBatchUpdateRequest *batchRequest = [[NSBatchUpdateRequest alloc] initWithEntityName:@"MyObject"];
batchRequest.predicate = [NSPredicate predicateWithFormat:@"read == NO"];
batchRequest.propertiesToUpdate = @{@"read" : @(YES)};

[managedObjectContext executeRequest:batchRequest error:&batchError];
```

While in most cases you're dealing with a single `NSPersistentStore`, you do have the option of supplying an `NSArray` of stores you'd like the batch operation applied to, via the `affectedStores` property.

####Result Types

You have a few options when it comes to the format of confirmation you receive after applying the batch update. 

* `NSStatusOnlyResultType` is simply a success or failure status
* `NSUpdatedObjectsCountResultType` is the count of modified objects
* `NSUpdatedObjectIDsResultType` is an array of `NSManagedObjectID`s. Later we'll see, in some situations, this is the necessary result type.

####Speed Comparison

Using [Mark Dalrymple](http://www.bignerdranch.com/about-us/nerds/mark-dalrymple.html)'s trusty [BRNTimeBlock](https://gist.github.com/bignerdranch/2006587) we can see that a batch update on 250,000 objects takes just over one second, while a manual update takes around 16 seconds. [^fn-time_specs]

[^fn-time_specs]: All tests were run using `XCode 6 Beta 7` along with the `iPhone 5s Simulator` on a `Late 2013 MacBook Pro`.

![Time Comparison](time_results.png)

####Memory Comparison

In additon to speed considerations, memory usage between the two is like night and day.

![Memory Comparison](memory_results.png)

####What's the catch?

So with results that are many times over more efficient than a manual update, there has to be some tradeoffs. As mentioned earlier, this type of operation is something database systems handle well and object graphs fall short. As such, it's important to understand that when performing a batch operation you're essentially telling Core Data "Step aside, I got this". Apple even refers to this by equating the batch operation to "Running with scissors".[^fn-wwdc_225]

These are a few things to keep in mind:

* Property validation will not be performed on the new value, allowing you to insert bad data.
* Referential integrity will not be maintained. (ex. Setting an employee's department will not in turn update the array of employees on the department object)
* `NSManagedObjects` already in an `NSManagedObjectContext` will not be automatically refreshed. This is where using the `NSUpdatedObjectIDsResultType` is required if you want to reflect your updates in the UI.
* Lastly you must ensure your `NSManagedObjectContext` has a merge policy, as you can potentially introduce a merge conflict on yourself.
 
[^fn-wwdc_225]: [ASCII WWDC 225](http://asciiwwdc.com/2014/sessions/225?#t=1341.0)

###Asynchronous Fetching

Utilizing Core Data in a multi-threaded facet has always required a deep understanding of the framework and a healthy dose of patients. While asynchronous fetching is not necessarily a feature of a multi-threaded Core Data environment, it can often be a sufficient solution to your performance issue before jumping the gun and rolling with a full multi context/threaded solution. 

####Multi-threaded Core Data vs Asynchronous Fetching

Setting up a separate context and thread for Core Data allows you to perform any necessary operations (Fetching, Inserting, Deleting, Modifying) on your managed objects away from the main UI thread. However, even on that background thread, each operation will block the context while it's being performed.

An `NSAsynchronousFetchRequest` allows you to send off your fetch request to the `NSManagedObjectContext` and be notified via a callback block when the objects have been populated in the context. This means that, whether on the main thread or a background thread, you can continue to work with your `NSManagedObjectContext` while this fetch is executing.

####Progress and Cancelation

`NSAsynchronousFetchRequest` uses `NSProgress` to allow you to get incremental updates on how many objects have been fetched via KVO. The only catch with incremental notifications is since database operations occur in streams there is no upfront way for the `NSAsynchronousFetchRequest` to know exactly how many objects will be returned. If you happen to know this number in advance, you can supply this figure to the `NSProgress` instance for incremental updates. 

```
NSProgress *progress = [NSProgress progressWithTotalUnitCount:preComputedCount];
[progress becomeCurrentWithPendingUnitCount:1];

NSError *executeError = nil;
[context executeRequest:asyncFetch error:&executeError];

[progress resignCurrent];

```

By utilizing `NSProgress`, this also gives you a way of allowing the user to cancel a long running fetch request.

###Summary

While I don't think either of these features, on their own, will be winning over the Core Data opponents, it does show Apple's continued improvement to the framework. Each feature attacks a specific pain point Core Data enthusiast have encountered in the past.	

Batch updating provides a seamless way of bypassing Core Data's convenient, albeit expensive at times, features  to get a large data change completed quickly. While asynchronous fetching enables a lightweight means to executing a long running fetch without grinding the system to a halt or getting tangled in a complex mutli-threaded universe.

Check out the accompanying sample project detailing both of these features, along with other [iOS 8 Demos](https://github.com/bignerdranch/iOS8Demos). 
