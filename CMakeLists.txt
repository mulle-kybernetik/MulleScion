cmake_minimum_required (VERSION 3.0)

project (MulleScion)


set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/mulle-configuration)
message(STATUS "CMAKE_MODULE_PATH is ${CMAKE_MODULE_PATH}")
message(STATUS "CMAKE_BUILD_TYPE is ${CMAKE_BUILD_TYPE}")

set( MULLE_LANGUAGE "ObjC")

if( "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  include( Debug)
else()
  include( Release)
endif()


add_definitions( -DPROJECT_VERSION=1854)


include( CMakeSourcesAndHeaders.txt )


set( HEADERS
${MULLE_SCION_HEADERS}
${MULLE_SCION_FOUNDATION_HEADERS}
${MULLE_SCION_PARSER_HEADERS}
${MULLE_SCION_PRINTER_HEADERS}
)



# move to mulle-configuration
set( CMAKE_FIND_FRAMEWORK "LAST")

find_library( FOUNDATION_LIBRARY NAMES Foundation)
message( STATUS "FOUNDATION_LIBRARY is ${FOUNDATION_LIBRARY}")

add_library( MulleScion STATIC
${MULLE_SCION_SOURCES}
${MULLE_SCION_FOUNDATION_SOURCES}
${MULLE_SCION_PARSER_SOURCES}
${MULLE_SCION_PRINTER_SOURCES}
)

target_link_libraries( MulleScion
${FOUNDATION_LIBRARY}
${OS_SPECIFIC_LIBS}
-lz
)


add_executable( mulle-scion
${MONGOOSE_SOURCES}
${TOOL_SOURCES}
)


target_link_libraries( mulle-scion
${BEGIN_ALL_LOAD}
MulleScion
${END_ALL_LOAD}
${FOUNDATION_LIBRARY}
${OS_SPECIFIC_LIBS}
-lz
)


INSTALL( TARGETS MulleScion DESTINATION "lib")
INSTALL( FILES ${HEADERS} DESTINATION "include/MulleScion")

INSTALL( TARGETS mulle-scion DESTINATION "bin")
