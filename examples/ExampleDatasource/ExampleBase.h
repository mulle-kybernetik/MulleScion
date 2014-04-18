//
//  ExampleBase.h
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import <CoreData/CoreData.h>

//
// the ExampleBase contains code for the CoreData database interface
// there is nothing MulleScion specific in here. The actual interfacing
// to MulleScion is done in Example
//
@interface ExampleBase : NSObject
{
   NSManagedObjectContext   *managedObjectContext_;
}

- (NSURL *) databaseURL;
- (NSManagedObjectContext *) managedObjectContext;

- (NSArray *) fetchObjectsFromEntityNamed:(NSString *) name
                                predicate:(NSPredicate *) predicate
                          sortDescriptors:(NSArray *) sortOrderings;

- (NSUInteger) countObjectsOfEntityNamed:(NSString *) name
                         predicateFormat:(NSString *) format
                               arguments:(va_list) args;


- (id) createManagedObjectOfEntityNamed:(NSString *) entityName;


@end
