# -- Formula Info --
# If you don't have this file, there will be no homebrew
# formula operations.
#
PROJECT="MulleScion"      # your project name, requires camel-case
DESC="A modern template engine for Objective C"
LANGUAGE="objc"           # c,cpp, objc, bash ...
NAME="mulle-scion"        # formula filename w/o .rb extension


#
# Specify needed homebrew packages by name as you would when saying
# `brew install`.
#
# Use the ${DEPENDENCY_TAP} prefix for non-official dependencies.
# DEPENDENCIES and BUILD_DEPENDENCIES will be evaled later!
# So keep them single quoted.
#
# DEPENDENCIES='${DEPENDENCY_TAP}mulle-concurrent
# libpng
# '

#
# Build via mulle-build. If you don't like this
# edit bin/release.sh
#
BUILD_DEPENDENCIES='mulle-sde
cmake'

DEBIAN_DEPENDENCIES="foundation-developer cmake"