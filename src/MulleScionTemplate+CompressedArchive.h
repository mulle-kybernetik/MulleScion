//
//  MulleScionTemplate+CompressedArchive.h
//  MulleScion
//
//  Created by Nat! on 26.02.13.
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


#import "MulleScionObjectModel.h"

//
// keyed encoding, at least in my experience is slower than
// just parsing the template file new (!)
//
@interface MulleScionTemplate ( CompressedArchive)

- (id) initWithContentsOfArchive:(NSString *) fileName;
- (BOOL) writeArchive:(NSString *) fileName;

- (BOOL) writeArchive:(NSString *) fileName
                keyed:(BOOL) keyed;
                
// this opens the file and checks the archive header
+ (BOOL) isArchivedTemplatePath:(NSString *) path
                   isCompressed:(BOOL *) isCompressed;

// this checks extension first and believes
+ (BOOL) isArchivedTemplatePath:(NSString *) path;

@end
