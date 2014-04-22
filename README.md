
MulleScion is a modern template engine for Objective C
=============
(written in an oldfashioned way)
***

It's **heavily** (very heavily) inspired by 

[TWIG]("http://twig.sensiolabs.org/") "The flexible, fast, and secure template 
engine for PHP"

*MulleScion* is fairly flexible, reasonably fast and can be made as
 secure as you wish. 
 
* **Reasonably 
Fast** :      *MulleScion* can compile templates into a compressed 
               archive format. Loading such an archive is lots faster than 
               parsing. A compiled template is read-only, you can use it many 
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
 
	<html>
	<!-- rendered by {{ [[NSProcessInfo processInfo] processName] }} on 
        {{ [NSDate date]] }} -->
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


Using the MulleScion.framework the creation of a string from your 
object using a template file is as easy as:

	NSString  *output;
	 
	output = [MulleScionTemplate descriptionWithTemplateFile:@"test.scion"
    	                                          dataSource:self];

This is the general architecture of *MulleScion*

![](/dox/MulleScionDataFlow.png "Data Flow Sketch")
![](http://www.mulle-kybernetik.com/software/git/MulleScion/raw/master/dox/MulleScionDataFlow.png "Data Flow Sketch")

*MulleScion* is currently still pretty much a "happy path" project, but 
it is being used in a commercial project. 

TOOLS
=============
There is an interactive editor available for OS X called [MulleScionist](http://www.mulle-kybernetik.com/software/git/MulleScionist/),
which allows you to edit a HTML scion template and preview the results at the
same time.


DOCUMENTATION
=============

Virtually all the documentation is contained in example **.scion** templates 
in the `dox`folder. For each command or feature there should be a separate 
template file that documents it. mulle-scion, the command line utility, contains 
a small quickly hacked together webserver that can present the documentation 
using *MulleScion* itself.
In Xcode just run `Show Documentation in Webserver` and it should setup the 
webserver and open your browser to the right address.

MulleScion is very similar to TWIG, so you can glean much of relevance from 
<http://twig.sensiolabs.org>. If you see a feature in TWIG but don't see it in 
the tests file, it's likely not there (but it's probably easily achieved some 
other way (define, macro, ObjC category on NSString).


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

[http://www.mulle-kybernetik.com/software/git/MulleScion/]()

releases are pushed to github

[https://github.com/mulle-nat/MulleScion/]()


TODO
=============
It might be nice to have delayed evaluation for render results. More tests.


AUTHOR
=============
Coded by Nat!
2013 Mulle kybernetiK

Mongoose Webserver by
Sergey Lyubka 
