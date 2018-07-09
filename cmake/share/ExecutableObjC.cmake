if( NOT __EXECUTABLE_OBJC_CMAKE__)
   set( __EXECUTABLE_OBJC_CMAKE__ ON)

   if( MULLE_TRACE_INCLUDE)
      message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
   endif()

   if( NOT EXECUTABLE_NAME)
      set( EXECUTABLE_NAME "MulleScion")
   endif()

   option( LINK_STARTUP_LIBRARY "Add a startup library to ObjC executable" ON)

   #
   # This library contains ___get_or_create_mulle_objc_universe and
   # the startup code to create the universe
   #
   if( LINK_STARTUP_LIBRARY)
      if( NOT STARTUP_LIBRARY_NAME)
         set( STARTUP_LIBRARY_NAME "MulleObjC-startup")
      endif()

      if( NOT STARTUP_LIBRARY)
         find_library( STARTUP_LIBRARY NAMES ${STARTUP_LIBRARY_NAME})
      endif()

      message( STATUS "STARTUP_LIBRARY is ${STARTUP_LIBRARY}")

      set( EXECUTABLE_LIBRARY_LIST
        ${EXECUTABLE_LIBRARY_LIST}
        ${STARTUP_LIBRARY}
      )
   endif()

   #
   # need this for .aam projects
   #
   set_target_properties( "${EXECUTABLE_NAME}"
      PROPERTIES LINKER_LANGUAGE C
   )

   #
   # For noobs: add a line so they find the output
   #
   add_custom_command(
     TARGET "${EXECUTABLE_NAME}"
     POST_BUILD
     COMMAND echo "Your executable \"$<TARGET_FILE:${EXECUTABLE_NAME}>\" is now ready to run"
     VERBATIM
   )

   include( ExecutableObjCAux OPTIONAL)

endif()
