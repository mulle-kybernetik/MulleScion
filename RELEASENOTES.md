### 1859.1.3

* fix various bits and pieces so stuff builds on macOS

### 1859.1.2

* Various small improvements

### 1859.1.1

* updated mulle-sde, improved versioning

# 1859.0.0

chamged versioning to three digits for mulle-project

* tested against mulle-objc 0.15
* migration from bootstrap to mulle-sde


### 1858.2

* adapt to changes in mulle-configuration

### 1858.1

* fix build problem with new mulle-configuration

## 1858

There is an option that allows specifying includes via the environment like
so:
`MULLESCION_ALLOW_GETENV_INCLUDES="YES" MY_INCLUDE="foo.scion" mulle-scion bar.scion none`
and then in `bar.scion` use `{% includes MY_INCLUDE %}`. This looks obscure,
but I needed it to wrap code around existing templates.
* MULLESCION_.. environment variables now are of the YES/NO variety.

## 1857

* fix missing menu due to change of root dox
* fix podspec version
* add dump of includes for debugging

## 1856

* clarify usage output
* add nexti/previ to for loop dictionary.
* modernized tests a little bit to be compatible with mulle-tests also improved
CmakeLists.txt slightly

## 1855

* Bool fix from Hannes Tribus `<hons82@...com>`
* IOS/ARC fixes from Hannes Tribus `<hons82@...com>`
* Some portability fixes for MulleFoundation

## 1854

* Added a podspec fix from Hannes Tribus `<hons82@...com>`

* Fixed an obvious KVC bug, in a code path that was probably never used
* Some support for MulleFoundation merged in
* Added local variable __FOUNDATION__
* Use a fork of google-toolbox for html escaping/unescaping
* Use mulle-configuration for compilation
* --version prints version and exits

## 1853.2

* Experimental Travis CI integration on Github.
* Improvements in project structure due to better `mulle-bootstrap`

## 1853.1

* Fixed a bug, where `endfilter` did not respect the options setting of the
returning filter. This could create havoc on plaintext, when your filter
just specified (output).

## 1853

* Made mulle-scion brew compatible. You can now brew it. As I wanted to use
mulle-scion to produce brew formulae, I needed some options in the way
mulle-scion is called.

** It is now possible to do this:

```
echo '--- {{ VALUE }} ---' | mulle-scion - keyvalue - VALUE="xxx"
```

which produces predicatably

```
--- xxx ---
```

* Templates can be passed in via stdin and the replacement values can be given
as key=value arguments. This makes mulle-scion even more convenient to use
in shell scripts.

~~~
brew install https://www.mulle-kybernetik.com/software/formulae/mulle-scion.rb
~~~

* There are now "hidden" environment variables WWW_ROOT, WWW_PORT, WWW_PLIST for
the webserver.

* The way libraries are created and headers are written has been standardized and
improved. There is some support for a future "mulle-bootstrap", in case you are
wondering what the .bootstrap folder does.

## 1852

### API change

Redesigned the "convenience interface". Sorry but I just disliked the
proliferation of code, that separated **NSURL** and **NSString** by type. I used the
power of ObjC and simplified this without having to resort to degenerics ;)
In other words the` +descriptionWithTemplateURL:` method family is gone, just use
`+descriptionWithTemplateFile:` with either NSString or NSURL.

### LANGUAGE change

I apparently goofed up the documentation in 1851 and made an incompatible change
so that **mulle-scion** choked up on its own documentation templates. Ahem. That
has been fixed, so that MulleScion now skips all scion tags, that are
immediately _followed_ by a backtick ` or a backquote \. This ought to be
harmless in my opinion, but results may vary.



## 1851.0

*** BIG CHANGE!!! FILTER REDESIGNED ***

I decided to convert the documentation from ASCII into markdown. For that I
needed a markdown filter. As it turns out, none of the libraries I found are
able to do incremental rendering (bummer). This meant, that the markdown filter
had to buffer all incoming strings until the endfilter was reached.
That broke a lot of stuff.

On a positive note, you can now nest filters and can tweak them a little with
optional parameters.


*** BIG CHANGE!!! ELSEFOR INSTEAD OF ELSE IN FOR-ENDFOR ***

I messed up, when I "designed" aka hacked in the {% for else endfor %} feature
it doesn't work, when there is a {% if else endif %} contained in the loop.
So else needs to be renamed to elsefor in this case.

To keep in sync with the archive version, the version nr. has been bumped to
1851.


* Improved the dependencyTable generation, by ignoring syntax errors.

* The documentation is now in markdown format. With some hacking effort
the builtin webserver can now show the "Results" much nicer.

* Stole a CSS to make it look more nicey, nicey.

* Improved the LICENSE detail.

* Made it more possible to call a macro from a macro, which failed in some cases.

* There is now a hidden convert feature on includes, which allows to preprocess
the data. convert > parse > print > filter


## 1848.11

*** This can break archived templates on iOS, regenerate them ***

* mulle-scion has now a -z option to output compiled templates. While testing
I found out, that when I use NSKeyedArchiver it's actually slower than parsing
plain text and uses more space - even compressed.

```
Compile plaintext * 100
-rw-r--r--  1 nat  _lpoperator  198016 Oct  9 17:00 big.scion

