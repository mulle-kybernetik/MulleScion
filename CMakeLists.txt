cmake_minimum_required (VERSION 3.0)

project( MulleScion C)

# add cmake module paths to search path
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/share")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake")

include( Environment OPTIONAL)

set( CMAKE_EDITABLE_FILES
   CMakeLists.txt
   cmake/HeadersAndSources.cmake
   cmake/DependenciesAndLibraries.cmake
)

include( PreFiles OPTIONAL)

include( HeadersAndSources )
include( DependenciesAndLibraries)

set( HEADERS
${MULLE_SCION_HEADERS}
${MULLE_SCION_FOUNDATION_HEADERS}
${MULLE_SCION_PARSER_HEADERS}
${MULLE_SCION_PRINTER_HEADERS}
)

include( PostFiles OPTIONAL)

set( PROJECT_VERSION 1859.1.4)

add_definitions( -DPROJECT_VERSION={PROJECT_VERSION})

message( STATUS "CMAKE_C_COMPILER_ID=${CMAKE_C_COMPILER_ID}")
message( STATUS "CMAKE_SYSTEM_NAME=${CMAKE_SYSTEM_NAME}")

if( ("${CMAKE_SYSTEM_NAME}" STREQUAL "Darwin") AND NOT "${CMAKE_C_COMPILER_ID}" MATCHES "^(MulleClang)$")
   set( OBJC_COVERAGE_OPTIMIZED_LIBS OFF)
   set( CREATE_OBJC_LOADER_INC OFF)
endif()

### Library


set( LIBRARY_SOURCES
${MULLE_SCION_SOURCES}
${MULLE_SCION_FOUNDATION_SOURCES}
${MULLE_SCION_PARSER_SOURCES}
${MULLE_SCION_PRINTER_SOURCES}
${GOOGLE_TOOLBOX_SOURCES}
${HOEDOWN_SOURCES}
${HEADERS}
cmake/HeadersAndSources.cmake
)

include( PreLibrary OPTIONAL)
include( Library )
include( PostLibrary OPTIONAL)


### Executable

set( EXECUTABLE_NAME mulle-scion)
set( EXECUTABLE_SOURCES ${TOOL_SOURCES}
${MONGOOSE_SOURCES}
)

if( APPLE)
   set( EXECUTABLE_LIBRARY_LIST
      ${EXECUTABLE_LIBRARY_LIST}
      -ObjC
   )

   set( EXECUTABLE_LIBRARY_LIST
      ${EXECUTABLE_LIBRARY_LIST}
      $<TARGET_FILE:${LIBRARY_NAME}>
      ${FOUNDATION_LIBRARY}
   )
else()
   set( ALL_LOAD_DEPENDENCY_LIBRARIES
      $<TARGET_FILE:${LIBRARY_NAME}>
      ${ALL_LOAD_DEPENDENCY_LIBRARIES}
   )
endif()


set( EXECUTABLE_DEPENDENCY_NAMES
MulleScion
)

include( PreExecutable OPTIONAL)
include( Executable )
include( PostExecutable OPTIONAL)

if( APPLE)
   target_link_libraries( "${EXECUTABLE_NAME}"
      -lz
   )
endif()


include( PreInstall OPTIONAL)

# INSTALL( TARGETS MulleScion DESTINATION "lib")
# INSTALL( FILES ${HEADERS} DESTINATION "include/MulleScion")

INSTALL( TARGETS mulle-scion DESTINATION "bin")
INSTALL( FILES ${SCIONS} ${PLISTS} DESTINATION "share/mulle-scion/dox")

include( PostInstall OPTIONAL)
