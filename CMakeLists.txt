cmake_minimum_required (VERSION 3.0)

project( MulleScion C)


# add cmake module paths to search path
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake/share")
list( INSERT CMAKE_MODULE_PATH 0 "${PROJECT_SOURCE_DIR}/cmake")

include( Environment)

include( CMakeSourcesAndHeaders.txt )
include( DependenciesAndLibraries)

set( GOOGLE_TOOLBOX_SOURCES
"google-toolbox-for-mac/Foundation/GTMNSString+HTML.m"
)

set( HEADERS
${MULLE_SCION_HEADERS}
${MULLE_SCION_FOUNDATION_HEADERS}
${MULLE_SCION_PARSER_HEADERS}
${MULLE_SCION_PRINTER_HEADERS}
)

add_definitions( -DPROJECT_VERSION=1858.3)

include( PreLibrary OPTIONAL)

add_library( MulleScion STATIC
${MULLE_SCION_SOURCES}
${MULLE_SCION_FOUNDATION_SOURCES}
${MULLE_SCION_PARSER_SOURCES}
${MULLE_SCION_PRINTER_SOURCES}
${GOOGLE_TOOLBOX_SOURCES}
${HOEDOWN_SOURCES}
${HEADERS}
CMakeSourcesAndHeaders.txt
)

include( Library OPTIONAL)


include( PostLibrary OPTIONAL)


include( PreExecutable OPTIONAL)

add_executable( mulle-scion
${MONGOOSE_SOURCES}
${TOOL_SOURCES}
CMakeSourcesAndHeaders.txt
)

set( EXECUTABLE_NAME "mulle-scion")

set( EXECUTABLE_LIBRARY_LIST
   ${ALL_LOAD_DEPENDENCY_LIBRARIES}
   ${OPTIONAL_DEPENDENCY_LIBRARIES}
   ${DEPENDENCY_LIBRARIES}
   ${OS_SPECIFIC_LIBRARIES}
)

include( Executable OPTIONAL)

target_link_libraries( "mulle-scion"
$<TARGET_FILE:MulleScion>
${EXECUTABLE_LIBRARY_LIST}
)

add_dependencies( mulle-scion MulleScion)

include( PostExecutable OPTIONAL)


include( PreInstall OPTIONAL)

# INSTALL( TARGETS MulleScion DESTINATION "lib")
# INSTALL( FILES ${HEADERS} DESTINATION "include/MulleScion")

INSTALL( TARGETS mulle-scion DESTINATION "bin")
INSTALL( FILES ${SCIONS} ${PLISTS} DESTINATION "share/mulle-scion/dox")

include( PostInstall OPTIONAL)
