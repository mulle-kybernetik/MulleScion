
MulleScionTemplates is a modern template engine for Objective C
=============
(written in an oldfashioned way)
***

It's **heavily** (very heavily) inspired by 

[TWIG]("http://twig.sensiolabs.org/") "The flexible, fast, and secure template engine for PHP"


*MulleScionTemplates* is fairly flexible, reasonably fast and can be made as
 secure as you wish. 

* **Reasonably 
Fast** :      *MulleScionTemplates* can compile templates into a compressed archive 
               format. Loading such an archive is lots faster than parsing. A 
               compiled template is read-only, you can use it many times to 
               render different output from different input.

* **Secure** :   *MulleScionTemplates* has hooks so your application can ensure that 
               untrusted template code doesn't have access to all of the input 
               data.

* **Flexible** :    There is the possibility of extending KVC and writing your own
               "builtin" fuctions. A template can (if allowed) execute 
               arbitrary ObjC code. MulleScion has a powerful define like 
               preprocessing capability and macros to expand your template vocabulary.


MulleScionTemplates are beautiful (hello Jinja :) :

	{% extends "layout.html" %}
	{% block body %}
 	 <ul>
 	 {% for user in users %}
  	  <li><a href="{{ user.url }}">{{ user.username }}</a></li>
  	 {% endfor %}
  	 </ul>
	{% endblock %}


Using the MulleScionTemplates.framework the creation of a string from your 
object using a template file is as easy as:

	NSString  *output;
	 
	output = [MulleScionTemplate descriptionWithTemplateFile:@"test.scion"
    	                                          dataSource:self];

This is the general architecture of *MulleScionTemplates*

![](http://www.mulle-kybernetik.com/software/git/MulleScionTemplates/raw/master/dox/MulleScionTemplatesDataFlow.png "Data Flow Sketch")

*MulleScionTemplates* is a work in progress, it's extremely fresh and little used (yet).



DOCUMENTATION
=============

Virtually all the documentation is contained in example **.scion** templates 
in the `dox`folder. For each command or feature there should be a separate template file 
that documents it. mulle-scion, the command line utility, contains a small quickly hacked together webserver that can present the documentation using *MulleScionTemplates* itself. 
In Xcode just run `mulle-scion` and it should setup the webserver and open your browser to the right address. 

MulleScion is very similar to TWIG, so you can glean much of relevance from 
<http://twig.sensiolabs.org>. If you see a feature in TWIG but don't see it in the 
tests file, it's likely not there (but it's probably easily achieved some other way (define, macro, ObjC category on NSString).


LIMITATIONS
=============
Because you can execute arbitrary ObjC methods, and have access to Key Value
Coding, MulleScion can pretty much do anything. *MulleScionTemplates* use 
`NSInvocation` for method calls, and that usually can not do variable arguments. 
So that will be a problem. Be wary of anything using structs and C-Arrays and 
C-strings, although *MulleScionTemplates* tries to be as helpful as possible.

*MulleScionTemplates* do not do arithmetic or bitwise logic, quite on purpose.

*MulleScionTemplates* do not support the `@{ }` syntax to create dictionaries.

*MulleScionTemplates* `&&` and `||` have no operator precedence, use parentheses

*MulleScionTemplates* don't prevent you from trying stupid things.

The documentation is not very good, actually it is just more or less a 
collection of test cases with comments...

TODO
=============
It would be nice to have delayed evaluation for render results.
Get rid of MulleScionNull except for printing a nil value.


AUTHOR
=============
Coded by Nat!
2013 Mulle kybernetiK

Mongoose Webserver by
Sergey Lyubka 
