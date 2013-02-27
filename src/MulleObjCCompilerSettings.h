/*
 *  MulleCore - Optimized Foundation Replacements and Extensions Functionality
 *              also a part of MulleEOFoundation of MulleEOF (Project Titmouse)
 *              which is part of the Mulle EOControl Framework Collection
 *  Copyright (C) 2013 Nat!, Codeon GmbH, Mulle kybernetiK. All rights reserved.
 *
 *  Coded by Nat!
 *
 */
#ifndef __has_feature      // Optional.
# define __has_feature(x) 0 // Compatibility with non-clang compilers.
#endif


#ifndef NS_RETURNS_NOT_RETAINED
# if __has_feature( attribute_ns_returns_not_retained)
#  define NS_RETURNS_NOT_RETAINED __attribute__(( ns_returns_not_retained))
# else
#  define NS_RETURNS_NOT_RETAINED
# endif
#endif


#ifndef NS_RETURNS_RETAINED
# if __has_feature( attribute_ns_returns_retained)
#  define NS_RETURNS_RETAINED __attribute__(( ns_returns_retained))
# else
#  define NS_RETURNS_RETAINED
# endif
#endif


#ifndef NS_RELEASES_ARGUMENT
# if __has_feature( attribute_ns_consumed)
#  define NS_RELEASES_ARGUMENT   __attribute__(( ns_consumed))
# else
#  define NS_RELEASES_ARGUMENT
# endif
#endif


#ifndef NS_CONSUMED
# if __has_feature( attribute_ns_consumed)
#  define NS_CONSUMED   __attribute__(( ns_consumed))
# else
#  define NS_CONSUMED
# endif
#endif


#ifndef NS_CONSUMES_SELF
# if __has_feature( attribute_ns_consumes_self)
#  define NS_CONSUMES_SELF   __attribute__(( ns_consumes_self))
# else
#  define NS_CONSUMES_SELF
# endif
#endif


#ifndef MULLE_NO_RETURN
#  ifdef NO_RETURN
#   define MULLE_NO_RETURN   NO_RETURN
#  else
#   define MULLE_NO_RETURN   __attribute(( __noreturn__))
#  endif
//# define NO_RETURN __declspec(noreturn)
# else
#  define MULLE_NO_RETURN
#endif
