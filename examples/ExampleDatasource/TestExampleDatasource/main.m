//
//  main.m
//  TestExampleDatasource
//
//  Created by Nat! on 19.11.13.
//
//

#import <Foundation/Foundation.h>

//
// to make things a little more interesting (and more useful for use in
// MulleScionist) the actual code is separated out into a bundle
// http://www.mulle-kybernetik.com/software/git/MulleScionist/
//
int main(int argc, const char * argv[])
{

   NSAutoreleasePool   *pool;
   NSBundle            *bundle;
   Class               cls;
   id                  plist;
   NSString            *path;
   
   pool = [NSAutoreleasePool new];

   bundle = [NSBundle mainBundle];
   path   = [bundle pathForResource:@"ExampleDatasource"
                             ofType:@"bundle"];
   bundle = [NSBundle bundleWithPath:path];
   cls    = [bundle principalClass];

   if( ! cls)
   {
      NSLog( @"bundle \"%@\" load failure", path);
      return( nil);
   }
   
   if( ! [cls respondsToSelector:@selector( mulleScionDataSource)])
   {
      NSLog( @"bundle's principal class \"%@\" does not respond to +mulleScionDataSource", cls);
      return( nil);
   }
   
   plist = [cls performSelector:@selector( mulleScionDataSource)];
   if( ! plist)
   {
      NSLog( @"bundle's principal class \"%@\" returned nil for +mulleScionDataSource", cls);
      return( nil);
   }
   
   if( ! [plist respondsToSelector:@selector( valueForKeyPath:)])
   {
      NSLog( @"bundle's dataSource\"%@\" does not respond to -valueForKeyPath:", [plist class]);
      return( nil);
   }
   
   NSLog( @"%@", [plist valueForKeyPath:@"Liga.name"]);
   
   [pool release];
   return( 0);
}

