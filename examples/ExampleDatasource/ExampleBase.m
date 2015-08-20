//
//  ExampleBase.m
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import "ExampleBase.h"


@implementation ExampleBase

- (NSURL *) databaseURL
{
   abort();
}


- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
   NSURL                          *url;
   NSPersistentStoreCoordinator   *coordinator;
   NSError                        *error;
   NSPersistentStore              *store;
   NSManagedObjectModel           *model;
   NSBundle                       *bundle;
   
   bundle      = [NSBundle bundleForClass:[self class]];
   model       = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:bundle]];

   NSAssert( [[model entityVersionHashesByName] count], @"No model found");
   
   coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];

   url         = [self databaseURL];
      
   store = [coordinator persistentStoreForURL:url];
   if( ! store)
   {
      store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                        configuration:nil
                                                  URL:url
                                              options:nil
                                                error:&error];
      if( ! store)
      {
         NSLog( @"%@", error);
         return( nil);
      }
   }
   return( coordinator);
}


- (NSManagedObjectContext *) managedObjectContext
{
   NSPersistentStoreCoordinator   *coordinator;
   
   if( ! managedObjectContext_)
   {
      coordinator           = [self persistentStoreCoordinator];
      managedObjectContext_ = [NSManagedObjectContext new];
      
      [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
      [managedObjectContext_ setUndoManager:nil];
   }
   return( managedObjectContext_);
}


- (NSFetchRequest *) fetchRequestForEntityNamed:(NSString *) name
                                      predicate:(NSPredicate *) predicate
                                sortDescriptors:(NSArray *) sortDescriptors
{
   NSEntityDescription   *desc;
   NSFetchRequest        *request;
   
   request = [[NSFetchRequest new] autorelease];
   
   desc = [NSEntityDescription entityForName:name
                      inManagedObjectContext:[self managedObjectContext]];
   if( ! desc)
      [NSException raise:NSInvalidArgumentException
                  format:@"No entity with name \"%@\" known", name];
   [request setEntity:desc];
   
   if( predicate)
      [request setPredicate:predicate];
   
   if( sortDescriptors)
      [request setSortDescriptors:sortDescriptors];
   
   return( request);
}


- (NSFetchRequest *) fetchRequestForEntityNamed:(NSString *) name
                                predicateFormat:(NSString *) format
                                      arguments:(va_list) args
{
   NSPredicate      *predicate;
   NSFetchRequest   *request;
   
   predicate = [NSPredicate predicateWithFormat:format
                                      arguments:args];
   request   = [self fetchRequestForEntityNamed:name
                                      predicate:predicate
                                sortDescriptors:nil];
   return( request);
}


- (NSArray *) fetchObjectsFromEntityNamed:(NSString *) name
                                predicate:(NSPredicate *) predicate
                          sortDescriptors:(NSArray *) sortOrderings
{
   NSArray                  *objects;
   NSError                  *error;
   NSFetchRequest           *request;
   NSManagedObjectContext   *context;
   
   context = [self managedObjectContext];
   request = [self fetchRequestForEntityNamed:name
                                    predicate:predicate
                              sortDescriptors:sortOrderings];
   error   = nil;
   objects = [context executeFetchRequest:request
                                    error:&error];
   
   return( objects);
}


- (NSUInteger) countObjectsOfEntityNamed:(NSString *) name
                         predicateFormat:(NSString *) format
                               arguments:(va_list) args
{
   NSError          *error;
   NSFetchRequest   *request;
   NSUInteger       count;
   
   request = [self fetchRequestForEntityNamed:name
                              predicateFormat:format
                                    arguments:args];
   
   error   = nil;
   count   = [[self managedObjectContext] countForFetchRequest:request
                                                         error:&error];
   return( count);
}


- (id) createManagedObjectOfEntityNamed:(NSString *) entityName;
{
   id   obj;
   
   obj = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                       inManagedObjectContext:[self managedObjectContext]];
   return( obj);
}

@end
