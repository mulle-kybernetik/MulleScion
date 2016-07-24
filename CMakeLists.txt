cmake_minimum_required (VERSION 3.0)

project (MulleScion)


set( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_SOURCE_DIR}/mulle-configuration)
message(STATUS "CMAKE_MODULE_PATH is ${CMAKE_MODULE_PATH}")
message(STATUS "CMAKE_BUILD_TYPE is ${CMAKE_BUILD_TYPE}")
if( "${CMAKE_BUILD_TYPE}" STREQUAL "Debug")
  include( Debug)
else()
  include( Release)
endif()

# move to mulle-configuration
IF(APPLE)
   find_library( FOUNDATION
                 NAMES Foundation
                 PATHS ${CMAKE_OSX_SYSROOT}/System/Library
                 PATH_SUFFIXES Frameworks
                 NO_DEFAULT_PATH)
else()
   find_library( FOUNDATION
                 NAMES Foundation
                 HINTS lib dependencies/lib
                )
endif()


add_definitions( -DPROJECT_VERSION=1854)

include_directories(
src
src/hoedown
src/mongoose
google-toolbox-for-mac
google-toolbox-for-mac/Foundation
)


set( MONGOOSE_SOURCES
src/mongoose/mongoose.c
)


set( HOEDOWN_SOURCES
src/hoedown/Hoedown.m
src/hoedown/Hoedown+MulleScionPrinting.m
src/hoedown/NSString+TrimTextFromExamples.m
src/hoedown/NSData+Hoedown.m
src/hoedown/autolink.c
src/hoedown/buffer.c
src/hoedown/document.c
src/hoedown/escape.c
src/hoedown/html_blocks.c
src/hoedown/html_smartypants.c
src/hoedown/html.c
src/hoedown/stack.c
src/hoedown/version.c
)


set( GOOGLE_TOOLBOX_SOURCES
google-toolbox-for-mac/Foundation/GTMNSString+HTML.m
)



# public headers
set( MULLE_SCION_HEADERS
src/MulleScion.h
)


set( MULLE_SCION_SOURCES
src/MulleScion.m
)


# public headers
set( MULLE_SCION_FOUNDATION_HEADERS
src/MulleObjCCompilerSettings.h
src/MulleScionObjectModel.h
src/MulleScionObjectModel+NSCoding.h
src/MulleScionTemplate+CompressedArchive.h
src/NSFileHandle+MulleOutputFileHandle.h
src/MulleScionObjectModel+TraceDescription.h
)


set( MULLE_SCION_FOUNDATION_SOURCES
src/MulleScionObjectModel.m
src/MulleScionObjectModel+NSCoding.m
src/MulleScionTemplate+CompressedArchive.m
src/NSFileHandle+MulleOutputFileHandle.m
src/MulleScionObjectModel+TraceDescription.m
src/NSData+ZLib.m
src/NSObject+KVC_Compatibility.m
src/NSString+HTMLEscape.m
${GOOGLE_TOOLBOX_SOURCES}
${HOEDOWN_SOURCES}
)


# public headers
set( MULLE_SCION_PARSER_HEADERS
src/MulleScionParser.h
src/MulleScionParser+Parsing.h
)


set( MULLE_SCION_PARSER_SOURCES
src/MulleScionParser.m
src/MulleScionParser+Parsing.m
src/MulleScionObjectModel+Parsing.m
src/MulleScionObjectModel+BlockExpansion.m
src/MulleScionObjectModel+MacroExpansion.m
)


# public headers
set( MULLE_SCION_PRINTER_HEADERS
src/MulleScionOutputProtocol.h
src/MulleScionDataSourceProtocol.h
src/MulleScionPrinter.h
src/MulleScionPrintingException.h
src/NSObject+MulleScionDescription.h
)


set( MULLE_SCION_PRINTER_SOURCES
src/MulleScionDataSourceProtocol.m
src/MulleScionPrinter.m
src/MulleScionPrintingException.m
src/MulleScionObjectModel+Printing.m
src/NSObject+MulleScionDescription.m
src/NSValue+CheatAndHack.m
src/MulleMutableLineNumber.m
src/MulleScionNull.m
)


set( TOOL_SOURCES
src/MulleMongoose.m
src/MulleScionObjectModel+MulleMongoose.m
src/main.m
)


set( HEADERS
${MULLE_SCION_HEADERS}
${MULLE_SCION_FOUNDATION_HEADERS}
${MULLE_SCION_PARSER_HEADERS}
${MULLE_SCION_PRINTER_HEADERS}
)


add_library( MulleScion STATIC
${MULLE_SCION_SOURCES}
${MULLE_SCION_FOUNDATION_SOURCES}
${MULLE_SCION_PARSER_SOURCES}
${MULLE_SCION_PRINTER_SOURCES}
)


add_executable( mulle-scion
${MONGOOSE_SOURCES}
${TOOL_SOURCES}
)
 
set( OS_SPECIFIC_LIBS ${OS_SPECIFIC_LIBS} -lz)

target_link_libraries( mulle-scion
${BEGIN_ALL_LOAD}
MulleScion
${FOUNDATION}
${END_ALL_LOAD}
${OS_SPECIFIC_LIBS}
-lz
)



INSTALL( TARGETS MulleScion DESTINATION "lib")
INSTALL( FILES ${HEADERS} DESTINATION "include/MulleScion")

INSTALL( TARGETS mulle-scion DESTINATION "bin")
