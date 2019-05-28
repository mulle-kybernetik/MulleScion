//
//  MulleObjCLoader+MulleFoundation.m
//  MulleFoundation
//
//  Created by Nat! on 11.05.17.
//  Copyright © 2017 Mulle kybernetiK. All rights reserved.
//

#import "MulleObjCLoader+MulleScion.h"

#ifdef __MULLE_OBJC__

@implementation MulleObjCLoader( MulleScion)

+ (struct _mulle_objc_dependency *) dependencies
{
   static struct _mulle_objc_dependency   dependencies[] =
   {

#include "objc-loader.inc"

      { MULLE_OBJC_NO_CLASSID, MULLE_OBJC_NO_CATEGORYID }
   };

   return( dependencies);
}

@end

#endif
