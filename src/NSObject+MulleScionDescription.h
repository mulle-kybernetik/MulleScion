//
//  NSObject+MulleScionDescription.h
//  MulleTwigLikeObjCTemplates
//
//  Created by Nat! on 24.02.13.
//  Copyright (c) 2013 Mulle kybernetiK. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject ( MulleScionDescription)

- (NSString *) mulleScionDescriptionWithLocalVariables:(NSMutableDictionary *) context;

@end

extern NSString   *MulleScionDateFormatterKey;
extern NSString   *MulleScionNumberFormatterKey;
extern NSString   *MulleScionDateFormatKey;
extern NSString   *MulleScionNumberFormatKey;
extern NSString   *MulleScionLocaleKey;
extern NSString   *MulleScionNSNullDescriptionKey;
extern NSString   *MulleScionStringLengthKey;
extern NSString   *MulleScionStringEllipsisKey;
