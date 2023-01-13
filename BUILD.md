This is the "old" MulleScion, which supports macOS. The new "MulleScion" will
also work on macOS, but the xcodeproject file isn't maintained any longer.

## Build macOS

* Install [mulle-sde](//github.com/mulle-sde)
* Grab dependencies with `mulle-sde fetch`
* Build with `xcodebuild` or run **Xcode**


~~~

# Legacy instructions

```
mulle-sde

Mac OS X
========

``` bash
mulle-sde craft --no-local -- -DCREATE_OBJC_LOADER_INC=OFF -DLINK_STARTUP_LIBRARY=OFF
./install.sh OSX
```

will produce all OS X outputs. You have the choice between a "normal"
dynamically linked framework `MulleScion.framework` or a static library
`libMulleScion.a` with a set of include headers.

It will also produce the **mulle-scion** executable. This will place the Framework in `/Library/Frameworks` and the executable in `/usr/local/bin.`


iOS
=====

``` bash
mulle-sde craft
xcodebuild -target iOS
```

to produce a static library libMulleScion.a with a set of include headers.



CocoaPods
=========

> **This can't be working anymore**

MulleScion is available through [Mulle kybernetiK](www.mulle-kybernetik.com), to install
it simply add the following line to your Podfile:

``` bash
pod "MulleScion"
```

and add

``` bash
    pod repo add Mulle-kybernetiK http://www.mulle-kybernetik.com/repositories/CocoaPodSpecs
```
on the commandline.



Tips
====

Avoid compile errors by using something like

```
	HEADER_SEARCH_PATHS = $(inherited) $(PROJECT_DIR)/../MulleScion/Build/Products/Debug-iphonesimulator
```

or when using the framework

```
	FRAMEWORK_SEARCH_PATHS = $(inherited) $(PROJECT_DIR)/../MulleScion/Build/Products/Debug-iphonesimulator
```

Avoid runtime errors by using

```
	OTHER_LDFLAGS = -ObjC
```

or something like

```
	OTHER_LDFLAGS = -force_load $(PROJECT_DIR)/lib/libMulleScion.a
```

