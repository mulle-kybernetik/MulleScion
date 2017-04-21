//
//  MulleScionObjectModel+BlockExpansion.m
//  MulleScion
//
//  Created by Nat! on 01.03.13.
//
//  Copyright (c) 2013 Nat! - Mulle kybernetiK
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//

#import "MulleScionObjectModel+BlockExpansion.h"

#import "MulleScionObjectModel+NSCoding.h"


@implementation MulleScionObject( BlockExpansion)

- (MulleScionObject *) nextOwnerOfBlockCommand
{
   MulleScionObject  *curr;
   
   for( curr = self; curr; curr = curr->next_)
   {
      if( [curr->next_ isBlock])
         break;
      if( [curr->next_ isEndBlock])
         break;
   }
   return( curr);
}


- (MulleScionObject *) ownerOfBlockWithIdentifier:(NSString *) identifier
{
   MulleScionObject  *curr;
   
   for( curr = self; curr; curr = curr->next_)
      if( [curr->next_ isBlock])
         if( [identifier isEqualToString:[(MulleScionBlock *) curr->next_ identifier]])
            break;
   return( curr);
}


// replacement must be a copy
- (MulleScionBlock *) replaceOwnedBlockWith:(MulleScionBlock *) NS_CONSUMED replacement
{
   MulleScionBlock      *block;
   MulleScionObject     *endBlock;
   MulleScionObject     *endReplacement;
   
   NSParameterAssert( [replacement isBlock]);
   NSParameterAssert( [self->next_ isBlock]);
   
   endReplacement = [replacement tail];
   block          = (MulleScionBlock *) self->next_;
   endBlock       = [block terminateToEnd:block->next_];
   
   NSParameterAssert( [endBlock isEndBlock]);
   NSParameterAssert( [endReplacement isEndBlock]);
   
   self->next_           = replacement;
   endReplacement->next_ = endBlock->next_;
   endBlock->next_       = nil;
   
   [block release];
   
   return( replacement);
}

@end


@implementation MulleScionTemplate (BlockExpansion)

- (void) expandBlocksUsingTable:(NSDictionary *) table
{
   NSString           *identifier;
   MulleScionBlock    *block;
   MulleScionObject   *owner;
   MulleScionBlock    *chain;
   NSMutableArray     *stack;
   NSAutoreleasePool  *pool;
   
   pool  = [NSAutoreleasePool new];
   
   stack = [NSMutableArray array];
   
   owner = self;
   while( owner = [owner nextOwnerOfBlockCommand])
   {
      block = (MulleScionBlock *) owner->next_;
      if( [block isEndBlock])
      {
         [stack removeLastObject];
         owner = owner->next_;
         continue;
      }
      
      identifier = [block identifier];
      if( [stack containsObject:identifier])
         [NSException raise:NSInvalidArgumentException
                     format:@"%ld: block \"%@\" has already been expanded by (%@)",
          (long) [block lineNumber], identifier, [stack componentsJoinedByString:@", "]];
      [stack addObject:identifier];

      chain = [table objectForKey:identifier];
      if( ! chain)
      {
         owner = block;
         continue;
      }
      
      chain = [chain copyWithZone:NULL];
      owner = [owner replaceOwnedBlockWith:chain];
   }
   
   [pool release];
}

@end
