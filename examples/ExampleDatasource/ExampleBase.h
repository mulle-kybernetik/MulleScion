//
//  ExampleBase.h
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import <CoreData/CoreData.h>


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
