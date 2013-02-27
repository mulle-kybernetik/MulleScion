//
//  MulleScionOutputProtocol.h
//  MulleScionTemplates
//
//  Created by Nat! on 27.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//
#import <Foundation/Foundation.h>


@protocol MulleScionOutput

- (void) appendString:(NSString *) s;

@end


@interface NSMutableString ( MulleScionOutput) < MulleScionOutput>
@end

