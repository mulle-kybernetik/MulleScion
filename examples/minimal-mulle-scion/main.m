#import <Foundation/Foundation.h>
#import <MulleScion/MulleScion.h>


int main(int argc, const char * argv[])
{
   NSString            *output;
   NSAutoreleasePool   *pool;
   
   pool = [NSAutoreleasePool new];
   
   output = [MulleScionTemplate descriptionWithTemplateFile:@"/tmp/test.scion"
                                           propertyListFile:@"/tmp/test.plist"];
   if( output)
      fputs( [output UTF8String], stdout);
   
   return( ! [output length]);
}

