Mac OS X
========

	./install.sh OSX


will produce all OS X outputs. You have the choice between a "normal" 
dynamically linked framework `MulleScion.framework` or a static library `libMulleScion.a` with a set of include headers.

It will also produce the **mulle-scion** executable. This will place the Framework in `/Library/Frameworks` and the executable in `/usr/local/bin.`


iOS
=====

	xcodebuild -target iOS

to produce a static library libMulleScion.a with a set of include headers.



CocoaPods
=========

MulleScion is available through [Mulle kybernetiK](www.mulle-kybernetik.com), to install
it simply add the following line to your Podfile:

    pod "MulleScion"

and add 
  
    pod repo add Mulle-kybernetiK http://www.mulle-kybernetik.com/repositories/CocoaPodSpecs

on the commandline.


mulle-bootstrap
=========

      Add http://www.mulle-kybernetik.com/repositories/MulleScion
      
to your

      .bootstrap/gits

and say

      mulle-bootstrap



Tips
====

Avoid compile errors by using something like

	HEADER_SEARCH_PATHS = $(inherited) $(PROJECT_DIR)/../MulleScion/Build/Products/Debug-iphonesimulator

or when using the framework

	FRAMEWORK_SEARCH_PATHS = $(inherited) $(PROJECT_DIR)/../MulleScion/Build/Products/Debug-iphonesimulator


Avoid runtime errors by using 

	OTHER_LDFLAGS = -ObjC

or something like

	OTHER_LDFLAGS = -force_load $(PROJECT_DIR)/lib/libMulleScion.a