real	0m8.528s

Compile unkeyed * 100
-rw-r--r--  1 nat  wheel  75983 Oct  9 17:25 /tmp/unkeyed.scionz
real	0m8.680s

Compile keyed * 100
-rw-r--r--  1 nat  wheel  750347 Oct  9 17:25 /tmp/keyed.scionz
real	0m25.497s
```

* If you are on iOS it's most likely better to not use archives and caching!

* Fix erroneous trace output, which was always happening.

* Fix bug, where "for i in nil" would iterate once

* Fix bug, where MulleScionNull was passed as invocation argument


## 1848.10

*** This can break currently working templates, that contain unnoticed
    syntax errors! ***

* the parser doesn't allow garbage inside mulle-scion tags anymore. It
  used to parse {{ x = #<%$/&> }} because everything after "x " was
  ignored, but it was just too confusing in real life use.

* simplified expansion of function functionality a bit.
  added NSStringFromRange to builtin-functions

* added some NSURL methods for opening templates, which is more convenient on
iOS

* made built-in function in principle expandable to support user-written
functions


## 1848.9

* added a podspec


## 1848.8

* allow # comments within {% %}

* added log command for debugging

* mulle-scion now builds into /usr/local/bin in Release setting

* the demo webserver root is now /tmp/MulleScionDox

* fixed requires dox

* made requires a single line command, like include or extends, just because
it "felt right"

* remove some extraneous debug output and runtime warnings

* new scheme "Show Documentation in Browser"

* updated documentation a bit regarding multi-line commands


## v1848.7

* outsourced NSObject+MulleGraphviz because I need it in other code
too and the dependency on MulleScion was annoying.

* fixed some bad code in commandline tool, that reads the property list


## v1848.6

* add __ARGV__ parsage to mulle-scion. Now you can use mulle-scion as an awk
replacement in other shell scripts, if you so desire.


## v1848.5

* bunch of fixes. Added an example how to write a non-plist datasource, in this
case using CoreData.

* added a requires keyword for dynamic loading of bundles from within a scion
script (experimental)


## v1848.4

* renamed to MulleScion, because now it's more than just a template engine, it's
also somewhat useful as a little standalone Obj-C interpreter. Also
MulleScionTemplates was just too long.

* The MulleScionConvenience has been renamed to just MulleScion.

* There is now some rudimentary tracing support available. Just going to become
better over time.

* {{ }} can now be placed inside {% %} which makes templates with a lot of logic
and little output that much more managable.

* used google-toolbox-code for htmlEscapedString, which now adds some Apache2 Licensing
terms to this project. Or say #define NO_APACHE_LICENSE and get the old crufty
functionality back.

* the repository on github will be only pushed to for "releases" the continous
development is going to happen on Mulle kybernetiK.

<blockquote>mulle:  http://www.mulle-kybernetik.com/software/git/MulleScionTemplates/<br>
github: https://github.com/mulle-nat/MulleScionTemplates/
</blockquote>


## v1848.3  !!**massive changes**!!

* your compiled scionz files are incompatible now. Throw them away
and rebuild your caches

* you used to be able to have random trash after valid scion code, which was nice
for documentation. That doesn't work anymore in most cases

* you can now write multiline scripts, but some keywords need still to be
enclosed as singles in {% %} like macro, block, endblock, extends and maybe
some others

* there are the beginnings of a test suite, check out the tests folder. there is
a simple shellscript that runs the tests

* lots of smaller fixes, whose content one might glean from the git comments


## v1848.2

* your scionz files are incompatible now. Throw them away
and rebuild the caches
