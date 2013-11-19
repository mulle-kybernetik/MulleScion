//
//  Example.m
//  MulleScionDrake
//
//  Created by Nat! on 19.11.13.
//
//

#import "Example.h"
#import "Liga.h"
#import "Club.h"


@implementation Example


- (NSURL *) databaseURL
{
   return( [NSURL fileURLWithPath:@"/tmp/example.sqlite"]);
}


- (void) createDemoDataIfNeeded
{
   NSManagedObjectContext   *context;
   NSUInteger               count;
   Liga                     *liga1, *liga2;
   Club                     *club;
   NSError                  *error;
   
   context = [self managedObjectContext];
   count   = [self countObjectsOfEntityNamed:@"Liga"
                             predicateFormat:nil
                                   arguments:NULL];
   if( count)
      return;
   
   liga1  = [self createManagedObjectOfEntityNamed:@"Liga"];
   [liga1 setName:@"Bundesliga"];

   liga2  = [self createManagedObjectOfEntityNamed:@"Liga"];
   [liga2 setName:@"2. Liga"];

   club  = [self createManagedObjectOfEntityNamed:@"Club"];
   [club setName:@"VfL Bochum"];
   [club setLiga:liga2];
   
   [context save:&error];
}


- (id) valueForKey:(NSString *) key
{
   NSArray   *objects;
   
   objects = [self fetchObjectsFromEntityNamed:key
                                     predicate:nil
                               sortDescriptors:nil];
   return( objects);
}

# pragma mark -
# pragma mark Hooks for mulle-scion

- (id) valueForKeyPath:(NSString *) keyPath
{
   NSArray    *components;
   id         value;
   NSEnumerator   *rover;
   NSString       *key;
   
NS_DURING
   components = [keyPath componentsSeparatedByString:@"."];
   value      = self;

   rover = [components objectEnumerator];
   while( key = [rover nextObject])
      value = [value valueForKey:key];
   return( value);
NS_HANDLER
   // just ignore
NS_ENDHANDLER
   return( nil);
}


+ (id) mulleScionDataSource
{
   Example   *p;
   
   p = [[self new] autorelease];
   [p createDemoDataIfNeeded];
   return( p);
}

@end
