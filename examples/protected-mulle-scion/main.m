#import <Foundation/Foundation.h>
#import <MulleScion/MulleScion.h>


@implementation NSDictionary ( ProtectionHacque)

//
// check out @protocol MulleScionDataSource for other intercepts
//
- (id) mulleScionMethodSignatureForSelector:(SEL) sel
                                     target:(id) target
{
   if( target == [NSDate class] && sel == @selector( date))
      return( nil);

   return( [super mulleScionMethodSignatureForSelector:sel
                                                target:target]);
}

@end


int   main(int argc, const char * argv[])
{
   NSAutoreleasePool   *pool;
   NSDictionary        *info;
   
   pool = [NSAutoreleasePool new];
   
   info = [NSDictionary dictionary];
   
NS_DURING
   [MulleScionTemplate descriptionWithTemplateFile:@"/tmp/ptest.scion"
                                        dataSource:info];
NS_HANDLER
   NSLog( @"Exception raised (as expected) %@", localException);
NS_ENDHANDLER
   
   return( 0);
}

