#
# This file is not using mulle-sde update yet
#
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
src/Hoedown+MulleScionPrinting.m
src/MulleScionDataSourceProtocol.m
src/MulleScionPrinter.m
src/MulleScionPrintingException.m
src/MulleScionObjectModel+Printing.m
src/NSObject+MulleScionDescription.m
src/NSString+TrimTextFromExamples.m
src/NSValue+CheatAndHack.m
src/MulleMutableLineNumber.m
src/MulleScionNull.m
)


set( TOOL_SOURCES
src/MulleMongoose.m
src/MulleScionObjectModel+MulleMongoose.m
src/main.m
)


set( SCIONS
dox/Environment_Variables.scion
dox/Formatting_Options.scion
dox/Global_Variables.scion
dox/NSMakeRange.scion
dox/__demo.scion
dox/__page.scion
dox/__scion_banner.scion
dox/__scion_footer.scion
dox/__scion_macros.scion
dox/__scion_navigation.scion
dox/__scion_page.scion
dox/__scion_style.scion
dox/_spaces.scion
dox/_wrapper.scion
dox/block.scion
dox/define.scion
dox/dot.scion
dox/expression.scion
dox/extends.scion
dox/filter.scion
dox/for.scion
dox/if.scion
dox/includes.scion
dox/index.scion
dox/log.scion
dox/macro.scion
dox/requires.scion
dox/self.scion
dox/set.scion
dox/verbatim.scion
dox/while.scion
"dox/[].scion"
"dox/|.scion"
"dox/!_Introduction.scion"
"dox/#!.scion"
)

set( PLISTS
dox/properties.plist
)


set( GOOGLE_TOOLBOX_SOURCES
"google-toolbox-for-mac/Foundation/GTMNSString+HTML.m"
)

set( STAGE2_SOURCES
"src/MulleObjCLoader+MulleScion.m"
)
