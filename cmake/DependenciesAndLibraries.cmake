#
# The following includes include definitions generated
# during `mulle-sde update`. Don't edit those files. They are
# overwritten frequently.
#
# === MULLE-SDE START ===

include( _Dependencies OPTIONAL)
include( _Libraries OPTIONAL)

# === MULLE-SDE END ===
#

#
# If you need more find_library() statements, that you dont want to manage
# with the sourcetree, add them here.
#
# Add OS specific dependencies to OS_SPECIFIC_LIBRARIES
# Add all other dependencies (rest) to DEPENDENCY_LIBRARIES
#
if( APPLE AND NOT FOUNDATION_LIBRARY)
   find_library( FOUNDATION_LIBRARY Foundation)
   if( FOUNDATION_LIBRARY)
      set( DEPENDENCY_LIBRARIES
         ${DEPENDENCY_LIBRARIES}
         ${FOUNDATION_LIBRARY}
         CACHE INTERNAL "need to cache this"
      )
   endif()
   message( STATUS "FOUNDATION_LIBRARY is \"${FOUNDATION_LIBRARY}\"")
endif()
