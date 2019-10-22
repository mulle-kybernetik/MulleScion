
MulleScion is a modern template engine for Objective C
=============
(written in an oldfashioned way)

Release on [github](//github.com/mulle-kybernetik/MulleScion): [![Build Status](https://travis-ci.org/mulle-kybernetik/MulleScion.svg?branch=release)](https://travis-ci.org/mulle-kybernetik/MulleScion)

***

It's **heavily** (very heavily) inspired by

[TWIG](//twig.sensiolabs.org/) "The flexible, fast, and secure template
engine for PHP"

*MulleScion* is fairly flexible, reasonably fast and can be made as
 secure as you wish.

* **Reasonably
Fast** :      *MulleScion* can compile templates into a compressed
               archive format. Loading such an archive ought to be lots faster
               than parsing (but because the parse is so fast, maybe isn't).
               A compiled template is read-only, you can use it many
               times to render different output from different input.

* **Secure** :   *MulleScion* has hooks so your application can ensure
               that untrusted template code doesn't have access to all of the
               applications data.

* **Flexible** :    There is the possibility of extending KVC and writing your
               own "builtin" fuctions. A template can (if allowed) execute
               arbitrary ObjC code. MulleScion has a powerful define like
               preprocessing capability and macros to expand your template
               vocabulary.

Here is a simple example, where ObjC code is embedded in a template:

``` twig
<html>
   <!-- rendered by {{ [[NSProcessInfo processInfo] processName] }} on
        {{ [NSDate date] }} -->
   <body>
     {% for item in [NSTimeZone knownTimeZoneNames] %}
         {% if item#.isFirst %}
         <table>
            <tr><th>TimeZone</th></tr>
         {% endif %}
            <tr><td>{{ item }}</td></tr>
         {% if item#.isLast %}
         </table>
         {% endif %}
      {% else %}
         Sorry, no timezone info available.
      {% endfor %}
   </body>
</html>
```

Using the MulleScion.framework the creation of a string from your
object using a template file is as easy as:

``` objective-c
   NSString  *output;

   output = [MulleScionTemplate descriptionWithTemplateFile:@"test.scion"
                                                 dataSource:self];
```

This is the general architecture of *MulleScion*

![](/dox/MulleScionDataFlow.png "Data Flow Sketch")
![](https://www.mulle-kybernetik.com/software/git/MulleScion/raw/master/dox/MulleScionDataFlow.png "Data Flow Sketch")

*MulleScion* is happily used in a commercial project and has gone through
enough iterations to pronounce it "ready for production".


HTML PREPROCESSOR
=============
There is a companion project [MulleScionHTMLPreprocessor](/mulle-nat/MulleScionHTMLPreprocessor)
that used HTML like tags, to make the template easier to reformat in
HTML editors:

```
<html>
  <!-- rendered by {{ [[NSProcessInfo processInfo] processName] }} on
        {{ [NSDate date] }} -->
  <body>
    <for item in [NSTimeZone knownTimeZoneNames]>
      <if item#.isFirst>
        <table>
          <tr><th>TimeZone</th></tr>
      </if>
        <tr><td>{{ item }}</td></tr>
      <if item#.isLast>
        </table>
      </if>
    <else/>
      Sorry, no timezone info available.
    </for>
  </body>
</html>
```



TOOLS
=============
There is an interactive editor available for OS X called [MulleScionist](https://www.mulle-kybernetik.com/software/git/MulleScionist/),
which allows you to edit a HTML scion template and preview the results at the
same time.


DOCUMENTATION
=============

Virtually all the documentation is contained in example **.scion** templates
in the `dox` folder. For each command or feature there should be a separate
template file that documents it. **mulle-scion**, the command line utility,
contains  a small quickly hacked together webserver that can present the
documentation using *MulleScion* itself.

In Xcode just run `Show Documentation in Webserver` and it should setup the
webserver and open your browser to the right address.

MulleScion is very similar to TWIG, so you can glean much of relevance from
<http://twig.sensiolabs.org>. If you see a feature in TWIG but don't see it in
the tests file, it's likely not there (but it's probably easily achieved some
other way (using a `define` or a `macro` or an ObjC category on **NSString**).


LIMITATIONS
=============
Because you can execute arbitrary ObjC methods, and have access to Key Value
Coding, MulleScion can pretty much do anything. *MulleScion* uses
`NSInvocation` for method calls. That means there will be problems with variable
arguments methods. Be wary of anything using structs and C-Arrays and
C-strings, although *MulleScion* tries to be as helpful as possible.

*MulleScion* does not do arithmetic or bitwise logic, quite on purpose.

*MulleScion* `&&` and `||` have no operator precedence, use parentheses.

*MulleScion* doesn't prevent you from trying stupid things.

The documentation is not very good, actually it is just more or less a
collection of test cases with comments...


iOS SUPPORT
=============
There is iOS Support :)


SITES
=============
The main development site is Mulle kybernetiK.

[http://www.mulle-kybernetik.com/software/git/MulleScion/](http://www.mulle-kybernetik.com/software/git/MulleScion/)

releases are pushed to github

[https://github.com/mulle-nat/MulleScion/](https://github.com/mulle-nat/MulleScion/)


TODO
=============
It might be nice to have delayed evaluation for render results. More tests.


INSTALLATION (mulle-scion command line tool only)
=============

```
brew install mulle-kybernetik/software/mulle-scion
```

USAGE mulle-scion
=============

```
Usage:
   mulle-scion [options] <input> <datasource> [output] [arguments]

Options:
   -w       : start webserver for /usr/local/share/mulle-scion/dox
   -z       : write compressed archive to outputfile
   -Z       : write compressed keyed archive to outputfile (for IOS)

Input:
   -        : Read template from stdin
   template : a MulleScion template path or URL

Datasource:
   -        : Read data from stdin (only if input is not stdin already)
   args     : use arguments as datasource (see below)
   bundle   : a NSBundle. It's NSPrincipalClass will be used as the datasource
   plist    : a property list path or URL as datasource, see: plist(5)
   none     : empty datasource

Output:
   -        : Write result to stdout
   file     : Write result to file

Arguments:
   key=value: key/value pairs to be used as __ARGV__ contents
              (unless args as datasource was specified)

Examples:
   echo '***{{ VALUE }}***' | mulle-scion - args - VALUE="VfL Bochum 1848"
   echo '***{{ __ARGV__[ 0]}}***' | mulle-scion - none - "VfL Bochum 1848"
```


AUTHOR
=============
Coded by Nat!
2013 Mulle kybernetiK

Mongoose Webserver by
Sergey Lyubka

Hoedown Library by Natacha Porté
Vicent Martí
Xavier Mendez, Devin Torres and the Hoedown authors

Contributors: @hons82 (Hannes)

